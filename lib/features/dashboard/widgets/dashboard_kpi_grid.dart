import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/design/tokens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../dashboard_service.dart';

/// Grid 4 Metrik KPI Utama (Omzet, Transaksi, Rata-rata Order, Laba Bersih)
class DashboardKpiGrid extends StatelessWidget {
  final DashboardSummary summary;

  const DashboardKpiGrid({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final growth = summary.growthPercent;
    final aov = summary.calculatedAov;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final use4Cols = w >= 680;

        if (use4Cols) {
          return Row(
            children: [
              Expanded(
                child: DashboardKpiCard(
                  label: 'TOTAL OMZET',
                  value: CurrencyFormatter.format(summary.revenue),
                  icon: Icons.payments_rounded,
                  color: const Color(0xFF10B981),
                  caption: growth != null
                      ? '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}% vs lalu'
                      : 'Pendapatan kotor',
                  captionColor: growth != null
                      ? (growth >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                      : null,
                ),
              ),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: DashboardKpiCard(
                  label: 'TOTAL TRANSAKSI',
                  value: NumberFormat.decimalPattern('id_ID').format(summary.transactions),
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFF6366F1),
                  caption: '${summary.transactions} nota berhasil',
                ),
              ),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: DashboardKpiCard(
                  label: 'RATA-RATA ORDER',
                  value: CurrencyFormatter.format(aov),
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFFF59E0B),
                  caption: 'Nilai per struk',
                ),
              ),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: DashboardKpiCard(
                  label: 'LABA BERSIH',
                  value: CurrencyFormatter.format(
                    summary.netProfit ?? (summary.revenue - (summary.expenses ?? 0)),
                  ),
                  icon: Icons.account_balance_wallet_rounded,
                  color: const Color(0xFF0EA5E9),
                  caption: summary.expenses != null && summary.expenses! > 0
                      ? 'Beban ${CurrencyFormatter.format(summary.expenses)}'
                      : 'Estimasi kas operasional',
                ),
              ),
            ],
          );
        }

        // Tampilan Mobile (2x2 Grid)
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DashboardKpiCard(
                    label: 'TOTAL OMZET',
                    value: CurrencyFormatter.format(summary.revenue),
                    icon: Icons.payments_rounded,
                    color: const Color(0xFF10B981),
                    caption: growth != null
                        ? '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}%'
                        : 'Omzet kotor',
                    captionColor: growth != null
                        ? (growth >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                        : null,
                  ),
                ),
                const SizedBox(width: Gap.sm),
                Expanded(
                  child: DashboardKpiCard(
                    label: 'TRANSAKSI',
                    value: NumberFormat.decimalPattern('id_ID').format(summary.transactions),
                    icon: Icons.receipt_long_rounded,
                    color: const Color(0xFF6366F1),
                    caption: '${summary.transactions} nota selesai',
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.sm),
            Row(
              children: [
                Expanded(
                  child: DashboardKpiCard(
                    label: 'RATA-RATA / STRUK',
                    value: CurrencyFormatter.format(aov),
                    icon: Icons.trending_up_rounded,
                    color: const Color(0xFFF59E0B),
                    caption: 'AOV rata-rata',
                  ),
                ),
                const SizedBox(width: Gap.sm),
                Expanded(
                  child: DashboardKpiCard(
                    label: 'LABA BERSIH',
                    value: CurrencyFormatter.format(
                      summary.netProfit ?? (summary.revenue - (summary.expenses ?? 0)),
                    ),
                    icon: Icons.account_balance_wallet_rounded,
                    color: const Color(0xFF0EA5E9),
                    caption: summary.expenses != null && summary.expenses! > 0
                        ? 'Biaya: ${CurrencyFormatter.format(summary.expenses)}'
                        : 'Estimasi kas bersih',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Kartu Metrik KPI Satuan dengan Icon Tinted & Desain High-Contrast
class DashboardKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? caption;
  final Color? captionColor;

  const DashboardKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.caption,
    this.captionColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: p.textSecondary,
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: p.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: captionColor ?? p.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
