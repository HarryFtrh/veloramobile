import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/audio_helper.dart';
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 560),
          child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: WarmPalette.canvas,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: WarmPalette.line, width: 1.5)),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: WarmPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Modal Awal: ${CurrencyFormatter.format(_status?.startingCash ?? 0)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: WarmPalette.tertiary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: WarmPalette.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildShiftActionCard(
                    context: context,
                    icon: Icons.arrow_downward_rounded,
                    iconColor: WarmPalette.tertiary,
                    iconBg: WarmPalette.tertiary.withValues(alpha: 0.12),
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
                    iconColor: WarmPalette.danger,
                    iconBg: WarmPalette.danger.withValues(alpha: 0.12),
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
                  const SizedBox(height: 14),
                  _buildShiftActionCard(
                    context: context,
                    icon: Icons.lock_clock_rounded,
                    iconColor: WarmPalette.primary,
                    iconBg: WarmPalette.primary.withValues(alpha: 0.12),
                    borderColor: WarmPalette.primary.withValues(alpha: 0.3),
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
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor ?? WarmPalette.line, width: 1.2),
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
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: WarmPalette.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: WarmPalette.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: WarmPalette.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: WarmPalette.surfaceMuted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: WarmPalette.line),
        ),
        child: const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: WarmPalette.primary),
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
          color: isOpen ? WarmPalette.surfaceMuted : WarmPalette.canvas,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOpen ? WarmPalette.tertiary.withValues(alpha: 0.4) : WarmPalette.secondary,
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
                color: isOpen ? WarmPalette.tertiary : WarmPalette.secondary,
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
                  color: isOpen ? WarmPalette.textPrimary : WarmPalette.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: WarmPalette.textSecondary),
          ],
        ),
      ),
    );
  }
}
