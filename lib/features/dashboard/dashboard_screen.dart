import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/design/components.dart';
import '../../core/design/tokens.dart';
import '../../core/utils/audio_helper.dart';
import 'dashboard_cubit.dart';
import 'widgets/dashboard_header_card.dart';
import 'widgets/dashboard_range_picker.dart';
import 'widgets/dashboard_summary_view.dart';

/// Halaman Dashboard Utama Kasir & Penjualan Toko
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
                        DashboardHeaderCard(
                          isRefreshing: _isRefreshing,
                          onRefresh: () => _handleRefresh(context),
                        ),

                        const SizedBox(height: Gap.md),

                        // 2. Filter Rentang Waktu (Hari ini, 7 Hari, 30 Hari)
                        DashboardRangePicker(
                          selected: state.range,
                          onChanged: (r) {
                            AudioHelper.tapFeedback();
                            cubit.load(r);
                          },
                        ),

                        const SizedBox(height: Gap.md),

                        // 3. Status Data (Loading, Error, Loaded)
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
                          DashboardLoaded(:final summary) => DashboardSummaryView(
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
