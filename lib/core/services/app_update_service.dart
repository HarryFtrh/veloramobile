import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_config.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../network/api_client.dart';

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

/// Status pembaruan dari server atau Play Store
class AppUpdateCheckResult {
  final bool hasUpdate;
  final bool isForceUpdate;
  final String? latestVersionName;
  final int? latestVersionCode;
  final String? releaseNotes;
  final String? storeUrl;

  const AppUpdateCheckResult({
    required this.hasUpdate,
    this.isForceUpdate = false,
    this.latestVersionName,
    this.latestVersionCode,
    this.releaseNotes,
    this.storeUrl,
  });
}

/// Service untuk mengelola versi aplikasi, In-App Update, dan navigasi ke Google Play Store
class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static const MethodChannel _channel = MethodChannel('com.velora.mobile/app_update');
  AppVersionInfo? _cachedVersion;

  /// Inisialisasi listener interceptor pembaruan API
  static void init() {
    ApiClient.onAppUpdateRequired = () {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        instance.checkAndPrompt(ctx);
      }
    };
  }

  /// Mengambil informasi versi lokal dari Android PackageManager
  Future<AppVersionInfo> getAppVersion() async {
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
        debugPrint('[AppUpdateService] Gagal membaca versi dari platform channel: $e');
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

  /// Membuka Google Play Store untuk aplikasi ini
  Future<bool> openPlayStore({String? packageName}) async {
    final info = await getAppVersion();
    final targetPackage = packageName ?? info.packageName;

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final ok = await _channel.invokeMethod<bool>('openPlayStore', {
          'packageName': targetPackage,
        });
        return ok ?? false;
      } catch (e) {
        debugPrint('[AppUpdateService] Gagal membuka Play Store via channel: $e');
      }
    }
    return false;
  }

  /// Memeriksa ke backend apakah ada pembaruan versi Play Store
  Future<AppUpdateCheckResult> checkForUpdate() async {
    final current = await getAppVersion();

    try {
      final res = await ApiClient.instance.dio.get(
        '/v1/mobile/version-check',
        queryParameters: {
          'flavor': AppConfig.instance.flavor.name,
          'package': current.packageName,
          'version_code': current.versionCode,
          'version_name': current.versionName,
        },
      );

      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data['data'] is Map ? res.data['data'] : res.data;
        final latestCode = (data['latest_version_code'] as num?)?.toInt() ?? current.versionCode;
        final minCode = (data['min_version_code'] as num?)?.toInt() ?? 0;
        final latestName = data['latest_version_name']?.toString() ?? current.versionName;
        final notes = data['release_notes']?.toString();
        final force = (data['force_update'] == true) || (current.versionCode < minCode);
        final hasUpdate = latestCode > current.versionCode || force;

        return AppUpdateCheckResult(
          hasUpdate: hasUpdate,
          isForceUpdate: force,
          latestVersionName: latestName,
          latestVersionCode: latestCode,
          releaseNotes: notes,
        );
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Endpoint version-check belum aktif atau offline: $e');
    }

    // Jika endpoint backend belum diaktifkan, tidak perlu memaksa update
    return const AppUpdateCheckResult(hasUpdate: false);
  }

  /// Menampilkan dialog pembaruan Play Store yang ramah pengguna
  Future<void> showUpdateDialog(
    BuildContext context, {
    required AppUpdateCheckResult result,
    required AppVersionInfo currentVersion,
  }) async {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    await showDialog(
      context: context,
      barrierDismissible: !result.isForceUpdate,
      builder: (ctx) => PopScope(
        canPop: !result.isForceUpdate,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.lg)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.system_update_rounded, color: p.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.isForceUpdate ? 'Pembaruan Wajib' : 'Pembaruan Tersedia',
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Versi baru Velora (${result.latestVersionName ?? 'Terbaru'}) sudah tersedia di Google Play Store.',
                style: text.bodyMedium?.copyWith(color: p.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Versi saat ini: v${currentVersion.versionName} (Build ${currentVersion.versionCode})',
                style: text.bodySmall?.copyWith(color: p.textTertiary),
              ),
              if (result.releaseNotes != null && result.releaseNotes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: p.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    result.releaseNotes!,
                    style: text.bodySmall?.copyWith(color: p.textSecondary),
                  ),
                ),
              ],
              if (result.isForceUpdate) ...[
                const SizedBox(height: 12),
                Text(
                  'Pembaruan ini diperlukan untuk kompatibilitas sistem transaksi & API toko.',
                  style: text.bodySmall?.copyWith(color: p.danger, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
          actions: [
            if (!result.isForceUpdate)
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Nanti Saja', style: TextStyle(color: p.textSecondary)),
              ),
            FilledButton.icon(
              onPressed: () {
                openPlayStore(packageName: currentVersion.packageName);
                if (!result.isForceUpdate) {
                  Navigator.of(ctx).pop();
                }
              },
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: const Text('Buka Play Store'),
            ),
          ],
        ),
      ),
    );
  }

  /// Cek pembaruan dan buka dialog jika ada update (cocok dipanggil di Settings atau background)
  Future<void> checkAndPrompt(BuildContext context, {bool notifyIfUpToDate = false}) async {
    final current = await getAppVersion();
    final result = await checkForUpdate();

    if (!context.mounted) return;

    if (result.hasUpdate) {
      await showUpdateDialog(context, result: result, currentVersion: current);
    } else if (notifyIfUpToDate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aplikasi sudah versi terbaru (v${current.versionName})'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
