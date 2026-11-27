import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/app_regex.dart';
import '../../core/utils/safe_json.dart';
import '../shared_pos/services/product_catalog_service.dart';
import 'models/auth_models.dart';

export 'models/auth_models.dart';

final RegExp _identifierCleanRegex = RegExp(r'[^a-z0-9_.-]');

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final flavor = AppConfig.instance.flavor;
    final deviceName = switch (flavor) {
      AppFlavor.customer => 'Velora Customer Self-Order',
      AppFlavor.pharmacy => 'Velora Pharmacy POS Terminal',
      AppFlavor.sales => 'Velora Sales Mobile Terminal',
      AppFlavor.marketplace => 'Velora Marketplace Terminal',
      _ => 'Velora Mobile POS Terminal',
    };

    final payload = {
      'email': email,
      'password': password,
      'device_name': deviceName,
    };

    Response response;
    try {
      response = await ApiClient.instance.dio.post(
        '/v1/auth/login',
        data: payload,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        response = await ApiClient.instance.dio.post(
          '/auth/login',
          data: payload,
        );
      } else {
        rethrow;
      }
    }

    return await _processAuthResponse(response.data);
  }

  bool _googleSignInInitialized = false;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    final serverClientId = AppConfig.instance.googleServerClientId.trim();
    await GoogleSignIn.instance.initialize(
      serverClientId: serverClientId.isNotEmpty ? serverClientId : null,
    );
    _googleSignInInitialized = true;
  }

  /// Native Google Sign-In flow: ambil Google ID Token (JWT) lalu kirim ke POST /api/v1/auth/google.
  /// Mengembalikan `null` jika pengguna membatalkan pemilihan akun Google.
  Future<AuthUser?> loginWithGoogle({String action = 'login'}) async {
    await _ensureGoogleSignInInitialized();

    final GoogleSignInAccount googleUser;
    try {
      googleUser = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      final detail = e.description ?? e.code.name;
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError ||
          detail.contains('28444') ||
          detail.contains('serverClientId')) {
        throw Exception(
          'Konfigurasi Google Sign-In belum lengkap. Pastikan GOOGLE_SERVER_CLIENT_ID (Web Client ID) dan SHA-1 sudah terdaftar.',
        );
      }
      throw Exception('Login Google dibatalkan atau gagal: $detail');
    }

    final idToken = googleUser.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception(
        'ID Token Google tidak tersedia. Pastikan GOOGLE_SERVER_CLIENT_ID (Web Client ID) sudah dikonfigurasi.',
      );
    }

    final flavor = AppConfig.instance.flavor;
    final deviceName = switch (flavor) {
      AppFlavor.customer => 'Velora Customer Self-Order',
      AppFlavor.pharmacy => 'Velora Pharmacy POS Terminal',
      AppFlavor.sales => 'Velora Sales Mobile Terminal',
      AppFlavor.marketplace => 'Velora Marketplace Terminal',
      _ => 'Velora Mobile POS Terminal',
    };

    final clientType = kIsWeb
        ? 'pos'
        : (Platform.isIOS ? 'ios' : 'android');

    final payload = <String, dynamic>{
      'id_token': idToken,
      'action': action,
      'device_name': deviceName,
      'client_type': clientType,
    };

    Response response;
    try {
      response = await ApiClient.instance.dio.post(
        '/v1/auth/google',
        data: payload,
      );
    } on DioException catch (e) {
      _extractAndThrowAuthError(e);
    }

    return await _processAuthResponse(response.data);
  }

  /// Internal helper to parse login response, save secure session, and configure active branch
  Future<AuthUser> _processAuthResponse(dynamic rawData) async {
    Map<String, dynamic> data = {};
    if (rawData is Map) {
      final inner = rawData['data'];
      data = inner is Map
          ? Map<String, dynamic>.from(inner)
          : Map<String, dynamic>.from(rawData);
    }

    final token = data.getString('access_token', fallback: data.getString('token'));
    if (token.isEmpty) {
      throw Exception('Format respon server tidak valid: token otentikasi tidak ditemukan.');
    }

    final userJson = data.getMap('user');
    final rootPerms = AuthUser.extractPermissions(data);
    var user = AuthUser.fromJson(userJson.isNotEmpty ? userJson : data);
    if (user.permissions.isEmpty && rootPerms.isNotEmpty) {
      user = user.copyWith(permissions: rootPerms);
    }

    // Gerbang flavor: app kasir/staf menolak akun pelanggan sebelum sesi disimpan.
    final flavor = AppConfig.instance.flavor;
    if (flavor != AppFlavor.customer && user.isCustomerAccount) {
      throw const ApiException('Akun ini adalah akun pelanggan, bukan akun kasir/staf toko. Gunakan aplikasi Velora Customer.');
    }

    // Edge case Google Auth / akun baru tanpa tenant aktif: jangan simpan sesi kasir kosong.
    final hasTenantFlag = data['has_tenant'];
    if (flavor != AppFlavor.customer &&
        (hasTenantFlag == false || (user.tenantId.isEmpty && !user.isVeloraStaff))) {
      throw const ApiException(
        'Akun Anda belum terhubung dengan bisnis/toko aktif. Silakan daftar bisnis baru atau hubungi administrator.',
      );
    }

    await SessionStorage.instance.saveAuthToken(token);
    await SessionStorage.instance.saveTenantId(user.tenantId);
    await SessionStorage.instance.saveUserProfile(
      id: user.id,
      name: user.name,
      email: user.email,
      businessType: user.businessType,
      role: user.role,
    );
    await SessionStorage.instance.saveUserPermissions(user.permissions);
    final tenantMap = data.getMap('tenant');
    final storeLogo = tenantMap.getString(
      'logo',
      fallback: tenantMap.getString(
        'logo_url',
        fallback: tenantMap.getString(
          'store_logo',
          fallback: data.getString(
            'logo',
            fallback: data.getString(
              'logo_url',
              fallback: userJson.getString('logo', fallback: userJson.getString('logo_url')),
            ),
          ),
        ),
      ),
    );
    await SessionStorage.instance.saveTenantProfile(
      name: user.tenantName,
      address: tenantMap.getString('address'),
      phone: tenantMap.getString('phone'),
      logo: storeLogo.isNotEmpty ? storeLogo : null,
    );

    final activeLocId = userJson.getString('location_id');
    final activeLocMap = userJson.getMap('location');
    final activeLocName = activeLocMap.getString('name', fallback: 'Cabang Utama');

    if (activeLocId.isNotEmpty) {
      await SessionStorage.instance.saveLocation(id: activeLocId, name: activeLocName);
    } else if (user.locations.isNotEmpty) {
      final primary = user.locations.firstWhere(
        (l) => l.isMain,
        orElse: () => user.locations.first,
      );
      await SessionStorage.instance.saveLocation(id: primary.id, name: primary.name);
    }

    return user;
  }

  /// Live validation of current session token against backend /me
  Future<AuthUser?> getProfile() async {
    try {
      Response response;
      try {
        response = await ApiClient.instance.dio.get('/v1/me');
      } on DioException catch (e) {
        if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
          response = await ApiClient.instance.dio.get('/me');
        } else {
          rethrow;
        }
      }
      final rawData = response.data;
      Map<String, dynamic> data = {};
      if (rawData is Map) {
        final inner = rawData['data'];
        data = inner is Map
            ? Map<String, dynamic>.from(inner)
            : Map<String, dynamic>.from(rawData);
      }
      final user = AuthUser.fromJson(data);
      final tenantMap = data.getMap('tenant');
      final storeLogo = tenantMap.getString(
        'logo',
        fallback: tenantMap.getString(
          'logo_url',
          fallback: tenantMap.getString(
            'store_logo',
            fallback: data.getString(
              'logo',
              fallback: data.getString('logo_url'),
            ),
          ),
        ),
      );
      final tenantName = tenantMap.getString(
        'cafe_name',
        fallback: tenantMap.getString(
          'business_name',
          fallback: tenantMap.getString(
            'name',
            fallback: tenantMap.getString(
              'store_name',
              fallback: data.getString(
                'cafe_name',
                fallback: data.getString(
                  'business_name',
                  fallback: data.getString('store_name', fallback: data.getString('tenant_name', fallback: user.tenantName)),
                ),
              ),
            ),
          ),
        ),
      );
      if (tenantName.isNotEmpty || storeLogo.isNotEmpty) {
        await SessionStorage.instance.saveTenantProfile(
          name: tenantName.isNotEmpty ? tenantName : user.tenantName,
          address: tenantMap.getString('address'),
          phone: tenantMap.getString('phone'),
          logo: storeLogo.isNotEmpty ? storeLogo : null,
        );
      }
      return user;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return null;
      }
      rethrow;
    }
  }

  Future<void> selectBranch(BranchLocation location) async {
    await SessionStorage.instance.saveLocation(id: location.id, name: location.name);
    // Bersihkan cache katalog RAM cabang sebelumnya agar tidak tertukar
    ProductCatalogService.instance.clearMemoryCache();
  }

  Future<void> logout() async {
    try {
      await ApiClient.instance.dio.post('/v1/auth/logout');
    } catch (e) {
      debugPrint('[AuthService] Logout API notification failed (session will still clear): $e');
    }
    if (_googleSignInInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (e) {
        debugPrint('[AuthService] Google sign-out ignored: $e');
      }
    }
    // Bersihkan sesi kasir secara tuntas sambil tetap mengamankan antrean transaksi offline
    await SessionStorage.instance.clearUserSession(preserveOfflineQueue: true);
    ProductCatalogService.instance.clearMemoryCache();
  }

  Never _extractAndThrowAuthError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final messages = <String>[];
        for (final item in errors.values) {
          if (item is List && item.isNotEmpty) {
            messages.add(item.first.toString());
          } else if (item is String && item.isNotEmpty) {
            messages.add(item);
          }
        }
        if (messages.isNotEmpty) {
          throw ApiException(messages.join('\n'), statusCode: e.response?.statusCode);
        }
      }
      final msg = data['message']?.toString();
      if (msg != null && msg.isNotEmpty) {
        throw ApiException(msg, statusCode: e.response?.statusCode);
      }
    }
    throw ApiException.from(e);
  }

  /// Mengambil konfigurasi publik auth & skema registrasi dinamis dari `GET /v1/auth/settings`.
  Future<AuthPublicSettings> getAuthSettings() async {
    try {
      final response = await ApiClient.instance.dio.get('/v1/auth/settings');
      final raw = response.data;
      if (raw is Map) {
        final inner = raw['data'];
        final map = inner is Map
            ? Map<String, dynamic>.from(inner)
            : Map<String, dynamic>.from(raw);
        return AuthPublicSettings.fromJson(map);
      }
    } catch (e) {
      debugPrint('[AuthService] getAuthSettings fallback to default: $e');
    }
    return AuthPublicSettings.defaults();
  }

  /// Registrasi tenant / toko baru langsung dari aplikasi mobile (`POST /api/v1/register`)
  /// Mendukung tipe bisnis `cafe`, `retail`, `pharmacy`, dan `pbf` beserta field ekstra regulasi.
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    required String storeName,
    String? username,
    String? phone,
    String businessType = 'cafe',
    Map<String, String> extraFields = const {},
    String? address,
    String? voucherCode,
  }) async {
    final mappedType = (businessType == 'fnb' || businessType == 'cafe')
        ? 'cafe'
        : businessType.trim().toLowerCase();

    final cleanPhone = (phone != null && phone.trim().isNotEmpty)
        ? phone.trim().replaceAll(AppRegex.nonDigits, '')
        : '';

    final emailPrefix = email.split('@').first.toLowerCase().replaceAll(_identifierCleanRegex, '');
    final cleanUsername = (username != null && username.trim().isNotEmpty)
        ? username.trim().toLowerCase().replaceAll(_identifierCleanRegex, '')
        : (emailPrefix.length >= 3 ? emailPrefix : '${emailPrefix}123');

    final clientType = kIsWeb
        ? 'flutter_web'
        : (Platform.isIOS ? 'flutter_ios' : 'flutter_android');
    final deviceName = kIsWeb
        ? 'Velora Web POS'
        : (Platform.isIOS ? 'Velora Flutter iOS' : 'Velora Flutter Android');

    final payload = <String, dynamic>{
      'business_type': mappedType,
      'business_name': storeName.trim(),
      'name': name.trim(),
      'email': email.trim(),
      'username': cleanUsername,
      'phone': cleanPhone,
      'password': password,
      'device_name': deviceName,
      'client_type': clientType,
    };

    if (address != null && address.trim().isNotEmpty) {
      payload['address'] = address.trim();
    }
    if (voucherCode != null && voucherCode.trim().isNotEmpty) {
      payload['voucher_code'] = voucherCode.trim().toUpperCase();
    }

    // Field ekstra dinamis per tipe bisnis (pharmacy & pbf mendukung sia/sipa/pharmacist_name; semua mendukung npwp_number)
    final isPharmaOrPbf = mappedType == 'pharmacy' || mappedType == 'pbf';
    for (final entry in extraFields.entries) {
      final key = entry.key.trim();
      final val = entry.value.trim();
      if (val.isEmpty) continue;
      if (!isPharmaOrPbf &&
          (key == 'sia_number' || key == 'sipa_number' || key == 'pharmacist_name')) {
        continue;
      }
      payload[key] = val;
    }

    Response response;
    try {
      response = await ApiClient.instance.dio.post(
        '/v1/register',
        data: payload,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        try {
          response = await ApiClient.instance.dio.post(
            '/v1/auth/register',
            data: payload,
          );
        } on DioException catch (e2) {
          _extractAndThrowAuthError(e2);
        }
      } else {
        _extractAndThrowAuthError(e);
      }
    }

    final rawData = response.data;
    Map<String, dynamic> parsed = {};
    if (rawData is Map) {
      final inner = rawData['data'];
      parsed = inner is Map
          ? Map<String, dynamic>.from(inner)
          : Map<String, dynamic>.from(rawData);
    }
    final hasToken = parsed.getString('access_token', fallback: parsed.getString('token')).isNotEmpty;
    if (hasToken) {
      return await _processAuthResponse(rawData);
    }
    return await login(email: email, password: password);
  }

  /// Mengirim permintaan tautan reset kata sandi ke backend
  Future<void> forgotPassword(String email) async {
    final payload = {'email': email.trim()};
    try {
      await ApiClient.instance.dio.post(
        '/v1/auth/forgot-password',
        data: payload,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        try {
          await ApiClient.instance.dio.post(
            '/auth/forgot-password',
            data: payload,
          );
        } on DioException catch (e2) {
          _extractAndThrowAuthError(e2);
        }
      } else {
        _extractAndThrowAuthError(e);
      }
    }
  }

  Future<bool> hasQuickPin() async {
    final saved = await SessionStorage.instance.getUserPin();
    return saved != null && saved.isNotEmpty;
  }

  /// Verifikasi PIN kasir secara hybrid (lokal perangkat + server backend)
  /// Sisa waktu kunci PIN akibat terlalu banyak percobaan gagal (null = tidak terkunci)
  Duration? quickPinLockRemaining() {
    final until = SessionStorage.instance.getPinLockedUntil();
    if (until == null) return null;
    final diff = until.difference(DateTime.now());
    return diff.isNegative ? null : diff;
  }

  /// Bandingkan string dengan waktu konstan (mencegah timing attack)
  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  Future<void> _registerPinFailure() async {
    final fails = SessionStorage.instance.getPinFailCount() + 1;
    DateTime? lockedUntil;
    // Setelah 5x gagal: kunci 30 detik, lalu berlipat (60, 120, ... maks 15 menit)
    if (fails >= 5) {
      final exp = (fails - 5).clamp(0, 5);
      final seconds = (30 * (1 << exp)).clamp(30, 900);
      lockedUntil = DateTime.now().add(Duration(seconds: seconds));
    }
    await SessionStorage.instance.savePinLockState(failCount: fails, lockedUntil: lockedUntil);
  }

  Future<bool> verifyQuickPin(String pin) async {
    // Tolak langsung bila masih dalam masa kunci anti brute-force
    if (quickPinLockRemaining() != null) return false;

    final ok = await _verifyQuickPinInternal(pin);
    if (ok) {
      await SessionStorage.instance.savePinLockState(failCount: 0);
    } else {
      await _registerPinFailure();
    }
    return ok;
  }

  /// Komputasi hash kriptografis PIN dengan salt berbasis Device ID kasir
  static String hashPin(String pin, String salt) {
    final bytes = utf8.encode('$pin:$salt:velora_pos_salt_v1');
    return sha256.convert(bytes).toString();
  }

  Future<bool> _verifyQuickPinInternal(String pin) async {
    final savedPinOrHash = await SessionStorage.instance.getUserPin();
    final deviceId = await SessionStorage.instance.getDeviceId();
    final computedHash = hashPin(pin, deviceId);

    if (savedPinOrHash != null && savedPinOrHash.isNotEmpty) {
      // 1. Verifikasi jika sudah berupa hash SHA-256 (panjang 64 karakter hex)
      if (savedPinOrHash.length == 64 && _constantTimeEquals(computedHash, savedPinOrHash)) {
        return true;
      }

      // 2. Backward compatibility: Jika masih berupa plaintext PIN lama
      if (savedPinOrHash.length != 64 && _constantTimeEquals(pin, savedPinOrHash)) {
        // Otomatis upgrade ke salted SHA-256 hash di Keystore
        await SessionStorage.instance.saveUserPin(computedHash);
        return true;
      }
    }

    // Jika belum tersimpan lokal atau tidak cocok, coba verifikasi ke backend
    try {
      final response = await ApiClient.instance.dio.post(
        '/v1/auth/pin/verify',
        data: {'pin': pin},
      );
      final body = response.data;
      final isValid = body is Map && (body['valid'] == true || body['status'] == 'success');
      if (isValid) {
        await SessionStorage.instance.saveUserPin(computedHash);
        return true;
      }
    } catch (e) {
      debugPrint('[AuthService] Quick PIN verification error: $e');
    }

    return false;
  }

  /// Simpan hash PIN kasir ke secure storage lokal dan sinkronisasi PIN ke backend
  Future<void> setQuickPin(String pin) async {
    final deviceId = await SessionStorage.instance.getDeviceId();
    final pinHash = hashPin(pin, deviceId);
    await SessionStorage.instance.saveUserPin(pinHash);
    try {
      await ApiClient.instance.dio.post(
        '/v1/auth/pin',
        data: {'pin': pin},
      );
    } catch (e) {
      debugPrint('[AuthService] Sinkronisasi PIN backend: $e');
    }
  }
}

