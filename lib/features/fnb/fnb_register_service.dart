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
  });

  final String productId;
  final String name;

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
      'location_id': locId,
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
      final data = body is Map<String, dynamic> ? body['data'] : null;
      if (data is Map) {
        final orderObj = data['order'] is Map ? data['order'] as Map : data;
        return (orderObj['id'] ?? orderObj['order_number'] ?? orderObj['number'] ?? '').toString();
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
      'location_id': locId,
      if (orderId != null && orderId.isNotEmpty) 'order_id': int.tryParse(orderId) ?? orderId,
      if (tableId != null) 'table_id': int.tryParse(tableId) ?? tableId,
      'table_number': ?tableId,
      if (customerName != null && customerName.isNotEmpty) 'customer_name': customerName,
      'payment_method': method,
      'total_amount': bill.total,
      'grand_total': bill.total,
      'subtotal': bill.subtotal,
      'discount_total': bill.discount,
      if (voucherCode != null && voucherCode.isNotEmpty) 'voucher_code': voucherCode,
      'tax_total': bill.tax,
      'rounding_amount': bill.rounding,
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
          // Fallback: Endpoint domain cafe
          res = await ApiClient.instance.dio.post('/cafe/pos/checkout', data: payload);
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
      final data = body is Map ? body['data'] : null;
      final order = data is Map ? (data['order'] is Map ? data['order'] as Map : data) : const {};
      final invoice = (order['order_number'] ?? order['invoice_number'] ?? order['id'] ?? 'INV-$clientTxId').toString();
      return CheckoutOutcome(invoice: invoice, change: change);
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}

