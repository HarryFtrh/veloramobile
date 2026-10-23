import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import 'subscription_model.dart';

class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  TenantSubscription? _cached;

  /// Ambil data langganan tenant aktif (V1-First dengan multi-level fallback)
  Future<TenantSubscription> getSubscription({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached != null) {
      return _cached!;
    }

    // 1. Coba baca dari memori / local cache dulu jika ada
    final cachedStr = SessionStorage.instance.getSubscriptionCache();
    if (!forceRefresh && cachedStr != null && cachedStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedStr);
        if (decoded is Map<String, dynamic>) {
          _cached = TenantSubscription.fromJson(decoded);
          return _cached!;
        }
      } catch (_) {}
    }

    final dio = ApiClient.instance.dio;
    final tenantId = SessionStorage.instance.getTenantId();
    final tenantName = SessionStorage.instance.getUserName() ?? 'Toko';

    // 2. Urutan endpoint V1-First
    final endpoints = [
      '/v1/tenant/subscription',
      '/v1/subscription',
      '/v1/billing/subscription',
      '/v1/pos/config',
      '/subscription',
    ];

    for (final ep in endpoints) {
      try {
        final res = await dio.get(
          ep,
          queryParameters: {
            if (tenantId != null && tenantId.isNotEmpty) 'tenant_id': tenantId,
          },
        );

        if (res.statusCode == 200 && res.data != null) {
          final data = res.data;
          Map<String, dynamic>? subMap;

          if (data is Map) {
            final map = Map<String, dynamic>.from(data);
            if (map.containsKey('subscription') && map['subscription'] is Map) {
              subMap = Map<String, dynamic>.from(map['subscription'] as Map);
            } else if (map.containsKey('data') && map['data'] is Map) {
              final inner = Map<String, dynamic>.from(map['data'] as Map);
              if (inner.containsKey('subscription') && inner['subscription'] is Map) {
                subMap = Map<String, dynamic>.from(inner['subscription'] as Map);
              } else {
                subMap = inner;
              }
            } else {
              subMap = map;
            }
          }

          if (subMap != null && (subMap.containsKey('plan_name') || subMap.containsKey('status') || subMap.containsKey('plan'))) {
            final parsed = TenantSubscription.fromJson(subMap);
            _cached = parsed;
            try {
              await SessionStorage.instance.saveSubscriptionCache(jsonEncode(parsed.toJson()));
            } catch (_) {}
            return parsed;
          }
        }
      } on DioException catch (e) {
        // Jika 404, lanjutkan ke fallback endpoint berikutnya
        if (e.response?.statusCode == 404) continue;
        // Jika offline atau error lain, fallback ke cache jika ada
        if (_cached != null) return _cached!;
      } catch (_) {
        if (_cached != null) return _cached!;
      }
    }

    // 3. Fallback standar jika backend belum mengaktifkan modul langganan
    final fallback = TenantSubscription.standard(tenantName: tenantName);
    _cached = fallback;
    return fallback;
  }

  void clearCache() {
    _cached = null;
  }
}
