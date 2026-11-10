import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/safe_json.dart';

enum KitchenStage { fresh, preparing, ready }

class KitchenItem {
  const KitchenItem({
    required this.id,
    required this.name,
    required this.station,
    required this.quantity,
    required this.done,
    required this.modifiers,
    this.note,
    this.productId,
    this.price,
  });

  final String id;
  final String name;
  final String station;
  final int quantity;
  final bool done;
  final List<String> modifiers;
  final String? note;
  final String? productId;
  final num? price;

  KitchenItem copyWith({bool? done}) => KitchenItem(
        id: id,
        name: name,
        station: station,
        quantity: quantity,
        done: done ?? this.done,
        modifiers: modifiers,
        note: note,
        productId: productId,
        price: price,
      );

  factory KitchenItem.fromJson(Map<String, dynamic> json) {
    final note = json.getString('note').isNotEmpty
        ? json.getString('note')
        : (json.getString('notes').isNotEmpty
            ? json.getString('notes')
            : (json.getString('instructions').isNotEmpty
                ? json.getString('instructions')
                : json.getString('kitchen_note')));

    String itemName = json.getString('name');
    if (itemName.isEmpty && json['product'] is Map) {
      itemName = json['product']['name']?.toString() ?? '';
    }
    if (itemName.isEmpty) {
      itemName = json.getString('product_name', fallback: '-');
    }

    final price = json.getNum('price', fallback: json.getNum('unit_price', fallback: 0));
    final qty = json.getInt('quantity', fallback: json.getInt('qty', fallback: 1));

    // Stasiun / Kategori item
    String stationName = json.getString('category_name');
    if (stationName.isEmpty && json['product'] is Map) {
      final p = json['product'];
      if (p['category'] is Map) {
        stationName = p['category']['name']?.toString() ?? '';
      } else {
        stationName = p['category_name']?.toString() ?? p['category']?.toString() ?? '';
      }
    }
    if (stationName.isEmpty) {
      stationName = json.getString('category', fallback: json.getString('station'));
    }

    // Ekstraksi opsi modifier tanpa database ID
    final rawModifiers = json['modifiers'] ??
        json['options'] ??
        json['item_modifiers'] ??
        json['selected_modifiers'];
    final List<String> modifierList = [];
    if (rawModifiers is List) {
      for (final m in rawModifiers) {
        if (m is String && m.trim().isNotEmpty) {
          final clean = sanitizeDisplayName(m.trim());
          if (clean.isNotEmpty && !modifierList.contains(clean)) {
            modifierList.add(clean);
          }
        } else if (m is Map) {
          final modName = m['name'] ??
              m['option_name'] ??
              m['modifier_name'] ??
              m['label'] ??
              (m['option'] is Map ? m['option']['name'] : null);
          if (modName != null && modName.toString().trim().isNotEmpty) {
            final clean = sanitizeDisplayName(modName.toString().trim());
            if (clean.isNotEmpty && !modifierList.contains(clean)) {
              modifierList.add(clean);
            }
          }
        }
      }
    }

    final isDone = json['done'] == true ||
        json['is_done'] == true ||
        json['status'] == 'done' ||
        json['status'] == 'completed';

    return KitchenItem(
      id: json.getString('id', fallback: json.getString('item_id')),
      name: sanitizeDisplayName(itemName),
      station: stationName.isNotEmpty ? sanitizeDisplayName(stationName) : 'Dapur',
      quantity: qty,
      done: isDone,
      modifiers: modifierList,
      note: note.isEmpty ? null : note,
      productId: json.getString('product_id', fallback: json.getString('menu_item_id')),
      price: price,
    );
  }
}

class KitchenOrder {
  const KitchenOrder({
    required this.id,
    required this.number,
    required this.tableLabel,
    required this.stage,
    required this.createdAt,
    required this.items,
    this.status,
    this.paymentStatus,
    this.kitchenStatus,
    this.customerName,
    this.notes,
    this.totalAmount,
    this.orderType = 'dine_in',
    this.serverName,
  });

