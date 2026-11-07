import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';
import 'offline_sync_manager.dart';

/// Badge status jaringan dan sinkronisasi offline interaktif untuk Header AppShell & POS.
/// Memberikan kepastian visual bagi kasir tentang status koneksi dan antrean transaksi offline.
class OfflineSyncBadge extends StatelessWidget {
  final bool showClock;
  final String? timeStr;

  const OfflineSyncBadge({
    super.key,
    this.showClock = true,
    this.timeStr,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return ValueListenableBuilder<int>(
      valueListenable: OfflineSyncManager.instance.queueCountNotifier,
      builder: (context, count, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: OfflineSyncManager.instance.isSyncingNotifier,
          builder: (context, isSyncing, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: OfflineSyncManager.instance.isOnlineNotifier,
              builder: (context, isOnline, _) {
                // Skenario 1: Ada antrean offline yang perlu disinkronkan
                if (count > 0) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: isSyncing
                        ? null
                        : () async {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Memulai sinkronisasi transaksi offline ke cloud...'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            final res = await OfflineSyncManager.instance.triggerSyncDetailed();
                            if (!context.mounted) return;
                            final synced = res['synced'] ?? 0;
                            final rem = res['remaining'] ?? 0;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  synced > 0
                                      ? '✅ Berhasil menyinkronkan $synced transaksi! (Tersisa: $rem)'
                                      : (rem > 0 ? '⚠️ Server belum dapat dijangkau. Transaksi aman tersimpan lokal.' : 'Semua data telah sinkron.'),
                                ),
                                backgroundColor: synced > 0 ? Colors.green.shade700 : Colors.amber.shade900,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSyncing)
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber.shade900),
                            )
                          else
                            Icon(Icons.cloud_upload_rounded, size: 13, color: Colors.amber.shade900),
                          const SizedBox(width: 5),
                          Text(
                            isSyncing ? 'SINKRON...' : '$count OFFLINE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.amber.shade900,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Skenario 2: Antrean kosong (Online Normal atau Offline Bersih)
                final activeColor = isOnline ? p.tertiary : p.warning;
                final label = isOnline ? 'ONLINE' : 'OFFLINE';

                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    final res = await OfflineSyncManager.instance.triggerSyncDetailed();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Koneksi: ${isOnline ? "Online & Terhubung" : "Offline"}. Antrean: ${res['remaining'] ?? 0}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: p.surfaceMuted,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: p.line),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 6, color: activeColor),
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: activeColor,
                          ),
                        ),
                        if (showClock && timeStr != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            timeStr!,
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: p.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
