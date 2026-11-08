import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/tokens.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/utils/audio_helper.dart';
import '../../shared_pos/printer_settings_modal.dart';
import '../../shared_pos/sales_history_drawer.dart';
import '../../shared_pos/shift_modal.dart';
import '../../shared_pos/shift_service.dart';
import '../dashboard_cubit.dart';

/// Aksi Cepat Kasir: Buka Kasir, Riwayat Penjualan, Laporan Shift, Petty Cash, Printer
class DashboardQuickActionsCard extends StatelessWidget {
  const DashboardQuickActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _ActionButton(
            label: 'Riwayat Struk',
            icon: Icons.history_rounded,
            color: const Color(0xFF6366F1),
            onTap: () {
              AudioHelper.tapFeedback();
              SalesHistoryDrawer.show(
                context,
                storeName: SessionStorage.instance.getTenantName() ?? 'Kasir POS',
                storeAddress: SessionStorage.instance.getStoreAddress() ?? '',
                storePhone: SessionStorage.instance.getStorePhone() ?? '-',
                cashierName: SessionStorage.instance.getUserName() ?? 'Kasir',
                accentColor: primaryColor,
              );
            },
          ),
          _ActionButton(
            label: 'Laporan Shift',
            icon: Icons.assessment_rounded,
            color: const Color(0xFF10B981),
            onTap: () {
              AudioHelper.tapFeedback();
              final lastSummary = ShiftService.instance.lastCloseSummary;
              if (lastSummary != null) {
                ShiftDialogs.showShiftReportDialog(
                  context,
                  lastSummary,
                  onDone: () {},
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Shift kasir saat ini masih aktif berjalan.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          _ActionButton(
            label: 'Kas Kecil (Petty Cash)',
            icon: Icons.payments_outlined,
            color: const Color(0xFFF59E0B),
            onTap: () {
              AudioHelper.tapFeedback();
              ShiftDialogs.showPettyCashDialog(
                context,
                type: 'out',
                onSuccess: () {
                  context.read<DashboardCubit>().load();
                },
              );
            },
          ),
          _ActionButton(
            label: 'Pengaturan Printer',
            icon: Icons.print_rounded,
            color: const Color(0xFF0EA5E9),
            onTap: () {
              AudioHelper.tapFeedback();
              PrinterSettingsModal.show(context);
            },
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
