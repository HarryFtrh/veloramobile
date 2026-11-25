import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
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

  /// Initiates or completes Google OAuth flow matching Velora backend specification
  Future<AuthUser> loginWithGoogle({String? code, String? state}) async {
    // 1. Jika authorization code sudah tersedia dari callback OAuth
    if (code != null && code.isNotEmpty) {
      final flavor = AppConfig.instance.flavor;
      final deviceName = switch (flavor) {
        AppFlavor.customer => 'Velora Customer Self-Order',
        AppFlavor.pharmacy => 'Velora Pharmacy POS Terminal',
        AppFlavor.sales => 'Velora Sales Mobile Terminal',
        AppFlavor.marketplace => 'Velora Marketplace Terminal',
        _ => 'Velora Mobile POS Terminal',
      };

      final payload = <String, dynamic>{
        'code': code,
        'device_name': deviceName,
      };
      if (state != null) {
        payload['state'] = state;
      }

      Response response;
      try {
        response = await ApiClient.instance.dio.post(
          '/v1/auth/google/callback',
          data: payload,
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
          response = await ApiClient.instance.dio.post(
            '/auth/google/callback',
            data: payload,
          );
        } else {
          rethrow;
        }
      }
      return await _processAuthResponse(response.data);
    }

    // 2. Jika belum ada code, verifikasi status Google Auth di backend
    Response redirectRes;
    try {
      redirectRes = await ApiClient.instance.dio.get(
        '/v1/auth/google/redirect',
        queryParameters: {'action': 'login'},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        redirectRes = await ApiClient.instance.dio.get(
          '/auth/google/redirect',
          queryParameters: {'action': 'login'},
        );
      } else {
        rethrow;
      }
    }

    final rawData = redirectRes.data;
    Map<String, dynamic> data = {};
    if (rawData is Map) {
      final inner = rawData['data'];
      data = inner is Map
          ? Map<String, dynamic>.from(inner)
          : Map<String, dynamic>.from(rawData);
    }

    final url = data['url']?.toString();
    if (url == null || url.isEmpty) {
      throw Exception('URL otentikasi Google tidak tersedia.');
    }

    throw Exception('Login Google aktif. Silakan lanjutkan otentikasi melalui URL: $url');
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
      throw Exception('Akun ini adalah akun pelanggan, bukan akun kasir/staf toko. Gunakan aplikasi Velora Customer.');
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

  /// Registrasi tenant / toko baru langsung dari aplikasi mobile
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    required String storeName,
    String? username,
    String? phone,
    String businessType = 'cafe',
  }) async {
    // Backend mengharapkan 'cafe' untuk bisnis FnB/kafe/restoran
    final mappedType = (businessType == 'fnb' || businessType == 'cafe') ? 'cafe' : businessType;

    final cleanPhone = (phone != null && phone.trim().isNotEmpty)
        ? phone.trim().replaceAll(AppRegex.nonDigits, '')
        : '081234567890';

    final emailPrefix = email.split('@').first.toLowerCase().replaceAll(_identifierCleanRegex, '');
    final cleanUsername = (username != null && username.trim().isNotEmpty)
        ? username.trim().toLowerCase().replaceAll(_identifierCleanRegex, '')
        : (emailPrefix.length >= 3 ? emailPrefix : '${emailPrefix}123');

    final payload = {
      'name': name.trim(),
      'email': email.trim(),
      'username': cleanUsername,
      'phone': cleanPhone.length >= 9 ? cleanPhone : '081234567890',
      'password': password,
      'password_confirmation': password,
      'business_name': storeName.trim(),
      'store_name': storeName.trim(),
      'business_type': mappedType,
      'device_name': 'Velora Mobile POS',
    };

    Response response;
    try {
      response = await ApiClient.instance.dio.post(
        '/v1/auth/register',
        data: payload,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        try {
          response = await ApiClient.instance.dio.post(
            '/auth/register',
            data: payload,
          );
        } on DioException catch (e2) {
          _extractAndThrowAuthError(e2);
        }
      } else {
        _extractAndThrowAuthError(e);
      }
    }

    try {
      return await _processAuthResponse(response.data);
    } catch (_) {
      // Jika endpoint registrasi backend hanya mengembalikan pesan berhasil tanpa token,
      // lakukan auto-login menggunakan kredensial yang baru didaftarkan
      return await login(email: email, password: password);
    }
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
