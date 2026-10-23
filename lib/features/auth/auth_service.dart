import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/safe_json.dart';

enum AppPermission {
  viewDashboard,
  changeBranch,
  writeOffDebt,
  manageProducts,
  applyDiscount,
  accessPos,
  manageTables,
  viewKitchen,
  viewCustomers;

  List<String> get aliases {
    switch (this) {
      case AppPermission.viewDashboard:
        return const [
          'dashboard.view',
          'dashboard:view',
          'view:dashboard',
          'dashboard.read',
          'read:dashboard',
          'dashboard',
          'reports.view',
          'reports',
          'analytics.view',
          'view-dashboard',
          'view_dashboard',
        ];
      case AppPermission.changeBranch:
        return const [
          'branches.switch',
          'branches:switch',
          'switch:branches',
          'branches.manage',
          'locations.switch',
          'locations:switch',
          'switch:locations',
          'locations.manage',
          'branches',
          'locations',
          'change-branch',
          'change_branch',
        ];
      case AppPermission.writeOffDebt:
        return const [
          'debt.delete',
          'debt.writeoff',
          'debt:delete',
          'debt:writeoff',
          'customers.manage_debt',
          'customers.delete',
          'writeoff-debt',
        ];
      case AppPermission.manageProducts:
        return const [
          'products.create',
          'products.edit',
          'products.delete',
          'products.manage',
          'products:manage',
          'manage:products',
          'products',
        ];
      case AppPermission.applyDiscount:
        return const [
          'discounts.apply',
          'discounts:apply',
          'orders.discount',
          'discounts',
        ];
      case AppPermission.accessPos:
        return const [
          'pos.access',
          'pos:access',
          'access:pos',
          'pos.sales',
          'orders.create',
          'pos',
        ];
      case AppPermission.manageTables:
        return const [
          'tables.view',
          'tables.manage',
          'tables:view',
          'tables:manage',
          'tables',
        ];
      case AppPermission.viewKitchen:
        return const [
          'kitchen.view',
          'kitchen:view',
          'view:kitchen',
          'kds.access',
          'kds:access',
          'kitchen',
        ];
      case AppPermission.viewCustomers:
        return const [
          'customers.view',
          'customers.manage',
          'customers:view',
          'customers:manage',
          'customers',
        ];
    }
  }

  bool defaultFallback(AuthUser user) {
    switch (this) {
      case AppPermission.viewDashboard:
      case AppPermission.changeBranch:
      case AppPermission.writeOffDebt:
      case AppPermission.manageProducts:
        return user.isOwnerOrAdmin;
      case AppPermission.applyDiscount:
      case AppPermission.accessPos:
      case AppPermission.manageTables:
      case AppPermission.viewKitchen:
      case AppPermission.viewCustomers:
        return true;
    }
  }
}

class AuthUser {
  final int id;
  final String name;
  final String email;
  final String role;
  final List<String> permissions;
  final String tenantId;
  final String tenantName;
  final String businessType;
  final List<BranchLocation> locations;

  AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'cashier',
    this.permissions = const [],
    required this.tenantId,
    required this.tenantName,
    required this.businessType,
    required this.locations,
  });

  AuthUser copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    List<String>? permissions,
    String? tenantId,
    String? tenantName,
    String? businessType,
    List<BranchLocation>? locations,
  }) {
    return AuthUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      tenantId: tenantId ?? this.tenantId,
      tenantName: tenantName ?? this.tenantName,
      businessType: businessType ?? this.businessType,
      locations: locations ?? this.locations,
    );
  }

  /// Apakah pengguna ini adalah owner, admin, atau manager yang berhak mengelola cabang
  bool get isOwnerOrAdmin {
    final r = role.toLowerCase().trim();
    return r == 'owner' ||
        r == 'admin' ||
        r == 'administrator' ||
        r == 'manager' ||
        r == 'supervisor';
  }

  /// Apakah pengguna ini adalah kasir atau staf toko biasa
  bool get isCashier => !isOwnerOrAdmin;

  /// Apakah akun ini eksplisit bertipe pelanggan/member (bukan staf toko).
  /// Hanya role yang eksplisit dikirim backend yang dianggap pelanggan.
  bool get isCustomerAccount {
    final r = role.toLowerCase().trim();
    return r == 'customer' || r == 'member' || r == 'guest' || r == 'pelanggan';
  }

  /// Nama label role bahasa Indonesia yang rapi untuk UI
  String get roleDisplayName {
    final r = role.toLowerCase().trim();
    if (r == 'owner') return 'Owner';
    if (r == 'admin' || r == 'administrator') return 'Administrator';
    if (r == 'manager') return 'Manajer';
    if (r == 'supervisor') return 'Supervisor';
    if (r == 'barista') return 'Barista';
    if (r == 'waiter' || r == 'pelayan') return 'Pelayan';
    return 'Kasir';
  }

  static String _extractRole(Map<String, dynamic>? json) {
    if (json == null) return 'cashier';
    final direct = json.getString('role');
    if (direct.isNotEmpty) return direct;

    final roleMap = json.getMap('role');
    if (roleMap.isNotEmpty) {
      final name = roleMap.getString('name');
      if (name.isNotEmpty) return name;
    }

    final rawRoles = json['roles'];
    if (rawRoles is List && rawRoles.isNotEmpty) {
      final first = rawRoles.first;
      if (first is String && first.isNotEmpty) return first;
      if (first is Map) {
        final name = first['name']?.toString();
        if (name != null && name.isNotEmpty) return name;
      }
    }

    final roleName = json.getString('role_name');
    if (roleName.isNotEmpty) return roleName;

    return 'cashier';
  }

  static List<String> _extractPermissions(Map<String, dynamic>? json) {
    if (json == null) return const [];
    final Set<String> perms = {};

    void addFrom(dynamic list) {
      if (list is List) {
        for (final item in list) {
          if (item is String && item.trim().isNotEmpty) {
            perms.add(item.trim().toLowerCase());
          } else if (item is Map) {
            // 1. Spatie / Standard Permission format: { name: '...', slug: '...' }
            final name = item['name']?.toString() ?? item['slug']?.toString();
            if (name != null && name.trim().isNotEmpty) {
              perms.add(name.trim().toLowerCase());
            }

            // 2. CASL Format: { action: '...', subject: '...' }
            final rawAction = item['action'];
            final rawSubject = item['subject'];

            final actions = <String>[];
            if (rawAction is String && rawAction.trim().isNotEmpty) {
              actions.add(rawAction.trim().toLowerCase());
            } else if (rawAction is List) {
              for (final a in rawAction) {
                if (a is String && a.trim().isNotEmpty) {
                  actions.add(a.trim().toLowerCase());
                }
              }
            }

            final subjects = <String>[];
            if (rawSubject is String && rawSubject.trim().isNotEmpty) {
              subjects.add(rawSubject.trim().toLowerCase());
            } else if (rawSubject is List) {
              for (final s in rawSubject) {
                if (s is String && s.trim().isNotEmpty) {
                  subjects.add(s.trim().toLowerCase());
                }
              }
            }

            for (final action in actions) {
              for (final subject in subjects) {
                if (action == 'manage' && (subject == 'all' || subject == '*')) {
                  perms.add('*');
                  perms.add('all');
                  perms.add('manage:all');
                  perms.add('manage.all');
                } else {
                  perms.add('$subject.$action');
                  perms.add('$action:$subject');
                  perms.add('$subject:$action');
                  perms.add('$action-$subject');
                  perms.add('$subject-$action');

                  if (action == 'manage') {
                    perms.add(subject);
                    perms.add('$subject.*');
                  }
                  if (subject == 'all' || subject == '*') {
                    perms.add(action);
                    perms.add('*.$action');
                  }
                }
              }
            }
          }
        }
      }
    }

    addFrom(json['permissions']);
    addFrom(json['abilities']);
    addFrom(json['rules']); // CASL standard
    addFrom(json['casl_rules']);
    addFrom(json['ability_rules']);

    final roleMap = json.getMap('role');
    if (roleMap.isNotEmpty) {
      addFrom(roleMap['permissions']);
      addFrom(roleMap['abilities']);
      addFrom(roleMap['rules']);
    }

    final rawRoles = json['roles'];
    if (rawRoles is List) {
      for (final r in rawRoles) {
        if (r is Map) {
          addFrom(r['permissions']);
          addFrom(r['abilities']);
          addFrom(r['rules']);
        }
      }
    }

    final userMap = json.getMap('user');
    if (userMap.isNotEmpty) {
      addFrom(userMap['permissions']);
      addFrom(userMap['abilities']);
      addFrom(userMap['rules']);
    }

    return perms.toList(growable: false);
  }

  factory AuthUser.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return AuthUser(
        id: 0,
        name: 'Kasir',
        email: '',
        tenantId: '',
        tenantName: '',
        businessType: 'retail',
        locations: const [],
      );
    }

    final userMap = json.getMap('user');
    final source = userMap.isNotEmpty ? userMap : json;

    final tenant = source.getMap('tenant').isNotEmpty
        ? source.getMap('tenant')
        : json.getMap('tenant');

    final locList = (source['locations'] is List ? source : json).getList<BranchLocation>(
      'locations',
      (e) => BranchLocation.fromJson(e is Map<String, dynamic> ? e : null),
    );

    final perms = {
      ..._extractPermissions(json),
      ..._extractPermissions(source),
    }.toList();

    return AuthUser(
      id: source.getInt('id', fallback: json.getInt('id')),
      name: source.getString('name', fallback: json.getString('name', fallback: 'Kasir')),
      email: source.getString('email', fallback: json.getString('email')),
      role: _extractRole(source.isNotEmpty ? source : json),
      permissions: perms,
      tenantId: source.getString('tenant_id', fallback: json.getString('tenant_id', fallback: json.getString('current_tenant_id'))),
      tenantName: tenant.getString('name', fallback: source.getString('store_name', fallback: json.getString('store_name', fallback: ''))),
      businessType: tenant.getString('business_type', fallback: source.getString('business_type', fallback: json.getString('business_type', fallback: 'retail'))),
      locations: locList,
    );
  }
}

