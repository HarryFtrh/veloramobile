import 'package:dio/dio.dart';

/// Error terstruktur untuk lapisan service, supaya UI bisa menampilkan
/// pesan yang jelas dan tidak perlu menelan exception.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// Ubah error apa pun (terutama [DioException]) menjadi [ApiException].
  factory ApiException.from(Object error) {
    if (error is ApiException) return error;

    if (error is DioException) {
      final status = error.response?.statusCode;
      final body = error.response?.data;
      String? serverMessage;

      if (body is Map) {
        // Ambil detail error validasi spesifik dari Laravel (errors: {field: [message]})
        final rawErrors = body['errors'];
        if (rawErrors is Map) {
          final messages = <String>[];
          for (final entry in rawErrors.entries) {
            final val = entry.value;
            if (val is List && val.isNotEmpty) {
              messages.add(val.first.toString());
            } else if (val != null) {
              messages.add(val.toString());
            }
          }
          if (messages.isNotEmpty) {
            serverMessage = messages.join('\n');
          }
        }
        serverMessage ??= (body['message'] ?? body['error'])?.toString();
      } else if (body is String && body.isNotEmpty && !body.contains('<html') && !body.contains('<!DOCTYPE')) {
        serverMessage = body;
      }

      if (serverMessage != null && serverMessage.isNotEmpty && status != null && status < 500) {
        return ApiException(serverMessage, statusCode: status);
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ApiException('Koneksi terlalu lama. Periksa jaringan Anda.', statusCode: status);
        case DioExceptionType.connectionError:
          return ApiException('Tidak ada koneksi internet.', statusCode: status);
        default:
          break;
      }

      if (status == 403) {
        return const ApiException('Anda tidak punya akses ke fitur ini.', statusCode: 403);
      }
      if (status != null && status >= 500) {
        return ApiException(
          error.message ?? 'Server sedang bermasalah. Coba lagi sebentar.',
          statusCode: status,
        );
      }
    }

    return const ApiException('Terjadi kesalahan tak terduga.');
  }

  @override
  String toString() => message;
}
