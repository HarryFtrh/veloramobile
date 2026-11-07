import 'package:flutter/material.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/utils/audio_helper.dart';
import '../../../shared_pos/offline_sync_badge.dart';

/// Bilah Navigasi Atas & Kontrol Shift Kasir Apotek
class PharmacyPosHeader extends StatelessWidget {
  final bool isMobile;
  final double screenWidth;
  final String tenant;
  final String location;
  final bool isShiftOpen;
  final String shiftText;
  final String cashier;
  final bool isGridView;
  final bool isLoadingCatalog;
  final int pendingOfflineCount;
  final VoidCallback onOpenShiftReport;
  final VoidCallback onOpenQueue;
  final VoidCallback onOpenHistory;
  final VoidCallback onToggleViewMode;
  final VoidCallback onSyncCatalog;
  final VoidCallback onOpenPrescriptionReview;
  final VoidCallback onOpenStockAlert;
  final VoidCallback onOpenPrinterSettings;
  final VoidCallback onSyncOffline;
  final VoidCallback? onLogout;

  const PharmacyPosHeader({
    super.key,
    required this.isMobile,
    required this.screenWidth,
    required this.tenant,
    required this.location,
    required this.isShiftOpen,
    required this.shiftText,
    required this.cashier,
    required this.isGridView,
    required this.isLoadingCatalog,
    required this.pendingOfflineCount,
    required this.onOpenShiftReport,
    required this.onOpenQueue,
    required this.onOpenHistory,
    required this.onToggleViewMode,
    required this.onSyncCatalog,
    required this.onOpenPrescriptionReview,
    required this.onOpenStockAlert,
    required this.onOpenPrinterSettings,
    required this.onSyncOffline,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = ClinicalPalette.primary;
    const borderColor = Color(0xFFE2E8F0);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 18, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Clinic Icon & Name & Branch
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF0D9488)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: emeraldPrimary.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tenant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Actions Cluster & Cashier Shift
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMobile && screenWidth >= 980) ...[
                InkWell(
                  onTap: onOpenShiftReport,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 14,
                          color: isShiftOpen ? const Color(0xFF0D9488) : const Color(0xFFEA580C),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cashier,
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 1,
                          height: 12,
                          color: borderColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          shiftText,
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: isShiftOpen ? const Color(0xFF0D9488) : const Color(0xFFEA580C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const OfflineSyncBadge(showClock: false),
              const SizedBox(width: 6),

              // Segmented Action Bar
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isMobile) ...[
                      IconButton(
                        icon: const Icon(Icons.people_outline_rounded, size: 18, color: Color(0xFF0D9488)),
                        tooltip: 'Antrean Pasien & Billing',
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 34),
                        padding: EdgeInsets.zero,
                        onPressed: onOpenQueue,
                      ),
                    ],
                    IconButton(
                      icon: const Icon(Icons.receipt_long_rounded, size: 18, color: Color(0xFF64748B)),
                      tooltip: 'Riwayat Transaksi',
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 34),
                      padding: EdgeInsets.zero,
                      onPressed: onOpenHistory,
                    ),
                    IconButton(
                      icon: Icon(
                        isGridView ? Icons.grid_view_rounded : Icons.view_list_rounded,
                        size: 18,
                        color: const Color(0xFF0D9488),
                      ),
                      tooltip: isGridView ? 'Beralih ke List' : 'Beralih ke Grid',
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 34),
                      padding: EdgeInsets.zero,
                      onPressed: onToggleViewMode,
                    ),
                    PopupMenuButton<String>(
                      constraints: const BoxConstraints(minWidth: 200, maxWidth: 260),
                      icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF64748B)),
                      tooltip: 'Menu Tambahan',
                      padding: EdgeInsets.zero,
                      onSelected: (val) {
                        AudioHelper.tapFeedback();
                        switch (val) {
                          case 'sync':
                            onSyncCatalog();
                            break;
                          case 'queue':
                            onOpenQueue();
                            break;
                          case 'review':
                            onOpenPrescriptionReview();
                            break;
                          case 'stock_alert':
                            onOpenStockAlert();
                            break;
                          case 'printer':
                            onOpenPrinterSettings();
                            break;
                          case 'offline':
                            onSyncOffline();
                            break;
                          case 'logout':
                            onLogout?.call();
                            break;
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'sync',
                          child: Row(
                            children: [
                              Icon(Icons.sync_rounded, size: 18, color: isLoadingCatalog ? Colors.grey : emeraldPrimary),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text('Sinkronkan Katalog', overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                        if (isMobile)
                          const PopupMenuItem(
                            value: 'queue',
                            child: Row(
                              children: [
                                Icon(Icons.people_outline_rounded, size: 18, color: Color(0xFF0D9488)),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text('Antrean Pasien', overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'review',
                          child: Row(
                            children: [
                              Icon(Icons.assignment_outlined, size: 18, color: Color(0xFF0D9488)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text('Telaah Resep', overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'stock_alert',
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFEA580C)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text('Alert Stok & FEFO', overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'printer',
                          child: Row(
                            children: [
                              Icon(Icons.print_outlined, size: 18, color: Color(0xFF6D7A72)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text('Pengaturan Printer', overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                        if (pendingOfflineCount > 0)
                          PopupMenuItem(
                            value: 'offline',
                            child: Row(
                              children: [
                                const Icon(Icons.cloud_upload_outlined, size: 18, color: emeraldPrimary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Sync Offline ($pendingOfflineCount)',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (onLogout != null)
                          const PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout_rounded, size: 18, color: Color(0xFFBA1A1A)),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Keluar Kasir',
                                    style: TextStyle(color: Color(0xFFBA1A1A)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
