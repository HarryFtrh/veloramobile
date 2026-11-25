import 'package:material_ui/material_ui.dart';

import '../../../core/design/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/trend_chart.dart';
import '../../../core/utils/currency_formatter.dart';
import '../dashboard_cubit.dart';
import '../dashboard_service.dart';
import 'dashboard_kpi_grid.dart';
import 'dashboard_order_status_section.dart';
import 'dashboard_payment_breakdown.dart';
import 'dashboard_quick_actions_card.dart';

/// Tampilan Rincian Summary Dashboard yang Menggabungkan Semua Komponen Modular
class DashboardSummaryView extends StatelessWidget {
  final DashboardSummary summary;
  final DashboardRange range;
  final bool isWide;

  const DashboardSummaryView({
    super.key,
    required this.summary,
    required this.range,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Grid 4 KPI Metrik Utama (Omzet, Transaksi, Rata-rata Order, Laba Bersih)
        DashboardKpiGrid(summary: summary),

        const SizedBox(height: Gap.lg),

        // 2. Breakdown Metode Pembayaran (Tunai, QRIS, Kartu, Transfer)
        DashboardPaymentBreakdownCard(summary: summary),

        const SizedBox(height: Gap.lg),

        // 3. Status Pesanan Hari Ini (Khusus FnB / POS)
        if (summary.statusBreakdown.isNotEmpty) ...[
          DashboardOrderStatusSection(statusBreakdown: summary.statusBreakdown),
          const SizedBox(height: Gap.lg),
        ],

        // 4. Tren Penjualan Harian
        if (summary.dailyTrend.length > 1) ...[
          const SectionHeader(title: 'Tren Penjualan Harian'),
          const SizedBox(height: Gap.xs),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Riwayat Omzet',
                      style: text.bodySmall?.copyWith(color: p.textSecondary, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Puncak: ${CurrencyFormatter.format(summary.dailyTrend.reduce((a, b) => a > b ? a : b))}',
                      style: text.bodySmall?.copyWith(color: p.textPrimary, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: Gap.sm),
                TrendChart(values: summary.dailyTrend, height: 130),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
        ],

        // 5. Penjualan per Cabang (Jika multi-outlet)
        if (summary.branches.length > 1) ...[
          const SectionHeader(title: 'Penjualan per Cabang'),
          const SizedBox(height: Gap.xs),
          AppCard(
            child: Column(
              children: [
                for (final b in summary.branches)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Gap.xs),
                    child: Row(
                      children: [
                        Icon(Icons.storefront_outlined, size: 16, color: p.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            b.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(b.total),
                          style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
        ],

        // 6. Aksi Cepat Kasir & Bisnis (Quick Shortcuts)
        const SectionHeader(title: 'Aksi Cepat Kasir'),
        const SizedBox(height: Gap.xs),
        const DashboardQuickActionsCard(),
      ],
    );
  }
}
