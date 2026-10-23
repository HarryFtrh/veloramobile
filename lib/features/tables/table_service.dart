// features/tables/table_service.dart
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/safe_json.dart';

enum TableStatus { available, ordered, occupied, reserved }

class TableReservationInfo {
  const TableReservationInfo({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.time,
    required this.pax,
    required this.status,
  });

  final String id;
  final String customerName;
  final String phone;
  final String time;
  final int pax;
  final String status;

  factory TableReservationInfo.fromJson(Map<String, dynamic> json) =>
      TableReservationInfo(
        id: json.getString('id'),
        customerName: json.getString('customer_name', fallback: '-'),
        phone: json.getString('customer_phone'),
        time: json.getString('reservation_time'),
        pax: json.getInt('pax', fallback: 1),
        status: json.getString('status'),
      );
}

class TableOrderInfo {
  const TableOrderInfo({
    required this.id,
    required this.total,
    required this.itemCount,
    required this.createdAt,
    this.customerName,
  });

  final String id;
  final double total;
  final int itemCount;
  final DateTime createdAt;
  final String? customerName;

  factory TableOrderInfo.fromJson(Map<String, dynamic> json) {
    final name = json.getString('customer_name');
    return TableOrderInfo(
      id: json.getString('id'),
      total: json.getDouble('total_amount'),
      itemCount: json.getInt('items_count'),
      createdAt:
          DateTime.tryParse(json.getString('created_at'))?.toLocal() ??
          DateTime.now(),
      customerName: name.isEmpty ? null : name,
    );
  }
}

class CafeTableInfo {
  const CafeTableInfo({
    required this.id,
    required this.name,
    required this.capacity,
    required this.status,
    required this.isActive,
    this.order,
    this.reservation,
  });

  final String id;
  final String name;
  final int capacity;
  final TableStatus status;
  final bool isActive;
  final TableOrderInfo? order;
  final TableReservationInfo? reservation;

  factory CafeTableInfo.fromJson(Map<String, dynamic> json) {
    final order = json.getMap('active_order');
    final reservation = json.getMap('active_reservation');
    return CafeTableInfo(
      id: json.getString('id'),
      name: json.getString(
        'name',
        fallback: json.getString('table_number', fallback: '-'),
      ),
      capacity: json.getInt('capacity'),
      status: switch (json.getString('status')) {
        'ordered' => TableStatus.ordered,
        'occupied' => TableStatus.occupied,
        'reserved' => TableStatus.reserved,
        _ => TableStatus.available,
      },
      isActive: json.getBool('is_active', fallback: true),
      order: order.isEmpty ? null : TableOrderInfo.fromJson(order),
      reservation: reservation.isEmpty
          ? null
          : TableReservationInfo.fromJson(reservation),
    );
  }
}

class NewReservation {
  const NewReservation({
    required this.tableId,
    required this.customerName,
    required this.phone,
    required this.guests,
    required this.date,
    required this.time,
    this.notes,
  });

  final String tableId;
  final String customerName;
  final String phone;
  final int guests;
  final DateTime date;
  final String time;
  final String? notes;
}

class TableService {
  static final TableService instance = TableService._();
  TableService._();

  Map<String, dynamic> get _loc {
    final id = SessionStorage.instance.getLocationId();
    return {if (id != null && id.isNotEmpty) 'location_id': id};
  }

