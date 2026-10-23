import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SessionStorage {
  static const _tokenKey = 'velora_auth_token';
  static const _tenantIdKey = 'velora_tenant_id';
  static const _tenantNameKey = 'velora_tenant_name';
  static const _storeAddressKey = 'velora_store_address';
  static const _storePhoneKey = 'velora_store_phone';
  static const _locationIdKey = 'velora_location_id';
  static const _locationNameKey = 'velora_location_name';
  static const _userNameKey = 'velora_user_name';
  static const _userPinKey = 'velora_quick_pin';
  static const _qrisNmidKey = 'velora_qris_nmid';
  static const _deviceIdKey = 'velora_device_id';

  static const _userIdKey = 'velora_user_id';
  static const _userEmailKey = 'velora_user_email';
  static const _userRoleKey = 'velora_user_role';
  static const _userPermissionsKey = 'velora_user_permissions';
  static const _businessTypeKey = 'velora_business_type';

  static const _printerIs80mmKey = 'velora_printer_is_80mm';
  static const _printerConnectionTypeKey = 'velora_printer_conn_type';
  static const _printerAddressKey = 'velora_printer_address';
  static const _offlineSalesQueueKey = 'velora_offline_sales_queue';
  static const _subscriptionCacheKey = 'velora_subscription_cache';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;
  final Map<String, dynamic> _memCache = {};

  static SessionStorage? _instance;

  /// Safe singleton accessor yang tidak akan pernah melempar LateInitializationError
  static SessionStorage get instance {
    _instance ??= SessionStorage._();
    return _instance!;
  }

  /// Setter instance untuk kompatibilitas jika dipanggil langsung
  static set instance(SessionStorage val) {
    _instance = val;
  }

  SessionStorage._();

  // Konstruktor default untuk kompatibilitas mundur
  factory SessionStorage() => instance;

  static Future<void> init() async {
    final storage = instance;
    try {
      storage._prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // In-memory cache tetap berjalan jika SharedPreferences gagal atau tertunda
    }
  }

  /// Sanitizer untuk mencegah string 'undefined', 'null', atau empty lolos ke UI/API
  String? _cleanString(String? val) {
    if (val == null) return null;
    final trimmed = val.trim();
    final lower = trimmed.toLowerCase();
    if (trimmed.isEmpty || lower == 'undefined' || lower == 'null') {
      return null;
    }
    return trimmed;
  }

  Future<void> _setString(String key, String? value) async {
    final clean = _cleanString(value);
    if (clean == null) {
      _memCache.remove(key);
      await _prefs?.remove(key);
    } else {
      _memCache[key] = clean;
      await _prefs?.setString(key, clean);
    }
  }

  String? _getString(String key) {
    final fromPrefs = _prefs?.getString(key);
    if (fromPrefs != null) {
      return _cleanString(fromPrefs);
    }
    final fromMem = _memCache[key]?.toString();
    return _cleanString(fromMem);
  }

  Future<void> saveAuthToken(String token) async {
    final clean = _cleanString(token);
    if (clean != null) {
      _memCache[_tokenKey] = clean;
      await _secureStorage.write(key: _tokenKey, value: clean);
    } else {
      await clearAuthToken();
    }
  }

  Future<String?> getAuthToken() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      return _cleanString(token) ?? _cleanString(_memCache[_tokenKey]?.toString());
    } catch (_) {
      return _cleanString(_memCache[_tokenKey]?.toString());
    }
  }

  Future<void> clearAuthToken() async {
    _memCache.remove(_tokenKey);
    try {
      await _secureStorage.delete(key: _tokenKey);
    } catch (_) {}
  }

  Future<void> saveLocation({required String id, required String name}) async {
    await _setString(_locationIdKey, id);
    await _setString(_locationNameKey, name);
  }

  String? getLocationId() => _getString(_locationIdKey);
  String? getLocationName() => _getString(_locationNameKey);

  Future<void> saveTenantId(String tenantId) async {
    await _setString(_tenantIdKey, tenantId);
  }

  String? getTenantId() => _getString(_tenantIdKey);

  Future<void> saveTenantProfile({
    required String name,
    String? address,
    String? phone,
  }) async {
    await _setString(_tenantNameKey, name);
    if (address != null) await _setString(_storeAddressKey, address);
    if (phone != null) await _setString(_storePhoneKey, phone);
  }

  String? getTenantName() => _getString(_tenantNameKey);
  String? getStoreAddress() => _getString(_storeAddressKey);
  String? getStorePhone() => _getString(_storePhoneKey);

  Future<void> saveUserPin(String pin) async {
    final clean = _cleanString(pin);
    if (clean != null) {
      _memCache[_userPinKey] = clean;
      try {
        await _secureStorage.write(key: _userPinKey, value: clean);
      } catch (_) {}
    } else {
      _memCache.remove(_userPinKey);
      try {
        await _secureStorage.delete(key: _userPinKey);
      } catch (_) {}
    }
  }

  Future<String?> getUserPin() async {
    try {
      final pin = await _secureStorage.read(key: _userPinKey);
      return _cleanString(pin) ?? _cleanString(_memCache[_userPinKey]?.toString());
    } catch (_) {
      return _cleanString(_memCache[_userPinKey]?.toString());
    }
  }

  Future<void> saveUserProfile({
    required int id,
    required String name,
    required String email,
    required String businessType,
    String? role,
  }) async {
    _memCache[_userIdKey] = id;
    await _prefs?.setInt(_userIdKey, id);
    await _setString(_userNameKey, name);
    await _setString(_userEmailKey, email);
    await _setString(_businessTypeKey, businessType);
    if (role != null) {
      await saveUserRole(role);
    }
  }

  Future<void> saveUserRole(String role) => _setString(_userRoleKey, role);
  String? getUserRole() => _getString(_userRoleKey);

  Future<void> saveUserPermissions(List<String> permissions) async {
    _memCache[_userPermissionsKey] = permissions;
    await _prefs?.setStringList(_userPermissionsKey, permissions);
  }

  List<String> getUserPermissions() {
    final fromPrefs = _prefs?.getStringList(_userPermissionsKey);
    if (fromPrefs != null) return fromPrefs;
    final fromMem = _memCache[_userPermissionsKey];
    if (fromMem is List) {
      return fromMem.map((e) => e.toString()).toList();
    }
    return const [];
  }

  int? getUserId() {
    final fromPrefs = _prefs?.getInt(_userIdKey);
    if (fromPrefs != null) return fromPrefs;
    final fromMem = _memCache[_userIdKey];
    if (fromMem is int) return fromMem;
    if (fromMem is num) return fromMem.toInt();
    if (fromMem is String) return int.tryParse(fromMem);
    return null;
  }

  String? getUserEmail() => _getString(_userEmailKey);
  String? getBusinessType() => _getString(_businessTypeKey);

  Future<void> saveUserName(String name) async {
    await _setString(_userNameKey, name);
  }

  static const _rememberMeKey = 'velora_remember_me';
  static const _savedLoginIdentifierKey = 'velora_saved_login_identifier';

  Future<void> saveRememberMe({required bool rememberMe, String? identifier}) async {
    _memCache[_rememberMeKey] = rememberMe;
    await _prefs?.setBool(_rememberMeKey, rememberMe);
    if (rememberMe && identifier != null && identifier.isNotEmpty) {
      _memCache[_savedLoginIdentifierKey] = identifier;
      await _prefs?.setString(_savedLoginIdentifierKey, identifier);
    } else if (!rememberMe) {
      _memCache.remove(_savedLoginIdentifierKey);
      await _prefs?.remove(_savedLoginIdentifierKey);
    }
  }

  bool getRememberMe() {
    return _prefs?.getBool(_rememberMeKey) ?? _memCache[_rememberMeKey] ?? true;
  }

  String? getSavedLoginIdentifier() {
    return _prefs?.getString(_savedLoginIdentifierKey) ?? _memCache[_savedLoginIdentifierKey];
  }

  String? getUserName() => _getString(_userNameKey);

  Future<void> saveQrisNmid(String nmid) async {
    await _setString(_qrisNmidKey, nmid);
  }

  String? getQrisNmid() => _getString(_qrisNmidKey);

  Future<String> getDeviceId() async {
    String? id = _getString(_deviceIdKey);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await _setString(_deviceIdKey, id);
    }
    return id;
  }

  Future<void> savePrinterConfig({
    required bool is80mm,
    required String connectionType,
    String? printerAddress,
  }) async {
    _memCache[_printerIs80mmKey] = is80mm;
    await _prefs?.setBool(_printerIs80mmKey, is80mm);
    await _setString(_printerConnectionTypeKey, connectionType);
    if (printerAddress != null) {
      await _setString(_printerAddressKey, printerAddress);
    }
  }

  bool isPrinter80mm() {
    return _prefs?.getBool(_printerIs80mmKey) ??
        (_memCache[_printerIs80mmKey] as bool? ?? false);
  }

  String getPrinterConnectionType() {
    return _getString(_printerConnectionTypeKey) ?? 'Bluetooth';
  }

  String? getPrinterAddress() => _getString(_printerAddressKey);

  List<String> getOfflineQueue() {
    final fromPrefs = _prefs?.getStringList(_offlineSalesQueueKey);
    if (fromPrefs != null) return fromPrefs;
    final fromMem = _memCache[_offlineSalesQueueKey];
    if (fromMem is List<String>) return fromMem;
    return [];
  }

  Future<void> enqueueOfflineSale(String jsonSale) async {
    final queue = List<String>.from(getOfflineQueue());
    queue.add(jsonSale);
    _memCache[_offlineSalesQueueKey] = queue;
    await _prefs?.setStringList(_offlineSalesQueueKey, queue);
  }

  Future<void> clearOfflineQueue() async {
    _memCache.remove(_offlineSalesQueueKey);
    await _prefs?.remove(_offlineSalesQueueKey);
  }

  int getOfflineQueueCount() {
    return getOfflineQueue().length;
  }

  Future<void> saveSubscriptionCache(String jsonStr) async {
    await _setString(_subscriptionCacheKey, jsonStr);
  }

  String? getSubscriptionCache() => _getString(_subscriptionCacheKey);

  Future<void> clearAll() async {
    _memCache.clear();
    try {
      await _secureStorage.deleteAll();
    } catch (_) {}
    try {
      await _prefs?.clear();
    } catch (_) {}
  }
}
