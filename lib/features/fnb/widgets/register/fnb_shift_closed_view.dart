import 'package:flutter/material.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/utils/audio_helper.dart';
import '../../../shared_pos/receipt_printer_service.dart';
import '../../../shared_pos/shift_modal.dart';
import '../../../shared_pos/shift_service.dart';

/// Screen view shown when cashier shift is closed/locked
class FnbShiftClosedView extends StatelessWidget {
  final Future<void> Function() onRefreshShift;
  final VoidCallback? onOpenBills;

  const FnbShiftClosedView({
    super.key,
    required this.onRefreshShift,
    this.onOpenBills,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 36,
          vertical: 28,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.lock_clock_rounded,
                  size: 40,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: p.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: p.danger.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 14, color: p.danger),
                    const SizedBox(width: 6),
                    Text(
                      'STATUS: SHIFT KASIR DITUTUP',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: p.danger,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Laci & Register Kasir Terkunci',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Shift kasir saat ini sedang nonaktif. Buka shift kasir baru dengan modal kas awal untuk mulai menambahkan menu ke keranjang dan memproses transaksi penjualan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: p.textSecondary,
                ),
              ),
              const SizedBox(height: 26),
              ElevatedButton.icon(
                onPressed: () async {
                  AudioHelper.tapFeedback();
                  await ShiftDialogs.showOpenShiftDialog(
                    context,
                    onOpened: (_) => onRefreshShift(),
                  );
                },
                icon: const Icon(Icons.point_of_sale_rounded, size: 20),
                label: const Text(
                  'BUKA SHIFT KASIR BARU',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: const StadiumBorder(),
                  elevation: 1,
                  shadowColor: primaryColor.withValues(alpha: 0.4),
                ),
              ),
              if (ShiftService.instance.lastCloseSummary != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    AudioHelper.tapFeedback();
                    ShiftDialogs.showShiftReportDialog(
                      context,
                      ShiftService.instance.lastCloseSummary!,
                      onDone: () {},
                    );
                  },
                  icon: const Icon(Icons.assessment_rounded, size: 18),
                  label: const Text(
                    'Lihat Laporan Tutup Shift Terakhir',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: p.textPrimary,
                    side: BorderSide(color: p.line),
                    minimumSize: const Size.fromHeight(48),
                    shape: const StadiumBorder(),
                  ),
                ),
              ],
              if (onOpenBills != null) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: p.line)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'PILIHAN & PENGATURAN LAINNYA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: p.textTertiary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: p.line)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildClosedQuickCard(
                        context: context,
                        icon: Icons.receipt_long_rounded,
                        title: 'Riwayat & Antrean',
                        subtitle: 'Cek transaksi sebelumnya',
                        onTap: onOpenBills!,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildClosedQuickCard(
                        context: context,
                        icon: Icons.print_outlined,
                        title: 'Printer Thermal',
                        subtitle: 'Konfigurasi Bluetooth / IP',
                        onTap: () => ReceiptPrinterService.instance.openSettings(context),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClosedQuickCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.line, width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          AudioHelper.tapFeedback();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: p.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: primaryColor),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.5,
                  color: p.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
