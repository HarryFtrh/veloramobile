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
        : json.getString('notes');

    String itemName = json.getString('name');
    if (itemName.isEmpty && json['product'] is Map) {
      itemName = json['product']['name']?.toString() ?? '';
    }
    if (itemName.isEmpty) {
      itemName = json.getString('product_name', fallback: '-');
    }

    final price = json.getNum('price', fallback: json.getNum('unit_price', fallback: 0));
    final qty = json.getInt('quantity', fallback: json.getInt('qty', fallback: 1));

    final rawModifiers = json['modifiers'] ??
        json['options'] ??
        json['item_modifiers'] ??
        json['selected_modifiers'];
    final List<String> modifierList = [];
    if (rawModifiers is List) {
      for (final m in rawModifiers) {
        if (m is String && m.trim().isNotEmpty) {
          modifierList.add(sanitizeDisplayName(m.trim()));
        } else if (m is num) {
          modifierList.add(m.toString());
        } else if (m is Map) {
          final modName = m['name'] ??
              m['option_name'] ??
              m['modifier_name'] ??
              m['label'] ??
              (m['option'] is Map ? m['option']['name'] : null);
          if (modName != null && modName.toString().trim().isNotEmpty) {
            modifierList.add(sanitizeDisplayName(modName.toString().trim()));
          }
          final modId = m['id'] ?? m['modifier_option_id'] ?? m['option_id'];
          if (modId != null) {
            modifierList.add(modId.toString());
          }
        }
      }
    }

    return KitchenItem(
      id: json.getString('id'),
      name: sanitizeDisplayName(itemName),
      station: sanitizeDisplayName(json.getString('category_name')),
      quantity: qty,
      done: json['done'] == true || json['status'] == 'done' || json['status'] == 'completed',
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

  bool get isHeld =>
      status == 'held' ||
      status == 'hold' ||
      tableLabel.toLowerCase().contains('hold');

  KitchenOrder copyWith({List<KitchenItem>? items, String? status}) => KitchenOrder(
        id: id,
        number: number,
        tableLabel: tableLabel,
        stage: stage,
        createdAt: createdAt,
        items: items ?? this.items,
        status: status ?? this.status,
        customerName: customerName,
        notes: notes,
        totalAmount: totalAmount,
      );

  factory KitchenOrder.fromJson(Map<String, dynamic> json) {
    final status = json.getString('status', fallback: json.getString('order_status'));
    final customer = json.getString('customer_name');
    final notes = json.getString('notes', fallback: json.getString('note'));
    final tableNum = json.getString('table_number', fallback: json.getString('table_id'));

    return KitchenOrder(
      id: json.getString('id'),
      number: json.getString('order_number', fallback: '#${json.getString('id')}'),
      tableLabel: tableNum.isNotEmpty ? tableNum : 'Walk-in',
      stage: switch (status.toLowerCase()) {
        'preparing' => KitchenStage.preparing,
        'ready' || 'served' => KitchenStage.ready,
        _ => KitchenStage.fresh,
      },
      createdAt: DateTime.tryParse(json.getString('created_at'))?.toLocal() ?? DateTime.now(),
      items: json.getList<KitchenItem>('items', (e) {
        if (e is Map<String, dynamic>) return KitchenItem.fromJson(e);
        if (e is Map) return KitchenItem.fromJson(Map<String, dynamic>.from(e));
        throw const FormatException('Invalid item');
      }),
      status: status.isEmpty ? null : status,
      customerName: customer.isEmpty ? null : sanitizeDisplayName(customer),
      notes: notes.isEmpty ? null : notes,
      totalAmount: json.getNum('total_amount', fallback: json.getNum('grand_total', fallback: json.getNum('total', fallback: 0))),
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
      final query = {
        if (id != null && id.isNotEmpty) 'location_id': id,
        'status': 'open,held,preparing,ready',
      };
      dynamic raw;
      try {
        // Prioritas 1: Canonical POS v1 Orders
        final res = await ApiClient.instance.dio.get('/v1/pos/orders', queryParameters: query);
        raw = res.data;
      } catch (_) {
        try {
          // Fallback 1: Endpoint Cafe POS Orders
          final res = await ApiClient.instance.dio.get('/cafe/pos/orders', queryParameters: query);
          raw = res.data;
        } catch (_) {
          try {
            // Fallback 2: Endpoint KDS Kitchen Cafe
            final res = await ApiClient.instance.dio.get('/cafe/kitchen/orders', queryParameters: query);
            raw = res.data;
          } catch (_) {}
        }
      }

      List<dynamic> listData = const [];
      if (raw is List) {
        listData = raw;
      } else if (raw is Map) {
        final inner = raw['data'];
        if (inner is List) {
          listData = inner;
        } else if (inner is Map) {
          if (inner['orders'] is List) {
            listData = inner['orders'] as List;
          } else if (inner['data'] is List) {
            listData = inner['data'] as List;
          }
        } else if (raw['orders'] is List) {
          listData = raw['orders'] as List;
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

  Future<void> _post(String path) async {
    try {
      final id = SessionStorage.instance.getLocationId();
      final query = {if (id != null && id.isNotEmpty) 'location_id': id};
      try {
        await ApiClient.instance.dio.post('/v1/pos/orders/$path', queryParameters: query);
      } catch (_) {
        await ApiClient.instance.dio.post('/cafe/kitchen/orders/$path', queryParameters: query);
      }
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> start(String orderId) => _post('$orderId/prepare');
  Future<void> markReady(String orderId) => _post('$orderId/ready');
  Future<void> markServed(String orderId) => _post('$orderId/served');
  Future<void> toggleItemDone(String orderId, String itemId) => _post('$orderId/items/$itemId/done');

  Future<void> cancelOrder(String orderId, {String? reason}) async {
    removeHeldOrder(orderId);
    try {
      final id = SessionStorage.instance.getLocationId();
      final query = {if (id != null && id.isNotEmpty) 'location_id': id};
      final data = {'reason': reason ?? 'Dibatalkan oleh kasir'};
      try {
        // Prioritas 1: Canonical POS v1 Void
        await ApiClient.instance.dio.post('/v1/pos/orders/$orderId/void', queryParameters: query, data: data);
      } catch (_) {
        try {
          await ApiClient.instance.dio.post('/v1/pos/orders/$orderId/cancel', queryParameters: query, data: data);
        } catch (_) {
          await ApiClient.instance.dio.post('/cafe/pos/orders/$orderId/cancel', queryParameters: query, data: data);
        }
      }
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}
