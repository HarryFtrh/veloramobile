import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';

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
    return {
      'product_id': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
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
      'location_id': locationId,
      'payment_method': paymentMethod,
      'total_amount': totalAmount,
      'grand_total': totalAmount,
      'subtotal': subtotal ?? totalAmount,
      'tax_total': ?taxAmount,
      'discount_total': ?discountAmount,
      'rounding_amount': ?roundingAmount,
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
      final data = body is Map<String, dynamic> ? (body['data'] is Map<String, dynamic> ? body['data'] as Map<String, dynamic> : body) : <String, dynamic>{};
      final order = data['order'] is Map<String, dynamic> ? data['order'] as Map<String, dynamic> : data;
      final invoiceNum = (order['invoice_number'] ?? order['order_number'] ?? order['id'] ?? 'INV-$clientTxId').toString();

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

      await SessionStorage.instance.enqueueOfflineSale(jsonEncode(offlineRecord));

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

  bool _isSyncing = false;

  /// Sync all pending offline transactions to Canonical POS Offline Batch API
  Future<Map<String, dynamic>> syncOfflineQueue() async {
    if (_isSyncing) {
      return {'synced': 0, 'failed': 0, 'remaining': pendingOfflineCount};
    }
    _isSyncing = true;

    final queueRaw = SessionStorage.instance.getOfflineQueue();
    if (queueRaw.isEmpty) {
      _isSyncing = false;
      return {'synced': 0, 'failed': 0, 'remaining': 0};
    }

    final transactions = <Map<String, dynamic>>[];
    for (final raw in queueRaw) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          transactions.add(decoded);
        }
      } catch (_) {
        // Skip corrupt entry
      }
    }

    if (transactions.isEmpty) {
      await SessionStorage.instance.clearOfflineQueue();
      _isSyncing = false;
      return {'synced': 0, 'failed': 0, 'remaining': 0};
    }

    try {
      final response = await ApiClient.instance.dio.post(
        '/v1/pos/offline-batch-sync',
        data: {
          'location_id': SessionStorage.instance.getLocationId(),
          'transactions': transactions,
        },
      );

      Map<String, dynamic> data = {};
      if (response.data is Map) {
        final rawData = response.data['data'];
        if (rawData is Map) {
          data = Map<String, dynamic>.from(rawData);
        } else {
          data = Map<String, dynamic>.from(response.data);
        }
      }
      final syncedCount = (data['synced_count'] as num?)?.toInt() ?? transactions.length;

      // Clear queue on batch sync
      await SessionStorage.instance.clearOfflineQueue();

      // If server returned failed records, re-enqueue them
      final failedRaw = data['failed'];
      final failedList = failedRaw is List ? failedRaw : null;
      if (failedList != null && failedList.isNotEmpty) {
        for (final item in failedList) {
          if (item is Map) {
            await SessionStorage.instance.enqueueOfflineSale(jsonEncode(item));
          }
        }
      }

      return {
        'synced': syncedCount,
        'failed': failedList?.length ?? 0,
        'remaining': SessionStorage.instance.getOfflineQueueCount(),
      };
    } catch (e) {
      return {
        'synced': 0,
        'failed': transactions.length,
        'remaining': transactions.length,
        'error': e.toString(),
      };
    } finally {
      _isSyncing = false;
    }
  }
}
