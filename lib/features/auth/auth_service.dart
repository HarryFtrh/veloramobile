import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';
import '../../core/config/business_vertical.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/safe_json.dart';
import '../shared_pos/product_catalog_service.dart';

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
  final bool isOwner;
  final bool isVeloraStaff;
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
    this.isOwner = false,
    this.isVeloraStaff = false,
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
    bool? isOwner,
    bool? isVeloraStaff,
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
      isOwner: isOwner ?? this.isOwner,
      isVeloraStaff: isVeloraStaff ?? this.isVeloraStaff,
      permissions: permissions ?? this.permissions,
      tenantId: tenantId ?? this.tenantId,
      tenantName: tenantName ?? this.tenantName,
      businessType: businessType ?? this.businessType,
      locations: locations ?? this.locations,
    );
  }

  /// Apakah pengguna ini adalah owner, admin, manager, atau staf elevated (berhak mengelola cabang, shift, dll).
  /// Menggunakan logika terpadu RBAC (Permission), kepemilikan bisnis, dan pola heuristik peran.
  bool get isOwnerOrAdmin {
    // 1. Cek langsung properti kepemilikan / staf internal Velora
    if (isOwner || isVeloraStaff) return true;

    // 2. Berbasis Hak Akses / Permission (RBAC dinamis)
    for (final perm in permissions) {
      final p = perm.toLowerCase();
      if (p == '*' ||
          p == 'all' ||
          p == 'manage:all' ||
          p == 'manage-all' ||
          p == 'manage.all' ||
          p.contains('dashboard') ||
          p.contains('setting-user') ||
          p.contains('manage-shifts') ||
          p.contains('manage-roles') ||
          p.contains('manage-pos')) {
        if (p.contains('dashboard') || p.contains('setting-user') || p.contains('manage-roles') || p.contains('manage-shifts') || p == '*' || p == 'all' || p.contains('manage:all') || p.contains('manage-all')) {
          return true;
        }
      }
    }

    // 3. Fallback Heuristik Pola Nama Role (Dinamis: Owner, Admin, Manager, Supervisor, Kepala Toko, PIC, Leader, Lead, Koordinator)
    final r = role.toLowerCase().trim();
    final elevatedRegex = RegExp(r'(owner|admin|manager|manajer|supervisor|kepala|leader|lead|pic|koordinator)', caseSensitive: false);
    return elevatedRegex.hasMatch(r);
  }

  /// Apakah akun ini adalah dokter atau staf medis pemeriksa (klinis)
  bool get isDoctor {
    final r = role.toLowerCase().trim();
    return r.contains('dok') ||
        r.contains('doc') ||
        r.contains('medis') ||
        r.contains('spesialis') ||
        r.contains('gp') ||
        permissions.any((p) => p.toLowerCase().contains('doctor') || p.toLowerCase().contains('emr'));
  }

  /// Apakah akun ini adalah apoteker atau tenaga teknis kefarmasian (TTK)
  bool get isPharmacist {
    final r = role.toLowerCase().trim();
    return r.contains('apt') ||
        r.contains('apotek') ||
        r.contains('pharma') ||
        r.contains('farmasi') ||
        r.contains('racik') ||
        permissions.any((p) => p.toLowerCase().contains('compounding') || p.toLowerCase().contains('prescription'));
  }

  /// Apakah akun ini adalah staf gudang atau logistik obat
  bool get isWarehouse {
    final r = role.toLowerCase().trim();
    return r.contains('gudang') ||
        r.contains('logis') ||
        r.contains('invent') ||
        r.contains('wareh') ||
        permissions.any((p) => p.toLowerCase().contains('opname') || p.toLowerCase().contains('pbf'));
  }

  /// Apakah akun ini adalah staf dapur / KDS / barista
  bool get isKitchen {
    final r = role.toLowerCase().trim();
    return r.contains('kitchen') ||
        r.contains('dapur') ||
        r.contains('kds') ||
        r.contains('chef') ||
        r.contains('koki') ||
        r.contains('barista');
  }

  /// Apakah akun ini adalah pramusaji / waiter / floor staff
  bool get isWaiter {
    final r = role.toLowerCase().trim();
    return r.contains('waiter') ||
        r.contains('pelayan') ||
        r.contains('pramusaji') ||
        r.contains('floor');
  }

  /// Menentukan vertikal bisnis terpadu secara aman tanpa duplikasi hardcode string
  BusinessVertical get vertical => BusinessVertical.resolve(
        businessType: businessType.isNotEmpty ? businessType : SessionStorage.instance.getBusinessType(),
        role: role,
        flavor: AppConfig.instance.flavor,
      );

  bool get isPharmacyBusiness => vertical == BusinessVertical.pharmacy;
  bool get isFnbBusiness => vertical == BusinessVertical.fnb;
  bool get isRetailBusiness => vertical == BusinessVertical.retail;
  bool get isSalesAccount => vertical == BusinessVertical.sales;
  bool get isMarketplaceAccount => vertical == BusinessVertical.marketplace;

  /// Apakah pengguna ini adalah kasir atau staf toko biasa
  bool get isCashier => !isOwnerOrAdmin && !isDoctor && !isPharmacist && !isWarehouse && !isKitchen && !isWaiter;

  /// Apakah akun ini eksplisit bertipe pelanggan/member (bukan staf toko).
  /// Hanya role yang eksplisit dikirim backend yang dianggap pelanggan.
  bool get isCustomerAccount {
    final r = role.toLowerCase().trim();
    return r == 'customer' || r == 'member' || r == 'guest' || r == 'pelanggan';
  }

  /// Nama label role bahasa Indonesia yang rapi untuk UI
  String get roleDisplayName {
    if (isOwner) return 'Owner';
    if (isDoctor) return 'Dokter Pemeriksa';
    if (isPharmacist) return 'Apoteker Klinis';
    if (isWarehouse) return 'Logistik & Gudang';
    final r = role.toLowerCase().trim();
    if (r == 'owner') return 'Owner';
    if (r == 'admin' || r == 'administrator') return 'Administrator';
    if (r == 'manager' || r == 'manajer') return 'Manajer';
    if (r == 'supervisor') return 'Supervisor';
    if (r.contains('kepala')) return role;
    if (r.contains('lead') || r.contains('pic') || r.contains('koordinator')) return role;
    if (r == 'barista') return 'Barista';
    if (r == 'waiter' || r == 'pelayan') return 'Pelayan';
    return role.isNotEmpty ? role : 'Kasir';
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

    final extractedRole = _extractRole(source.isNotEmpty ? source : json);
    final isOwner = source.getBool(
      'is_owner',
      fallback: json.getBool('is_owner', fallback: extractedRole.toLowerCase().trim() == 'owner'),
    );
    final isVeloraStaff = source.getBool(
      'is_velora_staff',
      fallback: json.getBool('is_velora_staff'),
    );

    return AuthUser(
      id: source.getInt('id', fallback: json.getInt('id')),
      name: source.getString('name', fallback: json.getString('name', fallback: 'Kasir')),
      email: source.getString('email', fallback: json.getString('email')),
      role: extractedRole,
      isOwner: isOwner,
      isVeloraStaff: isVeloraStaff,
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
    if (isOwnerOrAdmin ||
        permissions.contains('*') ||
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

    // Smart fallback berbasis role jika array permissions kosong atau belum ada slug spesifik yang cocok
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
      if (rawData is Map) {
        final inner = rawData['data'];
        data = inner is Map
            ? Map<String, dynamic>.from(inner)
            : Map<String, dynamic>.from(rawData);
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
