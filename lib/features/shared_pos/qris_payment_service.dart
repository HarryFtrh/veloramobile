import 'dart:async';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/safe_json.dart';

enum QrisPaymentStatus {
  pending,
  paid,
  expired,
  failed,
}

class QrisInvoiceData {
  final String transactionId;
  final String qrString;
  final num amount;
  final String? nmid;
  final DateTime? expiresAt;
  final QrisPaymentStatus status;

  QrisInvoiceData({
    required this.transactionId,
    required this.qrString,
    required this.amount,
    this.nmid,
    this.expiresAt,
    this.status = QrisPaymentStatus.pending,
  });

  bool get isPaid => status == QrisPaymentStatus.paid;

  factory QrisInvoiceData.fromJson(Map<String, dynamic> json, num fallbackAmount) {
    final statusStr = json.getString('status', fallback: 'pending').toLowerCase();
    QrisPaymentStatus parsedStatus = QrisPaymentStatus.pending;
    if (statusStr == 'paid' || statusStr == 'settlement' || statusStr == 'success') {
      parsedStatus = QrisPaymentStatus.paid;
    } else if (statusStr == 'expired') {
      parsedStatus = QrisPaymentStatus.expired;
    } else if (statusStr == 'failed' || statusStr == 'cancel') {
      parsedStatus = QrisPaymentStatus.failed;
    }

    return QrisInvoiceData(
      transactionId: json.getString('transaction_id', fallback: json.getString('id', fallback: 'QRIS-${DateTime.now().millisecondsSinceEpoch}')),
      qrString: json.getString('qr_string', fallback: json.getString('qr_content', fallback: json.getString('payload'))),
      amount: json.getDouble('amount', fallback: fallbackAmount.toDouble()),
      nmid: json.getString('nmid'),
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json.getString('expires_at')) : null,
      status: parsedStatus,
    );
  }
}

class QrisPaymentService {
  static final QrisPaymentService instance = QrisPaymentService._();
  QrisPaymentService._();

  /// Menghasilkan QRIS Dinamis dari backend pembayaran (Midtrans/Xendit/DOKU/Velora Gateway)
  Future<QrisInvoiceData> generateDynamicQris({
    required num amount,
    String? orderId,
    String? tableNumber,
  }) async {
    final locationId = SessionStorage.instance.getLocationId();
    final payload = {
      'amount': amount,
      if (orderId != null && orderId.isNotEmpty) 'order_id': orderId,
      if (tableNumber != null && tableNumber.isNotEmpty) 'table_number': tableNumber,
      if (locationId != null && locationId.isNotEmpty) 'location_id': locationId,
    };

    Response response;
    try {
      response = await ApiClient.instance.dio.post(
        '/v1/pos/payments/qris',
        data: payload,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        try {
          response = await ApiClient.instance.dio.post(
            '/cafe/pos/payments/qris',
            data: payload,
          );
        } on DioException catch (e2) {
          final errMsg = e2.response?.data is Map
              ? (e2.response?.data['message']?.toString())
              : null;
          throw Exception(errMsg ?? e2.message ?? 'Gagal menghubungi gateway QRIS');
        }
      } else {
        final errMsg = e.response?.data is Map
            ? (e.response?.data['message']?.toString())
            : null;
        throw Exception(errMsg ?? e.message ?? 'Gagal membuat tagihan QRIS');
      }
    }

    final body = response.data;
    final data = body is Map<String, dynamic>
        ? (body['data'] is Map<String, dynamic> ? body['data'] as Map<String, dynamic> : body)
        : <String, dynamic>{};

    final invoice = QrisInvoiceData.fromJson(data, amount);
    if (invoice.qrString.isEmpty && invoice.transactionId.isEmpty) {
      throw Exception('Server mengembalikan data QRIS kosong.');
    }
    return invoice;
  }

  /// Memeriksa status pelunasan transaksi QRIS secara langsung ke backend
  Future<QrisPaymentStatus> checkStatus(String transactionId) async {
    try {
      Response response;
      try {
        response = await ApiClient.instance.dio.get('/v1/pos/payments/qris/$transactionId/status');
      } on DioException catch (e) {
        if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
          response = await ApiClient.instance.dio.get('/cafe/pos/payments/qris/$transactionId');
        } else {
          rethrow;
        }
      }

      final body = response.data;
      final data = body is Map<String, dynamic>
          ? (body['data'] is Map<String, dynamic> ? body['data'] as Map<String, dynamic> : body)
          : <String, dynamic>{};

      final statusStr = data.getString('status').toLowerCase();
      if (statusStr == 'paid' || statusStr == 'settlement' || statusStr == 'success') {
        return QrisPaymentStatus.paid;
      } else if (statusStr == 'expired') {
        return QrisPaymentStatus.expired;
      } else if (statusStr == 'failed' || statusStr == 'cancel') {
        return QrisPaymentStatus.failed;
      }
      return QrisPaymentStatus.pending;
    } catch (_) {
      return QrisPaymentStatus.pending;
    }
  }

  /// Membatalkan transaksi QRIS yang sedang aktif
  Future<void> cancel(String transactionId) async {
    try {
      await ApiClient.instance.dio.post('/v1/pos/payments/qris/$transactionId/cancel');
    } catch (_) {}
  }
}
