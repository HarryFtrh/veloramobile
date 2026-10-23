import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/design/components.dart';
import '../../core/design/tokens.dart';
import '../../core/design/trend_chart.dart';
import '../../core/utils/currency_formatter.dart';
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

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DashboardCubit>();
    final isWide = MediaQuery.sizeOf(context).width >= 600;
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return Scaffold(
      appBar: (!isWide || canPop) ? AppBar(title: const Text('Ringkasan')) : null,
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          return Column(
            children: [
              _RangePicker(selected: state.range, onChanged: cubit.load),
              Expanded(
                child: switch (state) {
                  DashboardLoading() => const SkeletonList(count: 4, itemHeight: 96),
                  DashboardFailed(:final message) =>
                    ErrorState(message: message, onRetry: cubit.load),
                  DashboardLoaded(:final summary) => RefreshIndicator(
                      onRefresh: cubit.load,
                      child: _SummaryList(summary: summary),
                    ),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RangePicker extends StatelessWidget {
  const _RangePicker({required this.selected, required this.onChanged});

  final DashboardRange selected;
  final ValueChanged<DashboardRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.xs, Gap.lg, Gap.sm),
      child: SegmentedButton<DashboardRange>(
        showSelectedIcon: false,
        segments: [
          for (final r in DashboardRange.values)
            ButtonSegment(value: r, label: Text(r.label)),
        ],
        selected: {selected},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}

class _SummaryList extends StatelessWidget {
  const _SummaryList({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final growth = summary.growthPercent;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(isWide ? Gap.xl : Gap.lg, 0, isWide ? Gap.xl : Gap.lg, Gap.xl),
              children: [
                if (isWide) ...[
                  // 4 Kolom Stat Tile di Tablet/Layar Lebar
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: StatTile(
                          label: 'Omzet',
                          value: CurrencyFormatter.format(summary.revenue),
                          caption: growth == null
                              ? null
                              : '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}% dari periode lalu',
                          captionColor: growth == null
                              ? null
                              : (growth >= 0 ? p.success : p.danger),
                        ),
                      ),
                      const SizedBox(width: Gap.md),
                      Expanded(
                        child: StatTile(
                          label: 'Transaksi',
                          value: NumberFormat.decimalPattern('id_ID').format(summary.transactions),
                        ),
                      ),
                      if (summary.averageDaily != null) ...[
                        const SizedBox(width: Gap.md),
                        Expanded(
                          child: StatTile(
                            label: 'Rata-rata harian',
                            value: CurrencyFormatter.format(summary.averageDaily),
                          ),
                        ),
                      ],
                      if (summary.netProfit != null) ...[
                        const SizedBox(width: Gap.md),
                        Expanded(
                          child: StatTile(
                            label: 'Laba bersih',
                            value: CurrencyFormatter.format(summary.netProfit),
                            caption: summary.expenses == null
                                ? null
                                : 'Biaya ${CurrencyFormatter.format(summary.expenses)}',
                          ),
                        ),
                      ],
                    ],
                  ),
                ] else ...[
                  // 2 Kolom Stat Tile di Mobile
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: StatTile(
                          label: 'Omzet',
                          value: CurrencyFormatter.format(summary.revenue),
                          caption: growth == null
                              ? null
                              : '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}% dari periode lalu',
                          captionColor: growth == null
                              ? null
                              : (growth >= 0 ? p.success : p.danger),
                        ),
                      ),
                      const SizedBox(width: Gap.md),
                      Expanded(
                        child: StatTile(
                          label: 'Transaksi',
                          value: NumberFormat.decimalPattern('id_ID').format(summary.transactions),
                        ),
                      ),
                    ],
                  ),
                  if (summary.netProfit != null || summary.averageDaily != null) ...[
                    const SizedBox(height: Gap.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (summary.averageDaily != null)
                          Expanded(
                            child: StatTile(
                              label: 'Rata-rata harian',
                              value: CurrencyFormatter.format(summary.averageDaily),
                            ),
                          ),
                        if (summary.averageDaily != null && summary.netProfit != null)
                          const SizedBox(width: Gap.md),
                        if (summary.netProfit != null)
                          Expanded(
                            child: StatTile(
                              label: 'Laba bersih',
                              value: CurrencyFormatter.format(summary.netProfit),
                              caption: summary.expenses == null
                                  ? null
                                  : 'Biaya ${CurrencyFormatter.format(summary.expenses)}',
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
                if (summary.dailyTrend.length > 1) ...[
                  const SizedBox(height: Gap.xl),
                  const SectionHeader(title: 'Tren penjualan'),
                  AppCard(child: TrendChart(values: summary.dailyTrend)),
                ],
                if (summary.statusBreakdown.isNotEmpty) ...[
                  const SizedBox(height: Gap.xl),
                  const SectionHeader(title: 'Status pesanan hari ini'),
                  AppCard(
                    child: Column(
                      children: [
                        for (final e in summary.statusBreakdown.entries)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: Gap.xs),
                            child: Row(
                              children: [
                                Expanded(child: Text(_statusLabel(e.key), style: text.bodyMedium)),
                                Text('${e.value}',
                                    style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                if (summary.branches.length > 1) ...[
                  const SizedBox(height: Gap.xl),
                  const SectionHeader(title: 'Penjualan per cabang'),
                  AppCard(
                    child: Column(
                      children: [
                        for (final b in summary.branches)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: Gap.xs),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(b.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: text.bodyMedium),
                                ),
                                Text(CurrencyFormatter.format(b.total),
                                    style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static String _statusLabel(String key) => switch (key) {
        'pending' => 'Menunggu',
        'preparing' => 'Diproses',
        'ready' => 'Siap',
        'served' => 'Disajikan',
        'completed' => 'Selesai',
        _ => key,
      };
}
