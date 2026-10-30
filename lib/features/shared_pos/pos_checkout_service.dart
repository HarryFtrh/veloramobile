import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import 'offline_sync_manager.dart';

class PosCartItem {
  final String productId;
  final String name;
  final num price;
  final int quantity;
  final String? batchNumber;
  final String? expiryDate;
  final Map<String, dynamic>? modifiers;

  PosCartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.batchNumber,
    this.expiryDate,
    this.modifiers,
  });

  Map<String, dynamic> toJson() {
    final effectivePrice = price;
    final effectiveQty = quantity;
    final effectiveSubtotal = effectivePrice * effectiveQty;
    return {
      'product_id': int.tryParse(productId) ?? productId,
      'name': name,
      'price': effectivePrice,
      'unit_price': effectivePrice,
      'quantity': effectiveQty,
      'qty': effectiveQty,
      'subtotal': effectiveSubtotal,
      'batch_number': ?batchNumber,
      'expiry_date': ?expiryDate,
      'modifiers': ?modifiers,
    };
  }
}

class PosCheckoutResult {
  final bool success;
  final String invoiceNumber;
  final num totalAmount;
  final num paidAmount;
  final num changeAmount;
  final bool isOffline;
  final String? errorMessage;

  PosCheckoutResult({
    required this.success,
    required this.invoiceNumber,
    required this.totalAmount,
    required this.paidAmount,
    required this.changeAmount,
    this.isOffline = false,
    this.errorMessage,
  });
}

class PosCheckoutService {
  static final PosCheckoutService instance = PosCheckoutService._();
  PosCheckoutService._();

  final _uuid = const Uuid();

  int get pendingOfflineCount => SessionStorage.instance.getOfflineQueueCount();

  Future<PosCheckoutResult> checkout({
    required List<PosCartItem> items,
    required num totalAmount,
    required num paidAmount,
    required String paymentMethod, // 'cash', 'qris', 'debit', 'transfer'
    String? customerName,
    String? tableNumber,
    String? orderId,
    String? shiftId,
    num? subtotal,
    num? taxAmount,
    num? discountAmount,
    num? roundingAmount,
  }) async {
    final clientTxId = _uuid.v4();
    final locationId = SessionStorage.instance.getLocationId() ?? '';

    final payload = {
      'client_tx_id': clientTxId,
      'location_id': int.tryParse(locationId) ?? locationId,
      'payment_method': paymentMethod,
      'payment_details': [
        {
          'method': paymentMethod,
          'payment_method': paymentMethod,
          'amount': paidAmount,
          'nominal': paidAmount,
        }
      ],
      'payments': [
        {
          'method': paymentMethod,
          'payment_method': paymentMethod,
          'amount': paidAmount,
          'nominal': paidAmount,
        }
      ],
      'total_amount': totalAmount,
      'grand_total': totalAmount,
      'subtotal': subtotal ?? totalAmount,
      'tax_total': ?taxAmount,
      'tax_amount': ?taxAmount,
      'discount_total': ?discountAmount,
      'discount_amount': ?discountAmount,
      'rounding_amount': ?roundingAmount,
      'dp_amount': 0,
      'paid_amount': paidAmount,
      'change_amount': paidAmount >= totalAmount ? paidAmount - totalAmount : 0,
      'customer_name': ?customerName,
      'table_number': ?tableNumber,
      'table_id': ?tableNumber,
      if (orderId != null && orderId.isNotEmpty) 'order_id': int.tryParse(orderId) ?? orderId,
      if (shiftId != null && shiftId.isNotEmpty) 'shift_id': int.tryParse(shiftId) ?? shiftId,
      'items': items.map((e) => e.toJson()).toList(),
    };

    try {
      Response response;
      try {
        response = await ApiClient.instance.dio.post(
          '/v1/pos/checkout-sale',
          data: payload,
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
          response = await ApiClient.instance.dio.post(
            '/cafe/pos/checkout',
            data: payload,
          );
        } else {
          rethrow;
        }
      }

      final body = response.data;
      Map<String, dynamic> data = {};
      if (body is Map) {
        final inner = body['data'] ?? body;
        data = inner is Map ? Map<String, dynamic>.from(inner) : Map<String, dynamic>.from(body);
      }
      final rawOrder = data['order'];
      final order = rawOrder is Map ? Map<String, dynamic>.from(rawOrder) : data;
      final invoiceNum = (order['invoice_number'] ??
              order['order_number'] ??
              order['id'] ??
              (body is Map ? (body['invoice'] ?? body['invoice_number']) : null) ??
              'INV-$clientTxId')
          .toString();

      return PosCheckoutResult(
        success: true,
        invoiceNumber: invoiceNum,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        changeAmount: paidAmount >= totalAmount ? paidAmount - totalAmount : 0,
        isOffline: false,
      );
    } on DioException catch (e) {
      // Offline fallback: save locally if internet drops!
      final offlineInvoice = 'OFFLINE-${DateTime.now().millisecondsSinceEpoch}';
      
      final offlineRecord = {
        'offline_id': clientTxId,
        'offline_reference_id': clientTxId,
        'location_id': locationId,
        'payment_method': paymentMethod,
        'grand_total': totalAmount,
        'subtotal': subtotal ?? totalAmount,
        'tax_total': ?taxAmount,
        'discount_total': ?discountAmount,
        'paid_amount': paidAmount,
        'change_amount': paidAmount >= totalAmount ? paidAmount - totalAmount : 0,
        'customer_name': customerName ?? 'Pelanggan Walk-In',
        'notes': tableNumber != null ? 'Meja: $tableNumber' : null,
        'order_id': ?orderId,
        'shift_id': ?shiftId,
        'items': items.map((e) => {
          'product_id': e.productId,
          'qty': e.quantity,
          'quantity': e.quantity,
          'unit_price': e.price,
          'price': e.price,
          'batch_number': ?e.batchNumber,
          'expiry_date': ?e.expiryDate,
          'modifiers': ?e.modifiers,
        }).toList(),
        'created_at': DateTime.now().toIso8601String(),
      };

      await OfflineSyncManager.instance.enqueueAndSync(offlineRecord);

      return PosCheckoutResult(
        success: true,
        invoiceNumber: offlineInvoice,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        changeAmount: paidAmount >= totalAmount ? paidAmount - totalAmount : 0,
        isOffline: true,
        errorMessage: 'Disimpan di antrean offline: ${e.message}',
      );
    }
  }

  bool get _isSyncing => false;

  /// Sync all pending offline transactions to Canonical POS Offline Batch API via unified OfflineSyncManager
  Future<Map<String, dynamic>> syncOfflineQueue() async {
    return await OfflineSyncManager.instance.triggerSyncDetailed();
  }
}
