import 'package:dio/dio.dart';
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
  final String? customerName;
  final String? notes;
  final num? totalAmount;
  final String orderType;
  final String? serverName;

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
        customerName: customerName ?? this.customerName,
        notes: notes ?? this.notes,
        totalAmount: totalAmount,
        orderType: orderType,
        serverName: serverName,
      );

  factory KitchenOrder.fromJson(Map<String, dynamic> json) {
    final status = json.getString('status', fallback: json.getString('order_status'));

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
      parsedItems = json.getList<KitchenItem>('details', (e) {
        if (e is Map<String, dynamic>) return KitchenItem.fromJson(e);
        if (e is Map) return KitchenItem.fromJson(Map<String, dynamic>.from(e));
        throw const FormatException('Invalid item');
      });
    }

    final lowerStatus = status.toLowerCase();
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
      status: status.isEmpty ? null : status,
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

  /// Menyimpan pesanan hold ke memori lokal kasir agar seketika muncul di antrean
  void registerLocalHeldOrder(KitchenOrder order) {
    _localHeldOrders[order.id] = order;
  }

  /// Menghapus pesanan hold setelah berhasil dibayar atau dibatalkan
  void removeHeldOrder(String orderId) {
    _localHeldOrders.remove(orderId);
  }

  Future<List<KitchenOrder>> load() async {
    try {
      final id = SessionStorage.instance.getLocationId();
      final locInt = int.tryParse(id ?? '');
      final query = {
        if (id != null && id.isNotEmpty) 'location_id': locInt ?? id,
        'status': 'open,held,preparing,ready,in_progress,cooking',
      };

      dynamic raw;
      final endpoints = [
        '/v1/pos/orders',
        '/v1/cafe/kitchen/orders',
        '/cafe/kitchen/orders',
        '/cafe/pos/orders',
      ];

      for (final endpoint in endpoints) {
        try {
          final res = await ApiClient.instance.dio.get(endpoint, queryParameters: query);
          if (res.statusCode == 200 && res.data != null) {
            raw = res.data;
            break;
          }
        } on DioException catch (e) {
          if (e.response?.statusCode != 404 && e.response?.statusCode != 405) {
            // Lanjutkan ke endpoint berikutnya
          }
        } catch (_) {}
      }

      if (raw == null) {
        // Fallback coba ambil tanpa filter status spesifik jika server strict
        try {
          final res = await ApiClient.instance.dio.get('/v1/pos/orders', queryParameters: {
            if (id != null && id.isNotEmpty) 'location_id': locInt ?? id,
          });
          raw = res.data;
        } catch (_) {}
      }

      List<dynamic> listData = const [];
      if (raw is List) {
        listData = raw;
      } else if (raw is Map) {
        final inner = raw['data'];
        if (inner is List) {
          listData = inner;
        } else if (inner is Map) {
          final orders = inner['orders'];
          final data = inner['data'];
          if (orders is List) {
            listData = orders;
          } else if (data is List) {
            listData = data;
          }
        } else {
          final rawOrders = raw['orders'];
          if (rawOrders is List) {
            listData = rawOrders;
          }
        }
      }

      final serverOrders = listData
          .map((e) {
            if (e is Map<String, dynamic>) return KitchenOrder.fromJson(e);
            if (e is Map) return KitchenOrder.fromJson(Map<String, dynamic>.from(e));
            return null;
          })
          .whereType<KitchenOrder>()
          .where((o) => o.items.isNotEmpty)
          .where((o) {
            final s = (o.status ?? '').toLowerCase().trim();
            // Abaikan pesanan yang sudah lunas/selesai/void dari daftar antrean aktif
            return s != 'paid' && s != 'completed' && s != 'settled' && s != 'closed' && s != 'void' && s != 'cancelled';
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
      } catch (_) {}
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
