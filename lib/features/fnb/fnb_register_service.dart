import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/session_storage.dart';
import 'billing.dart';
import 'modifiers.dart';

class RegisterLine {
  RegisterLine({
    required this.productId,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.note,
    this.options = const [],
    this.orderItemId,
  });

  final String productId;
  final String name;
  final String? orderItemId;

  /// Harga dasar produk, tanpa modifier.
  final num price;
  int quantity;
  String? note;
  final List<ModifierOption> options;

  /// Harga satu item termasuk tambahan modifier.
  num get unitPrice => price + options.fold<num>(0, (s, o) => s + o.price);
  num get subtotal => unitPrice * quantity;

  /// Kunci untuk menggabungkan baris yang identik (produk + modifier + catatan).
  String get mergeKey {
    final ids = options.map((o) => o.id).toList()..sort();
    return '$productId|${ids.join(',')}|${note ?? ''}';
  }

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
        'note': note,
        'order_item_id': orderItemId,
        'options': options.map((o) => o.toJson()).toList(),
      };

  factory RegisterLine.fromJson(Map<String, dynamic> json) => RegisterLine(
        productId: json['product_id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        price: json['price'] is num ? json['price'] as num : (num.tryParse(json['price']?.toString() ?? '') ?? 0),
        quantity: json['quantity'] is int ? json['quantity'] as int : (int.tryParse(json['quantity']?.toString() ?? '') ?? 1),
        note: json['note']?.toString(),
        orderItemId: json['order_item_id']?.toString(),
        options: (json['options'] is List)
            ? (json['options'] as List)
                .whereType<Map>()
                .map((m) => ModifierOption.fromJson(Map<String, dynamic>.from(m)))
                .toList()
            : const [],
      );

  Map<String, dynamic> toOrderJson() {
    final modIds = [for (final o in options) int.tryParse(o.id) ?? o.id];
    final modObjects = [
      for (final o in options)
        {
          'id': int.tryParse(o.id) ?? o.id,
          'modifier_option_id': int.tryParse(o.id) ?? o.id,
          'name': o.name,
          'price': o.price,
        }
    ];
    final modNames = [for (final o in options) o.name];

    return {
      'product_id': int.tryParse(productId) ?? productId,
      'quantity': quantity,
      'qty': quantity,
      'name': name,
      'unit_price': unitPrice,
      'price': unitPrice,
      'subtotal': subtotal,
      if (note != null && note!.isNotEmpty) 'notes': note,
      if (note != null && note!.isNotEmpty) 'note': note,
      if (options.isNotEmpty) ...{
        'modifiers': modObjects,
        'modifier_ids': modIds,
        'modifier_names': modNames,
        'options': modObjects,
      },
    };
  }

  Map<String, dynamic> toCheckoutJson() => {
        ...toOrderJson(),
        if (orderItemId != null && orderItemId!.isNotEmpty) ...{
          'order_item_id': int.tryParse(orderItemId!) ?? orderItemId,
          'id': int.tryParse(orderItemId!) ?? orderItemId,
        },
        'unit_price': unitPrice,
        'price': unitPrice,
        'subtotal': subtotal,
      };
}

class CheckoutOutcome {
  const CheckoutOutcome({required this.invoice, required this.change});
  final String invoice;
  final num change;
}

/// Layanan terpadu POS F&B yang mendukung endpoint v1 (/v1/pos/*)
/// dengan fallback cerdas ke legacy (/cafe/pos/*) dan antrean offline (anti koneksi drop).
class FnbRegisterService {
  static final FnbRegisterService instance = FnbRegisterService._();
  FnbRegisterService._();

  static const _uuid = Uuid();

  String? get _locationId => SessionStorage.instance.getLocationId();

  Future<BillingSettings> billingSettings() => BillingSettings.fetch();

