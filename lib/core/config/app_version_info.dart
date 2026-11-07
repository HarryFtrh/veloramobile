import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'app_config.dart';

/// Informasi versi aplikasi yang sedang berjalan
class AppVersionInfo {
  final String packageName;
  final String versionName;
  final int versionCode;

  const AppVersionInfo({
    required this.packageName,
    required this.versionName,
    required this.versionCode,
  });

  @override
  String toString() => '$versionName ($versionCode)';
}

/// Helper pembaca versi aplikasi dari PackageManager Android tanpa dependensi network
class AppVersionHelper {
  static const MethodChannel _channel = MethodChannel('com.velora.mobile/app_update');
  static AppVersionInfo? _cachedVersion;

  /// Mengambil informasi versi lokal dari Android PackageManager
  static Future<AppVersionInfo> getAppVersion() async {
    if (_cachedVersion != null) return _cachedVersion!;

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final res = await _channel.invokeMapMethod<String, dynamic>('getAppVersion');
        if (res != null) {
          final info = AppVersionInfo(
            packageName: res['packageName']?.toString() ?? 'com.velora.velora_mobile',
            versionName: res['versionName']?.toString() ?? '1.0.0',
            versionCode: (res['versionCode'] as num?)?.toInt() ?? 1,
          );
          _cachedVersion = info;
          return info;
        }
      } catch (e) {
        debugPrint('[AppVersionHelper] Gagal membaca versi dari platform channel: $e');
      }
    }

    // Fallback default
    final fallback = AppVersionInfo(
      packageName: 'com.velora.${AppConfig.instance.flavor.name}',
      versionName: '1.0.0',
      versionCode: 1,
    );
    _cachedVersion = fallback;
    return fallback;
  }
}