  final String id;
  final String number;
  final String tableLabel;
  final KitchenStage stage;
  final DateTime createdAt;
  final List<KitchenItem> items;
  final String? status;
  final String? paymentStatus;
  final String? kitchenStatus;
  final String? customerName;
  final String? notes;
  final num? totalAmount;
  final String orderType;
  final String? serverName;

  bool get isPaid {
    if (KitchenService.instance.isOrderPaid(id)) return true;
    final s = (status ?? '').toLowerCase().trim();
    final ps = (paymentStatus ?? '').toLowerCase().trim();
    return s == 'paid' ||
        s == 'completed' ||
        s == 'settled' ||
        s == 'lunas' ||
        ps == 'paid' ||
        ps == 'completed' ||
        ps == 'settled' ||
        ps == 'lunas';
  }

  bool get isHeld =>
      status == 'held' ||
      status == 'hold' ||
      tableLabel.toLowerCase().contains('hold');

  bool get isTakeaway =>
      orderType.toLowerCase().contains('take') ||
      orderType.toLowerCase().contains('bungkus') ||
      tableLabel.toLowerCase().contains('takeaway') ||
      tableLabel.toLowerCase().contains('bungkus');

  bool get isOnline =>
      orderType.toLowerCase().contains('online') ||
      orderType.toLowerCase().contains('delivery') ||
      orderType.toLowerCase().contains('ojol') ||
      orderType.toLowerCase().contains('gofood') ||
      orderType.toLowerCase().contains('grab');

  int get totalItemsCount => items.fold(0, (sum, i) => sum + i.quantity);
  int get completedItemsCount => items.where((i) => i.done).fold(0, (sum, i) => sum + i.quantity);
  bool get allItemsCompleted => items.isNotEmpty && items.every((i) => i.done);

  KitchenOrder copyWith({
    List<KitchenItem>? items,
    String? status,
    String? paymentStatus,
    String? kitchenStatus,
    KitchenStage? stage,
    String? tableLabel,
    String? customerName,
    String? notes,
  }) => KitchenOrder(
        id: id,
        number: number,
        tableLabel: tableLabel ?? this.tableLabel,
        stage: stage ?? this.stage,
        createdAt: createdAt,
        items: items ?? this.items,
        status: status ?? this.status,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        kitchenStatus: kitchenStatus ?? this.kitchenStatus,
        customerName: customerName ?? this.customerName,
        notes: notes ?? this.notes,
        totalAmount: totalAmount,
        orderType: orderType,
        serverName: serverName,
      );

