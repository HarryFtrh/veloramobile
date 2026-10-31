import 'package:dio/dio.dart';

/// Error terstruktur untuk lapisan service, supaya UI bisa menampilkan
/// pesan yang jelas dan tidak perlu menelan exception.
/// Dilengkapi dukungan telemetri Cloudflare (CF-Ray ID, status 520-526, dan 429 Retry-After).
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.cfRayId,
    this.retryAfterSeconds,
  });

  final String message;
  final int? statusCode;
  final String? cfRayId;
  final int? retryAfterSeconds;

  /// Ubah error apa pun (terutama [DioException]) menjadi [ApiException].
  factory ApiException.from(Object error) {
    if (error is ApiException) return error;

    if (error is DioException) {
      final status = error.response?.statusCode;
      final body = error.response?.data;
      final headers = error.response?.headers;

      // 🔍 Ekstraksi CF-Ray ID dari Cloudflare Edge Response
      final cfRay = headers?.value('cf-ray');

      // ⏱️ Ekstraksi Retry-After header (dalam detik) jika terjadi HTTP 429 / 503
      int? retryAfter;
      final rawRetry = headers?.value('retry-after');
      if (rawRetry != null) {
        retryAfter = int.tryParse(rawRetry);
      }

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

      if (serverMessage != null && serverMessage.isNotEmpty && status != null && status < 500 && status != 429) {
        return ApiException(
          serverMessage,
          statusCode: status,
          cfRayId: cfRay,
          retryAfterSeconds: retryAfter,
        );
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ApiException(
            'Koneksi terlalu lama. Periksa jaringan Anda.${cfRay != null ? ' (Ray ID: $cfRay)' : ''}',
            statusCode: status,
            cfRayId: cfRay,
          );
        case DioExceptionType.connectionError:
          return ApiException('Tidak ada koneksi internet.', statusCode: status, cfRayId: cfRay);
        default:
          break;
      }

      // 🛡️ Cloudflare Rate Limiting (429 Too Many Requests)
      if (status == 429) {
        final waitMsg = retryAfter != null ? ' Mohon tunggu $retryAfter detik.' : ' Silakan coba beberapa saat lagi.';
        return ApiException(
          'Permintaan transaksi terlalu padat (Rate Limit).$waitMsg${cfRay != null ? ' (Ray: $cfRay)' : ''}',
          statusCode: 429,
          cfRayId: cfRay,
          retryAfterSeconds: retryAfter,
        );
      }

      // 🛡️ Cloudflare WAF Challenge / Block (403)
      if (status == 403) {
        final isCfBlocked = headers?.value('cf-mitigated') != null ||
            (body is String && (body.contains('cloudflare') || body.contains('cf-ray') || body.contains('Attention Required')));
        if (isCfBlocked) {
          return ApiException(
            'Koneksi dibatasi oleh firewall keamanan Cloudflare.${cfRay != null ? ' (Ray ID: $cfRay)' : ''}',
            statusCode: 403,
            cfRayId: cfRay,
          );
        }
        return ApiException(
          'Anda tidak punya akses ke fitur ini.${cfRay != null ? ' (Ray ID: $cfRay)' : ''}',
          statusCode: 403,
          cfRayId: cfRay,
        );
      }

      // ☁️ Cloudflare Origin / Edge Error Codes (520–526)
      if (status != null && status >= 520 && status <= 526) {
        String cfDetail;
        switch (status) {
          case 521:
            cfDetail = 'Server pusat sedang tidak aktif (Web Server Down)';
            break;
          case 522:
            cfDetail = 'Koneksi ke server pusat waktu habis (Connection Timed Out)';
            break;
          case 523:
            cfDetail = 'Server pusat tidak dapat dijangkau (Origin Unreachable)';
            break;
          case 524:
            cfDetail = 'Waktu tunggu pemrosesan habis (Gateway Timeout)';
            break;
          case 525:
          case 526:
            cfDetail = 'Validasi SSL server pusat gagal (SSL Handshake Error)';
            break;
          case 520:
          default:
            cfDetail = 'Terjadi galat pada gateway perantara Cloudflare';
            break;
        }
        return ApiException(
          '$cfDetail (Status $status). Transaksi beralih ke mode offline.${cfRay != null ? ' (Ray ID: $cfRay)' : ''}',
          statusCode: status,
          cfRayId: cfRay,
        );
      }

      if (status != null && status >= 500) {
        return ApiException(
          'Server sedang bermasalah. Coba lagi sebentar.${cfRay != null ? ' (Ray ID: $cfRay)' : ''}',
          statusCode: status,
          cfRayId: cfRay,
        );
      }
    }

    return const ApiException('Terjadi kesalahan tak terduga.');
  }

  @override
  String toString() => message;
}
