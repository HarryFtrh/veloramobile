import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/audio_helper.dart';
import 'receipt_printer_service.dart';
import 'shift_service.dart';
import 'shift_modal.dart';

class CashierShiftBadge extends StatefulWidget {
  final VoidCallback? onShiftChanged;

  const CashierShiftBadge({super.key, this.onShiftChanged});

  @override
  State<CashierShiftBadge> createState() => _CashierShiftBadgeState();
}

class _CashierShiftBadgeState extends State<CashierShiftBadge> {
  ShiftStatus? _status;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    ShiftService.instance.addListener(_onServiceChanged);
    _refreshStatus();
  }

  void _onServiceChanged() {
    if (mounted) {
      setState(() {
        _status = ShiftService.instance.currentStatus;
      });
    }
  }

  @override
  void dispose() {
    ShiftService.instance.removeListener(_onServiceChanged);
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    setState(() => _isLoading = true);
    try {
      final status = await ShiftService.instance.getShiftStatus();
      if (mounted) {
        setState(() {
          _status = status;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleTap() {
    AudioHelper.tapFeedback();
    if (_status == null || !_status!.isOpen) {
      ShiftDialogs.showOpenShiftDialog(
        context,
        onOpened: (newStatus) {
          setState(() => _status = newStatus);
          widget.onShiftChanged?.call();
        },
      );
    } else {
      _showShiftActionsModal();
    }
  }

  void _showShiftActionsModal() {
    final isMobile = context.isMobile;
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 560),
          child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: p.canvas,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: p.line, width: 1.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shift Kasir: ${_status?.cashierName ?? 'Kasir'}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: p.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Modal Awal: ${CurrencyFormatter.format(_status?.startingCash ?? 0)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: p.tertiary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, size: 20, color: p.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildShiftActionCard(
                    context: context,
                    icon: Icons.arrow_downward_rounded,
                    iconColor: p.tertiary,
                    iconBg: p.tertiary.withValues(alpha: 0.12),
                    title: 'Kas Masuk (Petty Cash In)',
                    subtitle: 'Tambah modal koin atau uang kecil ke laci kasir',
                    onTap: () {
                      Navigator.pop(ctx);
                      AudioHelper.tapFeedback();
                      ShiftDialogs.showPettyCashDialog(
                        context,
                        type: 'in',
                        onSuccess: _refreshStatus,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildShiftActionCard(
                    context: context,
                    icon: Icons.arrow_upward_rounded,
                    iconColor: p.danger,
                    iconBg: p.danger.withValues(alpha: 0.12),
                    title: 'Kas Keluar (Petty Cash Out)',
                    subtitle: 'Pengeluaran operasional darurat (es batu, galon, kurir)',
                    onTap: () {
                      Navigator.pop(ctx);
                      AudioHelper.tapFeedback();
                      ShiftDialogs.showPettyCashDialog(
                        context,
                        type: 'out',
                        onSuccess: _refreshStatus,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildShiftActionCard(
                    context: context,
                    icon: Icons.receipt_long_rounded,
                    iconColor: Colors.teal.shade700,
                    iconBg: Colors.teal.shade50,
                    title: 'Rekap Kas Berjalan (X-Report)',
                    subtitle: 'Cetak audit omzet & uang kas laci saat ini tanpa menutup shift',
                    onTap: () async {
                      Navigator.pop(ctx);
                      AudioHelper.actionFeedback();
                      final ok = await ReceiptPrinterService.instance.printXReport(_status!);
                      if (!context.mounted) return;
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok ? '✅ Laporan X-Report berhasil dicetak ke printer' : 'Laporan X-Report disiapkan'),
                          action: SnackBarAction(
                            label: 'Bagikan',
                            textColor: Colors.amber,
                            onPressed: () => ReceiptPrinterService.instance.shareXReport(_status!),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildShiftActionCard(
                    context: context,
                    icon: Icons.lock_clock_rounded,
                    iconColor: primaryColor,
                    iconBg: primaryColor.withValues(alpha: 0.12),
                    borderColor: primaryColor.withValues(alpha: 0.3),
                    title: 'Tutup Shift & Rekonsiliasi Kasir',
                    subtitle: 'Hitung uang fisik di laci kasir & cetak laporan Z-Report',
                    onTap: () {
                      Navigator.pop(ctx);
                      AudioHelper.actionFeedback();
                      ShiftDialogs.showCloseShiftDialog(
                        context,
                        _status!,
                        onClosed: () {
                          _refreshStatus();
                          widget.onShiftChanged?.call();
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
  }

  Widget _buildShiftActionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? borderColor,
  }) {
    final p = context.palette;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor ?? p.line, width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: p.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: p.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: p.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: p.surfaceMuted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.line),
        ),
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
        ),
      );
    }

    final isOpen = _status?.isOpen ?? false;
    final isMobile = context.isMobile;

    return InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: isMobile ? 5 : 7),
        decoration: BoxDecoration(
          color: isOpen ? p.surfaceMuted : p.canvas,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOpen ? p.tertiary.withValues(alpha: 0.4) : p.secondary,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOpen ? p.tertiary : p.secondary,
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                isOpen
                    ? (isMobile ? 'Shift' : 'Shift • ${_status?.cashierName ?? 'Kasir'}')
                    : (isMobile ? 'Buka' : 'Buka Shift'),
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w700,
                  color: isOpen ? p.textPrimary : primaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: p.textSecondary),
          ],
        ),
      ),
    );
  }
}