  factory KitchenOrder.fromJson(Map<String, dynamic> json) {
    final rawKitchenStatus = json.getString('kitchen_status', fallback: json.getString('kitchen_state'));
    final rawOrderStatus = json.getString('status', fallback: json.getString('order_status'));
    final rawPaymentStatus = json.getString(
      'payment_status',
      fallback: json.getString('paid_status', fallback: json['is_paid'] == true ? 'paid' : ''),
    );
    final effectiveStatus = rawKitchenStatus.isNotEmpty ? rawKitchenStatus : rawOrderStatus;

    String customer = json.getString('customer_name');
    if (customer.isEmpty && json['customer'] is Map) {
      customer = json['customer']['name']?.toString() ?? '';
    }

    final notes = json.getString('notes', fallback: json.getString('note'));

    String tableNum = json.getString('table_number');
    if (tableNum.isEmpty && json['table'] is Map) {
      final t = json['table'];
      tableNum = t['name']?.toString() ?? t['table_number']?.toString() ?? '';
    }
    if (tableNum.isEmpty) {
      tableNum = json.getString('table_name', fallback: json.getString('table_id'));
    }

    final rawType = json.getString('order_type', fallback: json.getString('type', fallback: 'dine_in'));

    String server = json.getString('server_name', fallback: json.getString('waiter_name'));
    if (server.isEmpty && json['user'] is Map) {
      server = json['user']['name']?.toString() ?? '';
    }
    if (server.isEmpty && json['cashier'] is Map) {
      server = json['cashier']['name']?.toString() ?? '';
    }

    List<KitchenItem> parsedItems = json.getList<KitchenItem>('items', (e) {
      if (e is Map<String, dynamic>) return KitchenItem.fromJson(e);
      if (e is Map) return KitchenItem.fromJson(Map<String, dynamic>.from(e));
      throw const FormatException('Invalid item');
    });
    if (parsedItems.isEmpty) {
      parsedItems = json.getList<KitchenItem>('order_items', (e) {
        if (e is Map<String, dynamic>) return KitchenItem.fromJson(e);
        if (e is Map) return KitchenItem.fromJson(Map<String, dynamic>.from(e));
        throw const FormatException('Invalid item');
      });
    }
    if (parsedItems.isEmpty) {
      parsedItems = json.getList<KitchenItem>('line_items', (e) {
        if (e is Map<String, dynamic>) return KitchenItem.fromJson(e);
        if (e is Map) return KitchenItem.fromJson(Map<String, dynamic>.from(e));
        throw const FormatException('Invalid item');
      });
    }
    if (parsedItems.isEmpty) {
      parsedItems = json.getList<KitchenItem>('order_lines', (e) {
        if (e is Map<String, dynamic>) return KitchenItem.fromJson(e);
        if (e is Map) return KitchenItem.fromJson(Map<String, dynamic>.from(e));
        throw const FormatException('Invalid item');
      });
    }
    if (parsedItems.isEmpty) {
      parsedItems = json.getList<KitchenItem>('lines', (e) {
        if (e is Map<String, dynamic>) return KitchenItem.fromJson(e);
        if (e is Map) return KitchenItem.fromJson(Map<String, dynamic>.from(e));
        throw const FormatException('Invalid item');
      });
    }
    if (parsedItems.isEmpty) {
      parsedItems = json.getList<KitchenItem>('details', (e) {
        if (e is Map<String, dynamic>) return KitchenItem.fromJson(e);
        if (e is Map) return KitchenItem.fromJson(Map<String, dynamic>.from(e));
        throw const FormatException('Invalid item');
      });
    }
    if (parsedItems.isEmpty) {
      parsedItems = json.getList<KitchenItem>('order_details', (e) {
        if (e is Map<String, dynamic>) return KitchenItem.fromJson(e);
        if (e is Map) return KitchenItem.fromJson(Map<String, dynamic>.from(e));
        throw const FormatException('Invalid item');
      });
    }

    final lowerStatus = effectiveStatus.toLowerCase().trim();
    final stage = switch (lowerStatus) {
      'preparing' || 'in_progress' || 'cooking' || 'brewing' || 'process' || 'processing' => KitchenStage.preparing,
      'ready' || 'served' || 'done' => KitchenStage.ready,
      _ => KitchenStage.fresh,
    };

    return KitchenOrder(
      id: json.getString('id'),
      number: json.getString('order_number', fallback: '#${json.getString('id')}'),
      tableLabel: tableNum.isNotEmpty ? tableNum : 'Walk-In',
      stage: stage,
      createdAt: DateTime.tryParse(json.getString('created_at'))?.toLocal() ?? DateTime.now(),
      items: parsedItems,
      status: rawOrderStatus.isEmpty ? null : rawOrderStatus,
      paymentStatus: rawPaymentStatus.isEmpty ? null : rawPaymentStatus,
      kitchenStatus: rawKitchenStatus.isEmpty ? null : rawKitchenStatus,
      customerName: customer.isEmpty ? null : sanitizeDisplayName(customer),
      notes: notes.isEmpty ? null : notes,
      totalAmount: json.getNum('total_amount', fallback: json.getNum('grand_total', fallback: json.getNum('total', fallback: 0))),
      orderType: rawType,
      serverName: server.isEmpty ? null : sanitizeDisplayName(server),
    );
  }
}

class KitchenService {
  static final KitchenService instance = KitchenService._();
  KitchenService._();

  final Map<String, KitchenOrder> _localHeldOrders = {};
  final Set<String> _paidOrderIds = {};

  /// Menyimpan pesanan hold ke memori lokal kasir agar seketika muncul di antrean
  void registerLocalHeldOrder(KitchenOrder order) {
    _localHeldOrders[order.id] = order;
  }