  /// Kirim pesanan ke dapur tanpa pembayaran atau simpan antrean (hold/open bill). Mengembalikan id/nomor pesanan.
  Future<String> sendToKitchen({
    required List<RegisterLine> lines,
    String? tableId,
    String? customerName,
    String? notes,
    String? orderId,
    bool isHold = false,
    String? orderType,
  }) async {
    final locId = _locationId ?? SessionStorage.instance.getLocationId();
    if (locId == null || locId.isEmpty) {
      throw ApiException.from('Cabang kasir belum dipilih. Silakan pilih cabang di pengaturan.');
    }

    final clientTxId = _uuid.v4();
    final payload = {
      'client_tx_id': clientTxId,
      'location_id': int.tryParse(locId) ?? locId,
      if (orderId != null && orderId.isNotEmpty) 'order_id': int.tryParse(orderId) ?? orderId,
      if (tableId != null && tableId.isNotEmpty) 'table_id': int.tryParse(tableId) ?? tableId,
      if (tableId != null && tableId.isNotEmpty) 'table_number': tableId,
      if (customerName != null && customerName.isNotEmpty) 'customer_name': customerName,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'status': isHold ? 'held' : 'open',
      'order_type': ?orderType,
      'items': [for (final l in lines) l.toOrderJson()],
    };

    try {
      Response res;
      try {
        // Prioritas 1: Canonical POS v1 Orders
        res = await ApiClient.instance.dio.post('/v1/pos/orders', data: payload);
      } catch (_) {
        try {
          // Fallback 1: Domain Cafe POS
          res = await ApiClient.instance.dio.post('/cafe/pos/orders', data: payload);
        } catch (_) {
          // Fallback 2: Domain KDS Kitchen
          res = await ApiClient.instance.dio.post('/cafe/kitchen/orders', data: payload);
        }
      }

      final body = res.data;
      if (body is Map) {
        final rawData = body['data'];
        final data = rawData is Map ? rawData : body;
        final rawOrder = data['order'];
        final orderObj = rawOrder is Map ? rawOrder : data;
        final orderId = (orderObj['id'] ?? orderObj['order_number'] ?? orderObj['number'] ?? '').toString();
        if (orderId.isNotEmpty) return orderId;
      }
      return '';
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Pembayaran transaksi kasir terpadu (v1 engine) dengan offline guard.
  Future<CheckoutOutcome> checkout({
    required List<RegisterLine> lines,
    required BillBreakdown bill,
    required String method,
    required num paid,
    String? orderId,
    String? tableId,
    String? customerName,
    String? shiftId,
    String? voucherCode,
  }) async {
    final locId = _locationId ?? SessionStorage.instance.getLocationId();
    if (locId == null || locId.isEmpty) {
      throw ApiException.from('Cabang kasir belum dipilih. Silakan pilih cabang di pengaturan.');
    }

    final clientTxId = _uuid.v4();
    final change = paid > bill.total ? paid - bill.total : 0;
    final payload = {
      'client_tx_id': clientTxId,
      'location_id': int.tryParse(locId) ?? locId,
      if (orderId != null && orderId.isNotEmpty) 'order_id': int.tryParse(orderId) ?? orderId,
      if (tableId != null && tableId.isNotEmpty) 'table_id': int.tryParse(tableId) ?? tableId,
      if (tableId != null && tableId.isNotEmpty) 'table_number': tableId,
      if (customerName != null && customerName.isNotEmpty) 'customer_name': customerName,
      'payment_method': method,
      'payment_details': [
        {
          'method': method,
          'payment_method': method,
          'amount': paid,
          'nominal': paid,
        }
      ],
      'payments': [
        {
          'method': method,
          'payment_method': method,
          'amount': paid,
          'nominal': paid,
        }
      ],
      'total_amount': bill.total,
      'grand_total': bill.total,
      'subtotal': bill.subtotal,
      'discount_total': bill.discount,
      'discount_amount': bill.discount,
      if (voucherCode != null && voucherCode.isNotEmpty) 'voucher_code': voucherCode,
      if (voucherCode != null && voucherCode.isNotEmpty) 'promo_code': voucherCode,
      'tax_total': bill.tax,
      'tax_amount': bill.tax,
      'rounding_amount': bill.rounding,
      'dp_amount': 0,
      'paid_amount': paid,
      'change_amount': change,
      if (shiftId != null && shiftId.isNotEmpty) 'shift_id': int.tryParse(shiftId) ?? shiftId,
      'items': [for (final l in lines) l.toCheckoutJson()],
    };

    try {
      Response res;
      try {
        // Prioritas 1: Canonical POS v1 Engine (/v1/pos/checkout-sale)
        res = await ApiClient.instance.dio.post('/v1/pos/checkout-sale', data: payload);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
          try {
            // Fallback 1: POS v1 Checkout (/v1/pos/checkout)
            res = await ApiClient.instance.dio.post('/v1/pos/checkout', data: payload);
          } catch (_) {
            // Fallback 2: Endpoint domain cafe (/cafe/pos/checkout)
            res = await ApiClient.instance.dio.post('/cafe/pos/checkout', data: payload);
          }
        } else if (e.type == DioExceptionType.connectionError ||
                   e.type == DioExceptionType.connectionTimeout) {
          // Offline Guard: Simpan transaksi lokal v1 bila internet mati
          final offlineInvoice = 'OFFLINE-${DateTime.now().millisecondsSinceEpoch}';
          final offlineRecord = {
            'offline_id': clientTxId,
            'offline_reference_id': clientTxId,
            ...payload,
            'created_at': DateTime.now().toIso8601String(),
          };
          await SessionStorage.instance.enqueueOfflineSale(jsonEncode(offlineRecord));
          return CheckoutOutcome(invoice: offlineInvoice, change: change);
        } else {
          rethrow;
        }
      }

      final body = res.data;
      Map<String, dynamic> data = {};
      if (body is Map) {
        final inner = body['data'] ?? body;
        data = inner is Map ? Map<String, dynamic>.from(inner) : Map<String, dynamic>.from(body);
      }
      final rawOrder = data['order'];
      final order = rawOrder is Map ? Map<String, dynamic>.from(rawOrder) : data;
      final invoice = (order['order_number'] ??
              order['invoice_number'] ??
              order['id'] ??
              (body is Map ? (body['invoice'] ?? body['invoice_number']) : null) ??
              'INV-$clientTxId')
          .toString();
      return CheckoutOutcome(invoice: invoice, change: change);
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}

