import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/session_storage.dart';

class ApiClient {
  late final Dio dio;
  static late ApiClient instance;

  static void init() {
    instance = ApiClient._();
  }

  static void Function()? onSessionExpired;

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

          // ignore: avoid_print
          print('🌐 [API REQ] ${options.method} ${options.baseUrl}${options.path} -> data: ${options.data}');

          return handler.next(options);
        },
        onResponse: (response, handler) {
          // ignore: avoid_print
          print('✅ [API RES] ${response.statusCode} ${response.requestOptions.path} -> ${response.data}');
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          // ignore: avoid_print
          print('❌ [API ERR] ${e.response?.statusCode} ${e.requestOptions.path} -> data: ${e.response?.data} | msg: ${e.message}');

          // 1. Tangani 401 Unauthorized / Sesi Berakhir
          if (e.response?.statusCode == 401) {
            await SessionStorage.instance.clearAuthToken();
            onSessionExpired?.call();
          }

          // 2. Normalisasi pesan error agar tidak melempar HTML atau null crash ke UI
          if (e.response?.statusCode == 502 || e.response?.statusCode == 503 || e.response?.statusCode == 504) {
            e = e.copyWith(
              message: 'Server sedang dalam pemeliharaan sementara. Silakan coba beberapa saat lagi.',
            );
          }

          return handler.next(e);
        },
      ),
    );
  }
}
