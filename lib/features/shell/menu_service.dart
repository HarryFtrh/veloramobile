import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show compute, debugPrint;
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import 'menu_registry.dart';
import 'more_entry.dart';

export 'menu_registry.dart';

/// Service untuk memanggil GET /api/my-menu dan mengelola server-driven menu
/// Berlaku seragam untuk seluruh tipe bisnis (FnB, Apotek, Retail, Sales, Grosir)
class MenuService {
  static final MenuService instance = MenuService._();
  MenuService._();

  List<MoreEntry>? _cachedEntries;
  List<ServerMenuItem>? _rawMenuItems;

  List<MoreEntry>? get cachedEntries => _cachedEntries;
  List<ServerMenuItem>? get rawMenuItems => _rawMenuItems;

  String _getCacheNamespace() {
    final biz = SessionStorage.instance.getBusinessType()?.toLowerCase() ?? 'default';
    return 'my_menu_$biz';
  }

  /// Memanggil GET /api/my-menu dari backend Velora
  /// Backend (MenuPermissionFilterService) otomatis membuang menu:
  /// 1. Tidak masuk paket tenant (plans)
  /// 2. Berada di disabled_menu_keys / blocked_menu_keys
  /// 3. User tidak punya permission Spatie/CASL
  Future<List<MoreEntry>> fetchMyMenu({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedEntries != null && _cachedEntries!.isNotEmpty) {
      return _cachedEntries!;
    }

    final candidateEndpoints = [
      '/api/my-menu',
      '/my-menu',
      '/v1/my-menu',
      '/api/v1/my-menu',
      '/v1/pos/my-menu',
    ];

    Response<dynamic>? response;
    for (final ep in candidateEndpoints) {
      try {
        final res = await ApiClient.instance.dio.get(ep);
        if (res.statusCode == 200 && res.data != null) {
          response = res;
          break;
        }
      } catch (e) {
        debugPrint('⚠️ [MenuService] Candidate $ep failed: $e');
      }
    }

    final namespace = _getCacheNamespace();

    if (response != null) {
      try {
        final raw = response.data;
        List<dynamic> itemsList = [];
        if (raw is List) {
          itemsList = raw;
        } else if (raw is Map) {
          final d = raw['data'] ?? raw['menus'] ?? raw['items'] ?? raw['menu'];
          if (d is List) {
            itemsList = d;
          } else if (d is Map) {
            // Grouped format: { "Pelayanan": [...], "Pengadaan": [...] }
            for (final entry in d.entries) {
              if (entry.value is List) {
                for (final item in (entry.value as List)) {
                  if (item is Map) {
                    final m = Map<String, dynamic>.from(item);
                    m['category'] ??= entry.key;
                    itemsList.add(m);
                  }
                }
              }
            }
          }
        }

        if (itemsList.isNotEmpty) {
          final serverItems = <ServerMenuItem>[];
          for (final it in itemsList) {
            if (it is Map) {
              final item = ServerMenuItem.fromJson(Map<String, dynamic>.from(it));
              serverItems.add(item);
              // Handle children jika backend mengembalikan nested items
              if (item.children.isNotEmpty) {
                serverItems.addAll(item.children);
              }
            }
          }

          _rawMenuItems = serverItems;

          // Map setiap ServerMenuItem ke MoreEntry via MenuRegistry
          final resolvedEntries = <MoreEntry>[];
          final seenTitles = <String>{};
          for (final item in serverItems) {
            final entry = MenuRegistry.resolve(item);
            if (entry != null && seenTitles.add(entry.title)) {
              resolvedEntries.add(entry);
            }
          }

          if (resolvedEntries.isNotEmpty) {
            _cachedEntries = resolvedEntries;
            // Persist ke SessionStorage per namespace bisnis agar tetap tersedia saat offline
            try {
              final jsonList = serverItems.map((s) => s.toJson()).toList();
              final jsonStr = await compute(jsonEncode, jsonList);
              unawaited(SessionStorage.instance.saveCatalogCache(namespace, jsonStr));
            } catch (_) {}
            return resolvedEntries;
          }
        }
      } catch (e) {
        debugPrint('⚠️ [MenuService] Error parsing my-menu response: $e');
      }
    }

    // Jika gagal network atau offline, coba pulihkan dari SessionStorage
    final diskJson = SessionStorage.instance.getCatalogCache(namespace);
    if (diskJson != null && diskJson.isNotEmpty) {
      try {
        final decoded = await compute(jsonDecode, diskJson);
        if (decoded is List) {
          final restored = <MoreEntry>[];
          final restoredSeen = <String>{};
          for (final it in decoded) {
            if (it is Map) {
              final item = ServerMenuItem.fromJson(Map<String, dynamic>.from(it));
              final entry = MenuRegistry.resolve(item);
              if (entry != null && restoredSeen.add(entry.title)) {
                restored.add(entry);
              }
            }
          }
          if (restored.isNotEmpty) {
            _cachedEntries = restored;
            return restored;
          }
        }
      } catch (_) {}
    }

    return _cachedEntries ?? const [];
  }
}