  /// Menghapus pesanan hold setelah berhasil dibayar atau dibatalkan
  void removeHeldOrder(String orderId) {
    _localHeldOrders.remove(orderId);
  }

  /// Menandai pesanan telah lunas agar tidak muncul kembali di Open Bills kasir
  void markOrderPaid(String? orderId) {
    if (orderId == null || orderId.trim().isEmpty) return;
    final clean = orderId.trim().replaceFirst(RegExp(r'^#'), '');
    _localHeldOrders.remove(orderId);
    _localHeldOrders.remove(clean);
    _paidOrderIds.add(orderId.trim());
    _paidOrderIds.add(clean);
  }

  /// Memeriksa apakah pesanan sudah ditandai lunas pada sesi kasir ini
  bool isOrderPaid(String? orderId) {
    if (orderId == null || orderId.trim().isEmpty) return false;
    final clean = orderId.trim().replaceFirst(RegExp(r'^#'), '');
    return _paidOrderIds.contains(orderId.trim()) || _paidOrderIds.contains(clean);
  }

  /// Ekstraksi list order dari berbagai bentuk payload JSON backend
  static List<dynamic> _extractOrdersList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;
    if (raw is Map) {
      final inner = raw['data'];
      if (inner is List) return inner;
      if (inner is Map) {
        if (inner['orders'] is List) return inner['orders'] as List;
        if (inner['data'] is List) return inner['data'] as List;
        if (inner['items'] is List) return inner['items'] as List;
      }
      if (raw['orders'] is List) return raw['orders'] as List;
      if (raw['items'] is List) return raw['items'] as List;
    }
    return const [];
  }

  Future<List<KitchenOrder>> load() async {
    try {
      final id = SessionStorage.instance.getLocationId();
      final locInt = int.tryParse(id ?? '');
      final locationQuery = {
        if (id != null && id.isNotEmpty) 'location_id': locInt ?? id,
      };

      dynamic raw;

      // 1. Prioritas Utama: Endpoint KDS dapur Cafe resmi (persis seperti versi Web)
      // /v1/cafe/kitchen/orders dan /cafe/kitchen/orders
      final primaryKitchenEndpoints = [
        '/v1/cafe/kitchen/orders',
        '/cafe/kitchen/orders',
      ];

      for (final endpoint in primaryKitchenEndpoints) {
        // Coba dengan location_id
        try {
          final res = await ApiClient.instance.dio.get(endpoint, queryParameters: locationQuery);
          if (res.statusCode == 200 && res.data != null) {
            final list = _extractOrdersList(res.data);
            if (list.isNotEmpty) {
              raw = res.data;
              debugPrint('🍳 [KDS LOAD] Berhasil memuat ${list.length} tiket dari $endpoint (dengan location_id)');
              break;
            }
          }
        } catch (_) {}

        // Jika kosong dengan location_id, coba tanpa location_id (persis seperti web KDS saat multi-outlet)
        if (locationQuery.isNotEmpty) {
          try {
            final res = await ApiClient.instance.dio.get(endpoint);
            if (res.statusCode == 200 && res.data != null) {
              final list = _extractOrdersList(res.data);
              if (list.isNotEmpty) {
                raw = res.data;
                debugPrint('🍳 [KDS LOAD] Berhasil memuat ${list.length} tiket dari $endpoint (tanpa location_id)');
                break;
              }
            }
          } catch (_) {}
        }
      }

      // 2. Fallback: Endpoint order POS aktif (mencakup status paid, confirmed, open, held, dll.)
      if (raw == null || _extractOrdersList(raw).isEmpty) {
        final posEndpoints = [
          '/v1/pos/orders',
          '/cafe/pos/orders',
        ];

        final posQueryWithStatus = {
          ...locationQuery,
          'status': 'paid,confirmed,open,held,preparing,ready,in_progress,cooking,pending,process',
        };

        for (final endpoint in posEndpoints) {
          try {
            final res = await ApiClient.instance.dio.get(endpoint, queryParameters: posQueryWithStatus);
            if (res.statusCode == 200 && res.data != null) {
              final list = _extractOrdersList(res.data);
              if (list.isNotEmpty) {
                raw = res.data;
                debugPrint('🍳 [KDS LOAD] Berhasil fallback memuat ${list.length} pesanan dari $endpoint');
                break;
              }
            }
          } catch (_) {}
        }
      }

      final listData = _extractOrdersList(raw);

      final serverOrders = listData
          .map((e) {
            if (e is Map<String, dynamic>) return KitchenOrder.fromJson(e);
            if (e is Map) return KitchenOrder.fromJson(Map<String, dynamic>.from(e));
            return null;
          })
          .whereType<KitchenOrder>()
          .where((o) => o.items.isNotEmpty)
          .where((o) {
            final ks = (o.kitchenStatus ?? '').toLowerCase().trim();
            final s = (o.status ?? '').toLowerCase().trim();

            // Saring HANYA pesanan yang benar-benar sudah diselesaikan/disajikan atau dibatalkan.
            // Pesanan 'paid' (lunas di kasir) TETAP DITAMPILKAN agar koki/barista memasaknya!
            if (ks == 'served' || ks == 'dismissed' || ks == 'cancelled' || ks == 'void') {
              return false;
            }
            if (s == 'cancelled' || s == 'void' || s == 'refunded' || s == 'served' || s == 'dismissed') {
              return false;
            }
            return true;
          })
          .toList();

      // Gabungkan dengan tiket hold lokal kasir bila belum ada di list server
      final combined = List<KitchenOrder>.from(serverOrders);
      for (final local in _localHeldOrders.values) {
        if (!combined.any((o) => o.id == local.id || o.number == local.number)) {
          combined.insert(0, local);
        }
      }

      return combined;
    } catch (e) {
      if (_localHeldOrders.isNotEmpty) {
        return _localHeldOrders.values.toList();
      }
      throw ApiException.from(e);
    }
  }

  /// Eksekusi multi-tier yang tahan banting untuk memperbarui status pesanan dapur
  Future<void> _updateStatus({
    required String orderId,
    required String nextStatus,
    required String action,
  }) async {
    final id = SessionStorage.instance.getLocationId();
    final locInt = int.tryParse(id ?? '');
    final query = {if (id != null && id.isNotEmpty) 'location_id': locInt ?? id};
    final body = {
      'status': nextStatus,
      if (id != null && id.isNotEmpty) 'location_id': locInt ?? id,
    };

    final attempts = [
      // 1. Route Action v1
      () => ApiClient.instance.dio.post('/v1/pos/orders/$orderId/$action', queryParameters: query),
      // 2. Status payload v1
      () => ApiClient.instance.dio.post('/v1/pos/orders/$orderId/status', queryParameters: query, data: body),
      // 3. Patch v1
      () => ApiClient.instance.dio.patch('/v1/pos/orders/$orderId/status', queryParameters: query, data: body),
      // 4. Cafe Kitchen Action v1
      () => ApiClient.instance.dio.post('/v1/cafe/kitchen/orders/$orderId/$action', queryParameters: query),
      // 5. Cafe Kitchen Status v1
      () => ApiClient.instance.dio.post('/v1/cafe/kitchen/orders/$orderId/status', queryParameters: query, data: body),
      // 6. Legacy Cafe Kitchen Action
      () => ApiClient.instance.dio.post('/cafe/kitchen/orders/$orderId/$action', queryParameters: query),
      // 7. Legacy Cafe Kitchen Status
      () => ApiClient.instance.dio.post('/cafe/kitchen/orders/$orderId/status', queryParameters: query, data: body),
      // 8. Legacy Cafe POS Status
      () => ApiClient.instance.dio.post('/cafe/pos/orders/$orderId/status', queryParameters: query, data: body),
    ];

    Object? lastError;
    for (final attempt in attempts) {
      try {
        await attempt();
        return;
      } catch (e) {
        lastError = e;
        // Hanya lanjut ke fallback endpoint jika route belum ditemukan (404 / 405).
        // Jangan menembak ulang ke 7 endpoint lain jika terjadi timeout / 500 / 422!
        final statusCode = e is DioException ? e.response?.statusCode : null;
        if (statusCode != 404 && statusCode != 405) {
          break;
        }
      }
    }

    if (lastError != null) {
      throw ApiException.from(lastError);
    }
  }

  Future<void> start(String orderId) => _updateStatus(orderId: orderId, nextStatus: 'preparing', action: 'prepare');
  Future<void> markReady(String orderId) => _updateStatus(orderId: orderId, nextStatus: 'ready', action: 'ready');
  Future<void> markServed(String orderId) => _updateStatus(orderId: orderId, nextStatus: 'served', action: 'served');

  /// Mengembalikan tiket ke tahap sebelumnya (misal dari Ready kembali ke Preparing)
  Future<void> revert(KitchenOrder order) {
    if (order.stage == KitchenStage.ready) {
      return _updateStatus(orderId: order.id, nextStatus: 'preparing', action: 'prepare');
    } else {
      return _updateStatus(orderId: order.id, nextStatus: 'open', action: 'reset');
    }
  }

  /// Menandai item pesanan individual selesai/belum selesai
  Future<void> toggleItemDone(String orderId, String itemId, {bool isDone = true}) async {
    final id = SessionStorage.instance.getLocationId();
    final locInt = int.tryParse(id ?? '');
    final query = {if (id != null && id.isNotEmpty) 'location_id': locInt ?? id};
    final body = {
      'status': isDone ? 'done' : 'pending',
      'done': isDone,
      if (id != null && id.isNotEmpty) 'location_id': locInt ?? id,
    };

    final attempts = [
      () => ApiClient.instance.dio.post('/v1/pos/orders/$orderId/items/$itemId/done', queryParameters: query, data: body),
      () => ApiClient.instance.dio.post('/v1/pos/orders/$orderId/items/$itemId/toggle', queryParameters: query, data: body),
      () => ApiClient.instance.dio.post('/v1/cafe/kitchen/orders/$orderId/items/$itemId/done', queryParameters: query, data: body),
      () => ApiClient.instance.dio.post('/cafe/kitchen/orders/$orderId/items/$itemId/done', queryParameters: query, data: body),
      () => ApiClient.instance.dio.patch('/v1/pos/orders/$orderId/items/$itemId', queryParameters: query, data: body),
    ];

    for (final attempt in attempts) {
      try {
        await attempt();
        return;
      } catch (e) {
        final statusCode = e is DioException ? e.response?.statusCode : null;
        if (statusCode != 404 && statusCode != 405) {
          break;
        }
      }
    }
  }

  Future<void> cancelOrder(String orderId, {String? reason}) async {
    removeHeldOrder(orderId);
    try {
      final id = SessionStorage.instance.getLocationId();
      final locInt = int.tryParse(id ?? '');
      final query = {if (id != null && id.isNotEmpty) 'location_id': locInt ?? id};
      final data = {'reason': reason ?? 'Dibatalkan oleh kasir/dapur'};

      final attempts = [
        () => ApiClient.instance.dio.post('/v1/pos/orders/$orderId/void', queryParameters: query, data: data),
        () => ApiClient.instance.dio.post('/v1/pos/orders/$orderId/cancel', queryParameters: query, data: data),
        () => ApiClient.instance.dio.post('/v1/cafe/kitchen/orders/$orderId/cancel', queryParameters: query, data: data),
        () => ApiClient.instance.dio.post('/cafe/pos/orders/$orderId/cancel', queryParameters: query, data: data),
        () => ApiClient.instance.dio.post('/cafe/kitchen/orders/$orderId/cancel', queryParameters: query, data: data),
      ];

      Object? lastError;
      for (final attempt in attempts) {
        try {
          await attempt();
          return;
        } catch (e) {
          lastError = e;
          final statusCode = e is DioException ? e.response?.statusCode : null;
          if (statusCode != 404 && statusCode != 405) {
            break;
          }
        }
      }

      if (lastError != null) {
        throw ApiException.from(lastError);
      }
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}
