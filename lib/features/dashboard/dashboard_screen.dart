import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/config/business_vertical.dart';
import '../../core/design/components.dart';
import '../../core/design/tokens.dart';
import '../../core/design/trend_chart.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/audio_helper.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/store_logo_avatar.dart';
import '../shared_pos/printer_settings_modal.dart';
import '../shared_pos/sales_history_drawer.dart';
import '../shared_pos/shift_modal.dart';
import '../shared_pos/shift_service.dart';
import 'dashboard_cubit.dart';
import 'dashboard_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DashboardCubit()..load(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh(BuildContext context) async {
    if (_isRefreshing) return;
    AudioHelper.actionFeedback();
    setState(() => _isRefreshing = true);
    try {
      await context.read<DashboardCubit>().load();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DashboardCubit>();
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: p.canvas,
      appBar: (!isWide || canPop)
          ? AppBar(
              title: const Text(
                'Dashboard Penjualan',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              centerTitle: false,
              actions: [
                IconButton(
                  tooltip: 'Muat Ulang Data',
                  onPressed: _isRefreshing ? null : () => _handleRefresh(context),
                  icon: _isRefreshing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          return RefreshIndicator(
            color: primaryColor,
            onRefresh: () => cubit.load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                isWide ? Gap.xl : Gap.md,
                isWide ? Gap.md : Gap.xs,
                isWide ? Gap.xl : Gap.md,
                Gap.xxl,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Header Card (Store / Outlet / Kasir & Live Status)
                        _DashboardHeaderCard(
                          isRefreshing: _isRefreshing,
                          onRefresh: () => _handleRefresh(context),
                        ),

                        const SizedBox(height: Gap.md),

                        // 2. Filter Rentang Waktu (Hari ini, 7 Hari, 30 Hari)
                        _RangePicker(
                          selected: state.range,
                          onChanged: (r) {
                            AudioHelper.tapFeedback();
                            cubit.load(r);
                          },
                        ),

                        const SizedBox(height: Gap.md),

                        // 3. Content State
                        switch (state) {
                          DashboardLoading() => const Padding(
                              padding: EdgeInsets.only(top: Gap.lg),
                              child: SkeletonList(count: 4, itemHeight: 96),
                            ),
                          DashboardFailed(:final message) => Padding(
                              padding: const EdgeInsets.only(top: Gap.xl),
                              child: ErrorState(
                                message: message,
                                onRetry: () => cubit.load(),
                              ),
                            ),
                          DashboardLoaded(:final summary) => _SummaryView(
                              summary: summary,
                              range: state.range,
                              isWide: isWide,
                            ),
                        },
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Header Kartu Informasi Toko, Lokasi, dan Status Kasir
class _DashboardHeaderCard extends StatelessWidget {
  final bool isRefreshing;
  final VoidCallback onRefresh;

  const _DashboardHeaderCard({
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final tenant = SessionStorage.instance.getTenantName() ??
        SessionStorage.instance.getLocationName() ??
        'Ringkasan Penjualan';
    final location = SessionStorage.instance.getLocationName() ?? 'Outlet Utama';
    final cashier = SessionStorage.instance.getUserName() ?? 'Kasir';
    final role = SessionStorage.instance.getUserRole() ?? 'Kasir';

    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          StoreLogoAvatar(
            size: 46,
            vertical: BusinessVertical.fnb,
            brandColor: primaryColor,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        tenant,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: p.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        location,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$dateStr • $cashier ($role)',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: p.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Sinkronkan / Refresh Data',
            onPressed: isRefreshing ? null : onRefresh,
            icon: isRefreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: primaryColor.withValues(alpha: 0.08),
              foregroundColor: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Selector Rentang Waktu dengan Desain Segmented Pills Modern
class _RangePicker extends StatelessWidget {
  const _RangePicker({required this.selected, required this.onChanged});

  final DashboardRange selected;
  final ValueChanged<DashboardRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: p.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.line),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (final r in DashboardRange.values)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(r),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected == r ? p.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: selected == r
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _iconForRange(r),
                        size: 14,
                        color: selected == r ? primaryColor : p.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        r.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected == r ? FontWeight.w800 : FontWeight.w600,
                          color: selected == r ? p.textPrimary : p.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static IconData _iconForRange(DashboardRange r) => switch (r) {
        DashboardRange.today => Icons.today_rounded,
        DashboardRange.week => Icons.date_range_rounded,
        DashboardRange.month => Icons.calendar_month_rounded,
      };
}

/// Tampilan Rincian Summary Dashboard yang Komprehensif
class _SummaryView extends StatelessWidget {
  final DashboardSummary summary;
  final DashboardRange range;
  final bool isWide;

  const _SummaryView({
    required this.summary,
    required this.range,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final growth = summary.growthPercent;
    final aov = summary.calculatedAov;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Grid 4 KPI Metrik Utama
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final use4Cols = w >= 680;

            if (use4Cols) {
              return Row(
                children: [
                  Expanded(
                    child: _KpiCard(
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
                    child: _KpiCard(
                      label: 'TOTAL TRANSAKSI',
                      value: NumberFormat.decimalPattern('id_ID').format(summary.transactions),
                      icon: Icons.receipt_long_rounded,
                      color: const Color(0xFF6366F1),
                      caption: '${summary.transactions} nota berhasil',
                    ),
                  ),
                  const SizedBox(width: Gap.sm),
                  Expanded(
                    child: _KpiCard(
                      label: 'RATA-RATA ORDER',
                      value: CurrencyFormatter.format(aov),
                      icon: Icons.trending_up_rounded,
                      color: const Color(0xFFF59E0B),
                      caption: 'Nilai per struk',
                    ),
                  ),
                  const SizedBox(width: Gap.sm),
                  Expanded(
                    child: _KpiCard(
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

            // Mobile (2x2 Grid)
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _KpiCard(
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
                      child: _KpiCard(
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
                      child: _KpiCard(
                        label: 'RATA-RATA / STRUK',
                        value: CurrencyFormatter.format(aov),
                        icon: Icons.trending_up_rounded,
                        color: const Color(0xFFF59E0B),
                        caption: 'AOV rata-rata',
                      ),
                    ),
                    const SizedBox(width: Gap.sm),
                    Expanded(
                      child: _KpiCard(
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
        ),

        const SizedBox(height: Gap.lg),

        // 2. Breakdown Metode Pembayaran (Tunai, QRIS, Kartu, Transfer)
        _PaymentBreakdownCard(summary: summary),

        const SizedBox(height: Gap.lg),

        // 3. Status Pesanan Hari Ini (Khusus FnB / POS)
        if (summary.statusBreakdown.isNotEmpty) ...[
          _OrderStatusSection(statusBreakdown: summary.statusBreakdown),
          const SizedBox(height: Gap.lg),
        ],

        // 4. Tren Penjualan
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

        // 5. Penjualan per Cabang (Jika ada cabang lain)
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
        _QuickActionsCard(),
      ],
    );
  }
}

/// Kartu Metrik KPI Modern dengan Icon Tinted & High-Contrast Typography
class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? caption;
  final Color? captionColor;

  const _KpiCard({
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

/// Rincian Penerimaan berdasarkan Metode Pembayaran
class _PaymentBreakdownCard extends StatelessWidget {
  final DashboardSummary summary;

  const _PaymentBreakdownCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final cash = summary.cashTotal;
    final qris = summary.qrisTotal;
    final debit = summary.debitTotal;
    final transfer = summary.transferTotal;
    final other = summary.otherTotal;
    final total = cash + qris + debit + transfer + other;

    final effectiveTotal = total > 0 ? total : (summary.revenue > 0 ? summary.revenue : 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_rounded, size: 18, color: p.textPrimary),
              const SizedBox(width: 8),
              Text(
                'Metode Pembayaran Masuk',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Total: ${CurrencyFormatter.format(total > 0 ? total : summary.revenue)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: p.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Multi-Segment Proportion Bar
          if (total > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    if (cash > 0)
                      Expanded(
                        flex: ((cash / effectiveTotal) * 100).round().clamp(1, 100),
                        child: Container(color: const Color(0xFF10B981)),
                      ),
                    if (qris > 0)
                      Expanded(
                        flex: ((qris / effectiveTotal) * 100).round().clamp(1, 100),
                        child: Container(color: const Color(0xFF6366F1)),
                      ),
                    if (debit > 0)
                      Expanded(
                        flex: ((debit / effectiveTotal) * 100).round().clamp(1, 100),
                        child: Container(color: const Color(0xFFF59E0B)),
                      ),
                    if (transfer > 0)
                      Expanded(
                        flex: ((transfer / effectiveTotal) * 100).round().clamp(1, 100),
                        child: Container(color: const Color(0xFF0EA5E9)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 4 Channels Grid
          Row(
            children: [
              Expanded(
                child: _PaymentItem(
                  label: 'Tunai',
                  amount: cash,
                  color: const Color(0xFF10B981),
                  icon: Icons.money_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PaymentItem(
                  label: 'QRIS',
                  amount: qris,
                  color: const Color(0xFF6366F1),
                  icon: Icons.qr_code_2_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PaymentItem(
                  label: 'Kartu/EDC',
                  amount: debit,
                  color: const Color(0xFFF59E0B),
                  icon: Icons.credit_card_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PaymentItem(
                  label: 'Transfer',
                  amount: transfer,
                  color: const Color(0xFF0EA5E9),
                  icon: Icons.account_balance_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _PaymentItem({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: p.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              CurrencyFormatter.format(amount),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: p.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status Pesanan FnB (Menunggu, Diproses, Siap, Selesai)
class _OrderStatusSection extends StatelessWidget {
  final Map<String, int> statusBreakdown;

  const _OrderStatusSection({required this.statusBreakdown});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final pending = statusBreakdown['pending'] ?? 0;
    final preparing = statusBreakdown['preparing'] ?? 0;
    final ready = statusBreakdown['ready'] ?? 0;
    final completed = (statusBreakdown['completed'] ?? 0) + (statusBreakdown['served'] ?? 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.soup_kitchen_rounded, size: 18, color: p.textPrimary),
              const SizedBox(width: 8),
              Text(
                'Status Pesanan Dapur Hari Ini',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatusBadgeItem(
                  title: 'Menunggu',
                  count: pending,
                  icon: Icons.hourglass_top_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusBadgeItem(
                  title: 'Diproses',
                  count: preparing,
                  icon: Icons.skateboarding_rounded,
                  color: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusBadgeItem(
                  title: 'Siap Saji',
                  count: ready,
                  icon: Icons.notifications_active_rounded,
                  color: const Color(0xFF0EA5E9),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusBadgeItem(
                  title: 'Selesai',
                  count: completed,
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadgeItem extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _StatusBadgeItem({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: p.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aksi Cepat Kasir: Buka Kasir, Riwayat Penjualan, Laporan Shift, Petty Cash, Printer
class _QuickActionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

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
      },
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
