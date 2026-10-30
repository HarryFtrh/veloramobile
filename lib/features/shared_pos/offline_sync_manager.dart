import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';

/// Manajer sinkronisasi otomatis transaksi offline di background.
/// Berjalan secara senyap saat internet kembali pulih tanpa mengganggu kasir.
class OfflineSyncManager {
  static final OfflineSyncManager instance = OfflineSyncManager._();
  OfflineSyncManager._();

  bool _isSyncing = false;
  Timer? _autoSyncTimer;

  /// Callback jika ada transaksi offline yang berhasil disinkronkan ke server
  static void Function(int syncedCount)? onSyncSuccess;

  /// Memulai pengecekan periodik sinkronisasi offline (default per 25 detik)
  void startAutoSync({Duration interval = const Duration(seconds: 25)}) {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(interval, (_) => triggerSync());
  }

  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  /// Pemicu sinkronisasi manual atau background
  Future<int> triggerSync() async {
    if (_isSyncing) return 0;
    final queue = SessionStorage.instance.getOfflineQueue();
    if (queue.isEmpty) return 0;

    final token = await SessionStorage.instance.getAuthToken();
    if (token == null || token.isEmpty) return 0;

    // Pastikan server backend dalam keadaan sehat sebelum mengirim batch
    final isHealthy = await ApiClient.checkHealth();
    if (!isHealthy) return 0;

    _isSyncing = true;
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
        return 0;
      }

      debugPrint('🔄 [OFFLINE SYNC] Mengirim ${transactions.length} transaksi offline ke /v1/pos/offline-batch-sync...');

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
        debugPrint('✅ [OFFLINE SYNC] Berhasil menyinkronkan $syncedCount transaksi offline ke server cloud');
        onSyncSuccess?.call(syncedCount);
        return syncedCount;
      }
    } catch (e) {
      debugPrint('⚠️ [OFFLINE SYNC] Sinkronisasi ditunda (koneksi/server belum siap): $e');
    } finally {
      _isSyncing = false;
    }
    return 0;
  }
}
