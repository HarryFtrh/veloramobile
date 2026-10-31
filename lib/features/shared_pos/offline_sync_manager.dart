import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';

/// Manajer sinkronisasi otomatis transaksi offline di background.
/// Berjalan secara senyap saat internet kembali pulih tanpa mengganggu kasir.
/// Dilengkapi adaptive exponential backoff dengan jitter untuk mencegah server overload.
class OfflineSyncManager {
  static final OfflineSyncManager instance = OfflineSyncManager._();
  OfflineSyncManager._();

  bool _isSyncing = false;
  Timer? _autoSyncTimer;
  int _consecutiveFailures = 0;
  static const int _minIntervalSeconds = 5;
  static const int _maxIntervalSeconds = 60;
  static const int _defaultIntervalSeconds = 25;

  final ValueNotifier<int> queueCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);

  void refreshState() {
    queueCountNotifier.value = SessionStorage.instance.getOfflineQueueCount();
    isSyncingNotifier.value = _isSyncing;
  }

  /// Callback jika ada transaksi offline yang berhasil disinkronkan ke server
  static void Function(int syncedCount)? onSyncSuccess;

  /// Memulai pengecekan periodik sinkronisasi offline dengan adaptive timing
  void startAutoSync({Duration interval = const Duration(seconds: _defaultIntervalSeconds)}) {
    _autoSyncTimer?.cancel();
    refreshState();
    _scheduleNextSync(interval.inSeconds);
  }

  void _scheduleNextSync(int seconds) {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer(Duration(seconds: seconds), () async {
      await triggerSync();
      // Hitung interval berikutnya berdasarkan status antrean & kegagalan
      final queueCount = SessionStorage.instance.getOfflineQueueCount();
      if (queueCount == 0) {
        _consecutiveFailures = 0;
        _scheduleNextSync(_defaultIntervalSeconds);
      } else if (_consecutiveFailures > 0) {
        // Exponential backoff dengan jitter: min(max, min * 2^failures) + jitter
        final base = min(_maxIntervalSeconds, _minIntervalSeconds * pow(2, min(_consecutiveFailures, 4)).toInt());
        final jitter = Random().nextInt(4);
        _scheduleNextSync(base + jitter);
      } else {
        _scheduleNextSync(_minIntervalSeconds);
      }
    });
  }

  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  /// Masukkan transaksi ke antrean offline dan picu sinkronisasi segera
  Future<void> enqueueAndSync(Map<String, dynamic> saleRecord) async {
    await SessionStorage.instance.enqueueOfflineSale(jsonEncode(saleRecord));
    refreshState();
    // Picu sinkronisasi tanpa menunda
    unawaited(triggerSync());
  }

  /// Pemicu sinkronisasi manual atau background
  Future<int> triggerSync() async {
    if (_isSyncing) return 0;
    refreshState();

    final queue = SessionStorage.instance.getOfflineQueue();
    if (queue.isEmpty) {
      _consecutiveFailures = 0;
      return 0;
    }

    final token = await SessionStorage.instance.getAuthToken();
    if (token == null || token.isEmpty) return 0;

    // Pastikan server backend dalam keadaan sehat sebelum mengirim batch
    final isHealthy = await ApiClient.checkHealth();
    isOnlineNotifier.value = isHealthy;
    if (!isHealthy) {
      _consecutiveFailures++;
      return 0;
    }

    _isSyncing = true;
    refreshState();
    try {
      final List<Map<String, dynamic>> transactions = [];
      for (final raw in queue) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            transactions.add(decoded);
          } else if (decoded is Map) {
            transactions.add(Map<String, dynamic>.from(decoded));
          }
        } catch (_) {}
      }

      if (transactions.isEmpty) {
        await SessionStorage.instance.clearOfflineQueue();
        _consecutiveFailures = 0;
        return 0;
      }

      debugPrint('🔄 [OFFLINE SYNC] Mengirim ${transactions.length} transaksi offline ke backend...');

      final payload = {
        'transactions': transactions,
        'orders': transactions,
      };

      dynamic res;
      try {
        res = await ApiClient.instance.dio.post(
          '/v1/pos/offline-batch-sync',
          data: payload,
        );
      } catch (e) {
        // Fallback endpoint baru dari commit 1c2e3e9c5
        try {
          res = await ApiClient.instance.dio.post(
            '/retail/pos/checkout/batch-offline',
            data: payload,
          );
        } catch (_) {
          rethrow;
        }
      }

      if (res != null && (res.statusCode == 200 || res.statusCode == 201)) {
        final syncedCount = transactions.length;
        await SessionStorage.instance.clearOfflineQueue();
        _consecutiveFailures = 0;

        // Jika backend merespons ada item gagal, masukkan kembali ke antrean
        if (res.data is Map) {
          final innerData = res.data['data'] is Map ? res.data['data'] : res.data;
          final failedList = innerData['failed'];
          if (failedList is List && failedList.isNotEmpty) {
            for (final f in failedList) {
              if (f is Map) {
                await SessionStorage.instance.enqueueOfflineSale(jsonEncode(f));
              }
            }
          }
        }

        debugPrint('✅ [OFFLINE SYNC] Berhasil menyinkronkan $syncedCount transaksi offline ke server cloud');
        onSyncSuccess?.call(syncedCount);
        return syncedCount;
      } else {
        _consecutiveFailures++;
      }
    } catch (e) {
      _consecutiveFailures++;
      if (e is DioException) {
        final status = e.response?.statusCode;
        final cfRay = e.response?.headers.value('cf-ray');
        final rayInfo = cfRay != null ? ' (CF-Ray: $cfRay)' : '';

        // Tangani Cloudflare Rate Limit 429 & Retry-After secara adaptif
        if (status == 429) {
          int backoffSeconds = 60;
          final retryHeader = e.response?.headers.value('retry-after');
          if (retryHeader != null) {
            final parsed = int.tryParse(retryHeader);
            if (parsed != null && parsed > 0) backoffSeconds = parsed;
          }
          debugPrint('⚠️ [OFFLINE SYNC] Terkena Cloudflare Rate Limit (HTTP 429)$rayInfo. Menunda sinkronisasi selama $backoffSeconds detik.');
          _scheduleNextSync(backoffSeconds);
          return 0;
        }

        // Tangani Cloudflare Origin Down (521-526)
        if (status != null && status >= 520 && status <= 526) {
          debugPrint('⚠️ [OFFLINE SYNC] Cloudflare Edge melaporkan origin server bermasalah (HTTP $status)$rayInfo. Menunggu server pulih...');
        }
      }
      debugPrint('⚠️ [OFFLINE SYNC] Sinkronisasi ditunda (koneksi/server belum siap, retry #$_consecutiveFailures): $e');
    } finally {
      _isSyncing = false;
      refreshState();
    }
    return 0;
  }

  /// Pemicu sinkronisasi manual dengan laporan detail (digunakan oleh PosCheckoutService & UI)
  Future<Map<String, dynamic>> triggerSyncDetailed() async {
    final prevCount = SessionStorage.instance.getOfflineQueueCount();
    final synced = await triggerSync();
    final remaining = SessionStorage.instance.getOfflineQueueCount();
    return {
      'synced': synced,
      'failed': max(0, prevCount - synced - remaining),
      'remaining': remaining,
    };
  }
}