extension UserAbility on AuthUser {
  /// Memeriksa hak akses ala CASL (mendukung API permissions + fallback role cerdas)
  bool can(AppPermission permission) {
    if (permissions.contains('*') ||
        permissions.contains('all') ||
        permissions.contains('manage:all') ||
        permissions.contains('superadmin')) {
      return true;
    }

    for (final slug in permission.aliases) {
      if (permissions.contains(slug.toLowerCase())) {
        return true;
      }
    }

    // Jika API secara eksplisit memberikan array permissions tapi tidak ada yang cocok
    if (permissions.isNotEmpty) {
      return false;
    }

    // Smart fallback berbasis role jika array permissions kosong/belum dikirim backend
    return permission.defaultFallback(this);
  }

  bool cannot(AppPermission permission) => !can(permission);
}

class BranchLocation {
  final String id;
  final String name;
  final bool isMain;

  BranchLocation({
    required this.id,
    required this.name,
    this.isMain = false,
  });

  factory BranchLocation.fromJson(Map<String, dynamic>? json) {
    return BranchLocation(
      id: json.getString('id'),
      name: json.getString('name', fallback: 'Cabang Kasir'),
      isMain: json.getBool('is_main_location', fallback: json.getBool('is_main')),
    );
  }
}

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final payload = {
      'email': email,
      'password': password,
      'device_name': 'Velora Mobile POS Terminal',
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
      final payload = <String, dynamic>{
        'code': code,
        'device_name': 'Velora Mobile POS Terminal',
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
    if (rawData is Map<String, dynamic>) {
      data = rawData['data'] is Map<String, dynamic>
          ? rawData['data'] as Map<String, dynamic>
          : rawData;
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
    if (rawData is Map<String, dynamic>) {
      data = rawData['data'] is Map<String, dynamic>
          ? rawData['data'] as Map<String, dynamic>
          : rawData;
    }

    final token = data.getString('access_token', fallback: data.getString('token'));
    if (token.isEmpty) {
      throw Exception('Format respon server tidak valid: token otentikasi tidak ditemukan.');
    }

    final userJson = data.getMap('user');
    final rootPerms = AuthUser._extractPermissions(data);
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
    await SessionStorage.instance.saveTenantProfile(
      name: user.tenantName,
      address: tenantMap.getString('address'),
      phone: tenantMap.getString('phone'),
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
      if (rawData is Map<String, dynamic>) {
        data = rawData['data'] is Map<String, dynamic>
            ? rawData['data'] as Map<String, dynamic>
            : rawData;
      }
      return AuthUser.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return null;
      }
      rethrow;
    }
  }

  Future<void> selectBranch(BranchLocation location) async {
    await SessionStorage.instance.saveLocation(id: location.id, name: location.name);
  }

  Future<void> logout() async {
    try {
      try {
        await ApiClient.instance.dio.post('/v1/auth/logout');
      } catch (_) {
        await ApiClient.instance.dio.post('/auth/logout');
      }
    } catch (_) {}
    await SessionStorage.instance.clearAuthToken();
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
        ? phone.trim().replaceAll(RegExp(r'\D'), '')
        : '081234567890';

    final emailPrefix = email.split('@').first.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_.-]'), '');
    final cleanUsername = (username != null && username.trim().isNotEmpty)
        ? username.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_.-]'), '')
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
  Future<bool> verifyQuickPin(String pin) async {
    final savedPin = await SessionStorage.instance.getUserPin();
    if (savedPin != null && savedPin.isNotEmpty && pin == savedPin) {
      return true;
    }

    // Jika belum tersimpan lokal atau tidak cocok, coba verifikasi ke backend
    try {
      Response response;
      try {
        response = await ApiClient.instance.dio.post(
          '/v1/auth/pin/verify',
          data: {'pin': pin},
        );
      } catch (_) {
        response = await ApiClient.instance.dio.post(
          '/auth/pin/verify',
          data: {'pin': pin},
        );
      }
      final body = response.data;
      final isValid = body is Map && (body['valid'] == true || body['status'] == 'success');
      if (isValid) {
        await SessionStorage.instance.saveUserPin(pin);
        return true;
      }
    } catch (_) {}

    return false;
  }

  /// Simpan PIN kasir ke secure storage lokal dan sinkronisasi ke backend
  Future<void> setQuickPin(String pin) async {
    await SessionStorage.instance.saveUserPin(pin);
    try {
      try {
        await ApiClient.instance.dio.post(
          '/v1/auth/pin',
          data: {'pin': pin},
        );
      } catch (_) {
        await ApiClient.instance.dio.post(
          '/auth/pin',
          data: {'pin': pin},
        );
      }
    } catch (_) {
      // Backend mungkin belum mengimplementasikan /auth/pin, penyimpanan lokal tetap aman
    }
  }
}