/// Konfigurasi publik auth & skema registrasi dinamis dari `GET /api/v1/auth/settings`.
class AuthPublicSettings {
  const AuthPublicSettings({
    required this.allowPublicRegistration,
    required this.allowPasswordReset,
    required this.maintenanceMode,
    required this.enableGoogleAuth,
    required this.registrationSchema,
  });

  final bool allowPublicRegistration;
  final bool allowPasswordReset;
  final bool maintenanceMode;
  final bool enableGoogleAuth;
  final Map<String, RegistrationTypeSchema> registrationSchema;

  RegistrationTypeSchema schemaFor(String businessType) {
    final key = businessType.trim().toLowerCase();
    return registrationSchema[key] ??
        defaults().registrationSchema[key] ??
        defaults().registrationSchema['cafe']!;
  }

  factory AuthPublicSettings.fromJson(Map<String, dynamic> json) {
    final fallback = AuthPublicSettings.defaults();
    final rawSchema = json['registration_schema'];
    final parsedSchema = <String, RegistrationTypeSchema>{};
    if (rawSchema is Map) {
      for (final entry in rawSchema.entries) {
        final key = entry.key.toString().toLowerCase();
        if (entry.value is Map) {
          parsedSchema[key] = RegistrationTypeSchema.fromJson(
            key,
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
      }
    }

    return AuthPublicSettings(
      allowPublicRegistration: json['allow_public_registration'] is bool
          ? json['allow_public_registration'] as bool
          : fallback.allowPublicRegistration,
      allowPasswordReset: json['allow_password_reset'] is bool
          ? json['allow_password_reset'] as bool
          : fallback.allowPasswordReset,
      maintenanceMode: json['maintenance_mode'] is bool
          ? json['maintenance_mode'] as bool
          : fallback.maintenanceMode,
      enableGoogleAuth: json['enable_google_auth'] is bool
          ? json['enable_google_auth'] as bool
          : fallback.enableGoogleAuth,
      registrationSchema:
          parsedSchema.isNotEmpty ? parsedSchema : fallback.registrationSchema,
    );
  }

  factory AuthPublicSettings.defaults() {
    return const AuthPublicSettings(
      allowPublicRegistration: true,
      allowPasswordReset: true,
      maintenanceMode: false,
      enableGoogleAuth: true,
      registrationSchema: {
        'cafe': RegistrationTypeSchema(
          key: 'cafe',
          label: 'Cafe & F&B',
          businessNameLabel: 'Nama Cafe / Resto',
          extraFields: [
            RegistrationExtraField(key: 'npwp_number', label: 'NPWP', required: false),
          ],
        ),
        'retail': RegistrationTypeSchema(
          key: 'retail',
          label: 'Retail / Toko',
          businessNameLabel: 'Nama Toko',
          extraFields: [
            RegistrationExtraField(key: 'npwp_number', label: 'NPWP', required: false),
          ],
        ),
        'pharmacy': RegistrationTypeSchema(
          key: 'pharmacy',
          label: 'Apotek',
          businessNameLabel: 'Nama Apotek',
          extraFields: [
            RegistrationExtraField(key: 'sia_number', label: 'Nomor SIA', required: false),
            RegistrationExtraField(key: 'sipa_number', label: 'Nomor SIPA', required: false),
            RegistrationExtraField(
              key: 'pharmacist_name',
              label: 'Nama Apoteker Penanggung Jawab',
              required: false,
            ),
            RegistrationExtraField(key: 'npwp_number', label: 'NPWP', required: false),
          ],
        ),
        'pbf': RegistrationTypeSchema(
          key: 'pbf',
          label: 'PBF (Distributor)',
          businessNameLabel: 'Nama PBF / Distributor',
          extraFields: [
            RegistrationExtraField(
              key: 'sia_number',
              label: 'Nomor Izin PBF / Sertifikat Distribusi',
              required: false,
            ),
            RegistrationExtraField(
              key: 'sipa_number',
              label: 'Nomor SIPA APJ PBF',
              required: false,
            ),
            RegistrationExtraField(
              key: 'pharmacist_name',
              label: 'Nama Apoteker Penanggung Jawab PBF',
              required: false,
            ),
            RegistrationExtraField(key: 'npwp_number', label: 'NPWP', required: false),
          ],
        ),
      },
    );
  }
}

class RegistrationTypeSchema {
  const RegistrationTypeSchema({
    required this.key,
    required this.label,
    required this.businessNameLabel,
    required this.extraFields,
  });

  final String key;
  final String label;
  final String businessNameLabel;
  final List<RegistrationExtraField> extraFields;

  factory RegistrationTypeSchema.fromJson(String key, Map<String, dynamic> json) {
    final fields = <RegistrationExtraField>[];
    final rawFields = json['extra_fields'];
    if (rawFields is List) {
      for (final item in rawFields) {
        if (item is Map) {
          final m = Map<String, dynamic>.from(item);
          final fKey = m['key']?.toString() ?? '';
          if (fKey.isNotEmpty) {
            fields.add(
              RegistrationExtraField(
                key: fKey,
                label: m['label']?.toString() ?? fKey,
                required: m['required'] == true,
              ),
            );
          }
        }
      }
    }
    return RegistrationTypeSchema(
      key: key,
      label: json['label']?.toString() ?? key.toUpperCase(),
      businessNameLabel: json['business_name_label']?.toString() ?? 'Nama Bisnis',
      extraFields: fields,
    );
  }
}

class RegistrationExtraField {
  const RegistrationExtraField({
    required this.key,
    required this.label,
    this.required = false,
  });

  final String key;
  final String label;
  final bool required;
}
