import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import '../config/app_version_info.dart';
import '../storage/session_storage.dart';

class ApiClient {
  late final Dio dio;
  static late ApiClient instance;
  static const _uuid = Uuid();

  static void init() {
    instance = ApiClient._();
  }

  static void Function()? onSessionExpired;
  static void Function(String message)? onSubscriptionBlocked;
  static void Function()? onAppUpdateRequired;
  static void Function(int? retryAfterSeconds, String? cfRayId)? onRateLimited;
  static void Function(String? cfRayId)? onCloudflareWafBlocked;

  ApiClient._() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.instance.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'User-Agent': 'VeloraMobile/1.0.0',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SessionStorage.instance.getAuthToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          final locationId = SessionStorage.instance.getLocationId();
          if (locationId != null && locationId.isNotEmpty && locationId.toLowerCase() != 'undefined' && locationId.toLowerCase() != 'null') {
            options.headers['X-Location-Id'] = locationId;
          }

          final tenantId = SessionStorage.instance.getTenantId();
          if (tenantId != null && tenantId.isNotEmpty && tenantId.toLowerCase() != 'undefined' && tenantId.toLowerCase() != 'null') {
            options.headers['X-Tenant-Id'] = tenantId;
          }

          final deviceId = await SessionStorage.instance.getDeviceId();
          options.headers['X-Device-Id'] = deviceId;
          options.headers.putIfAbsent('X-Terminal-Id', () => 'MOBILE-POS-01');

          // Context Bisnis (F&B, Farmasi, Retail, Sales, Customer)
          final bizType = SessionStorage.instance.getBusinessType() ?? AppConfig.instance.flavor.name;
          if (bizType.isNotEmpty) {
            options.headers['X-Business-Type'] = bizType.toLowerCase();
          }

          // Versi Aplikasi & Flavor untuk Cloudflare WAF & Backward-Compatibility Guard di Server
          final flavorName = AppConfig.instance.flavor.name;
          options.headers['X-App-Flavor'] = flavorName;

          try {
            final ver = await AppVersionHelper.getAppVersion();
            options.headers['User-Agent'] = 'VeloraMobile/${ver.versionName} (Android; Flavor=$flavorName; Build=${ver.versionCode}; DeviceId=$deviceId)';
            options.headers['X-App-Version'] = ver.versionName;
            options.headers['X-App-Version-Code'] = ver.versionCode.toString();
          } catch (_) {
            options.headers['User-Agent'] = 'VeloraMobile/1.0.0 (Android; Flavor=$flavorName; DeviceId=$deviceId)';
            options.headers.putIfAbsent('X-App-Version', () => '1.0.0');
            options.headers.putIfAbsent('X-App-Version-Code', () => '1');
          }

          // ⚡ IETF RFC 8935 Idempotency-Key untuk mengamankan transaksi mutasi dari dobel-kirim
          final method = options.method.toUpperCase();
          if (const ['POST', 'PUT', 'PATCH', 'DELETE'].contains(method)) {
            if (!options.headers.containsKey('Idempotency-Key') && !options.headers.containsKey('X-Idempotency-Key')) {
              options.headers['Idempotency-Key'] = _uuid.v4();
            }
          }

          // 🔍 W3C Distributed Tracing / RFC 9457 Correlation ID untuk pelacakan end-to-end di Cloudflare & backend
          if (!options.headers.containsKey('X-Correlation-Id')) {
            options.headers['X-Correlation-Id'] = _uuid.v4();
          }