  Future<List<CafeTableInfo>> tables() async {
    try {
      final res = await ApiClient.instance.dio.get('/cafe/tables', queryParameters: _loc);
      final body = res.data;

      final raw = body is Map ? (body['data'] ?? body['tables'] ?? body) : body;
      List listData = const [];
      if (raw is List) {
        listData = raw;
      } else if (raw is Map) {
        if (raw['data'] is List) {
          listData = raw['data'] as List;
        } else if (raw['tables'] is List) {
          listData = raw['tables'] as List;
        }
      }

      final list = <CafeTableInfo>[];
      for (final e in listData) {
        if (e is Map<String, dynamic>) {
          list.add(CafeTableInfo.fromJson(e));
        } else if (e is Map) {
          list.add(CafeTableInfo.fromJson(Map<String, dynamic>.from(e)));
        }
      }

      return list..removeWhere((t) => !t.isActive);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Membuat meja baru
  Future<CafeTableInfo?> createTable({
    required String name,
    required int capacity,
    String? position,
  }) async {
    try {
      final payload = {
        ..._loc,
        'name': name,
        'capacity': capacity,
        'position': ?position,
      };
      final res = await ApiClient.instance.dio.post('/cafe/tables', data: payload);
      final body = res.data;
      final raw = body is Map ? (body['data'] ?? body) : body;
      if (raw is Map) {
        return CafeTableInfo.fromJson(Map<String, dynamic>.from(raw));
      }
      return null;
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Otomatis membuatkan meja standar (Meja 01 s/d 08) jika belum ada meja sama sekali
  Future<List<CafeTableInfo>> seedDefaultTables() async {
    final created = <CafeTableInfo>[];
    for (int i = 1; i <= 8; i++) {
      try {
        final t = await createTable(
          name: 'Meja 0$i',
          capacity: i % 2 == 0 ? 4 : 2,
          position: i <= 6 ? 'indoor' : 'outdoor',
        );
        if (t != null) created.add(t);
      } catch (_) {}
    }
    return created;
  }

  Future<void> release(String tableId) async {
    try {
      await ApiClient.instance.dio.post('/cafe/tables/$tableId/release', queryParameters: _loc);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> reserve(NewReservation r) async {
    try {
      final d = r.date;
      final payload = {
        ..._loc,
        'table_id': r.tableId,
        'customer_name': r.customerName,
        'customer_phone': r.phone,
        'guest_count': r.guests,
        'reservation_date':
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
        'reservation_time': r.time,
        if (r.notes != null && r.notes!.trim().isNotEmpty)
          'notes': r.notes!.trim(),
      };
      await ApiClient.instance.dio.post('/cafe/reservations', data: payload);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> setReservationStatus(String reservationId, String status) async {
    try {
      await ApiClient.instance.dio.patch(
        '/cafe/reservations/$reservationId/status',
        data: {'status': status},
      );
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ActiveTableOrder?> getActiveOrder(String tableId) async {
    try {
      final res = await ApiClient.instance.dio.get('/cafe/tables/$tableId/active-order', queryParameters: _loc);
      final body = res.data;
      final raw = body is Map<String, dynamic> ? body['data'] : (body is Map ? body['data'] : null);
      if (raw is! Map) return null;
      return ActiveTableOrder.fromJson(Map<String, dynamic>.from(raw));
    } catch (e) {
      return null;
    }
  }
}

class ActiveTableItem {
  const ActiveTableItem({
    this._id,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.notes,
    this.modifiers = const [],
    this.modifierNames = const [],
  });

  final String? _id;
  String get id => _id ?? productId;
  final String productId;
  final String name;
  final num price;
  final int quantity;
  final String? notes;
  final List<dynamic> modifiers;
  final List<String> modifierNames;

  factory ActiveTableItem.fromJson(Map<String, dynamic> json) =>
      ActiveTableItem(
        id: json.getString('id').isNotEmpty
            ? json.getString('id')
            : json.getString('product_id'),
        productId: json.getString('product_id'),
        name: sanitizeDisplayName(json.getString('name', fallback: 'Item')),
        price: json.getDouble('price'),
        quantity: json.getInt('quantity', fallback: 1),
        notes: json.getString('notes').isEmpty ? null : json.getString('notes'),
        modifiers: json.getList<dynamic>('modifiers', (e) => e),
        modifierNames: json.getList<String>(
          'modifierNames',
          (e) => sanitizeDisplayName(e),
        ),
      );
}

class ActiveTableOrder {
  const ActiveTableOrder({
    required this.id,
    required this.customerName,
    required this.notes,
    required this.subtotal,
    required this.totalAmount,
    required this.isAlreadyPaid,
    required this.items,
  });

  final String id;
  final String customerName;
  final String notes;
  final num subtotal;
  final num totalAmount;
  final bool isAlreadyPaid;
  final List<ActiveTableItem> items;

  factory ActiveTableOrder.fromJson(Map<String, dynamic> json) =>
      ActiveTableOrder(
        id: json.getString('id'),
        customerName: sanitizeDisplayName(json.getString('customer_name')),
        notes: json.getString('notes'),
        subtotal: json.getDouble('subtotal'),
        totalAmount: json.getDouble('total_amount'),
        isAlreadyPaid: json.getBool('is_already_paid'),
        items: json.getList<ActiveTableItem>(
          'items',
          (e) => ActiveTableItem.fromJson(
            e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map),
          ),
        ),
      );
}