          if (kDebugMode) {
            final sanitized = _sanitizeData(options.data);
            debugPrint('🌐 [API REQ] ${options.method} ${options.baseUrl}${options.path} (trace: ${options.headers['X-Correlation-Id']}) -> data: $sanitized');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          final cfRay = response.headers.value('cf-ray');
          final cfCache = response.headers.value('cf-cache-status');
          if (kDebugMode) {
            final cfInfo = cfRay != null ? ' [CF-Ray: $cfRay, Cache: $cfCache]' : '';
            debugPrint('✅ [API RES] ${response.statusCode} ${response.requestOptions.path}$cfInfo -> ${_sanitizeData(response.data)}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          final traceId = e.response?.data is Map ? e.response?.data['trace_id'] : null;
          final cfRay = e.response?.headers.value('cf-ray');
          final statusCode = e.response?.statusCode;

          if (kDebugMode) {
            final cfInfo = cfRay != null ? ' [CF-Ray: $cfRay]' : '';
            debugPrint('❌ [API ERR] $statusCode ${e.requestOptions.path}$cfInfo (trace: $traceId) -> data: ${_sanitizeData(e.response?.data)} | msg: ${e.message}');
          }

          // 1. Tangani 401 Unauthorized / Sesi Berakhir
          if (statusCode == 401) {
            await SessionStorage.instance.clearAuthToken();
            onSessionExpired?.call();
          }

          // 2. Tangani 402 / 403 Batasan Langganan & Kredit (SubscriptionGuard)
          if (statusCode == 402 || (statusCode == 403 && e.response?.data is Map && (e.response?.data['code'] == 'SUBSCRIPTION_EXPIRED' || e.response?.data['code'] == 'CREDIT_LOCKED'))) {
            final msg = (e.response?.data is Map ? e.response?.data['message'] : null) ?? 'Masa langganan atau kredit operasional toko telah berakhir.';
            onSubscriptionBlocked?.call(msg.toString());
          }

          // 3. Tangani 426 Upgrade Required (Pembaruan Versi Play Store Wajib)
          if (statusCode == 426 || (e.response?.data is Map && e.response?.data['code'] == 'APP_UPDATE_REQUIRED')) {
            onAppUpdateRequired?.call();
          }

          // 4. Tangani 429 Cloudflare Rate Limit
          if (statusCode == 429) {
            final rawRetry = e.response?.headers.value('retry-after');
            final retrySec = rawRetry != null ? int.tryParse(rawRetry) : null;
            onRateLimited?.call(retrySec, cfRay);
          }

          // 5. Tangani 403 Cloudflare WAF Blocked
          if (statusCode == 403) {
            final isCf = e.response?.headers.value('cf-mitigated') != null ||
                (e.response?.data is String && (e.response!.data as String).contains('cloudflare'));
            if (isCf) {
              onCloudflareWafBlocked?.call(cfRay);
            }
          }

          // 6. Normalisasi pesan error Cloudflare (520-526) & Gateway Timeout agar tidak melempar HTML atau null crash ke UI
          if (statusCode != null && statusCode >= 520 && statusCode <= 526) {
            final cfMsg = statusCode == 521
                ? 'Server pusat Velora sedang offline (Cloudflare 521 Web Server Down). Mengalihkan ke transaksi offline.'
                : 'Layanan cloud pusat sedang mengalami gangguan perantara Cloudflare (Status $statusCode).';
            e = e.copyWith(message: cfMsg);
          } else if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
            e = e.copyWith(
              message: 'Server sedang dalam pemeliharaan sementara. Silakan coba beberapa saat lagi.',
            );
          }

          return handler.next(e);
        },
      ),
    );
  }

  /// Cek kesehatan koneksi backend live (/api/health atau /api/up)
  static Future<bool> checkHealth() async {
    try {
      final res = await instance.dio.get('/health');
      return res.statusCode == 200;
    } catch (_) {
      try {
        final res = await instance.dio.get('/up');
        return res.statusCode == 200;
      } catch (_) {
        return false;
      }
    }
  }

  /// Sanitasi data log untuk mencegah kebocoran kredensial (PIN, password, token)
  /// dan PII medis pasien (NIK, KTP, Rekam Medis, Diagnosis) di console/logcat (UU PDP No. 27/2022)
  static dynamic _sanitizeData(dynamic data) {
    if (data is Map) {
      final copy = <String, dynamic>{};
      for (final entry in data.entries) {
        final k = entry.key.toString();
        final lower = k.toLowerCase();
        final isSensitive = lower.contains('password') ||
            lower == 'pin' ||
            lower.contains('secret') ||
            lower.contains('token') ||
            lower.contains('authorization') ||
            lower.contains('nik') ||
            lower.contains('ktp') ||
            lower.contains('medical_record') ||
            lower.contains('no_rm') ||
            lower.contains('rm_number') ||
            lower.contains('diagnosis') ||
            lower.contains('anamnesis') ||
            lower.contains('allerg');

        if (isSensitive) {
          copy[k] = '***REDACTED***';
        } else if (entry.value is Map || entry.value is List) {
          copy[k] = _sanitizeData(entry.value);
        } else {
          copy[k] = entry.value;
        }
      }
      return copy;
    } else if (data is List) {
      return data.map((e) => _sanitizeData(e)).toList();
    }
    return data;
  }
}
