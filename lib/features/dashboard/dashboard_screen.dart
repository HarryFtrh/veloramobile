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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: p.canvas,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            return RefreshIndicator(
              color: primaryColor,
              onRefresh: () => cubit.load(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  isWide ? Gap.xl : 16,
                  isWide ? Gap.md : 12,
                  isWide ? Gap.xl : 16,
                  Gap.xxl,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!isWide || canPop) ...[
                            Row(
                              children: [
                                if (canPop) ...[
                                  Material(
                                    color: p.surface,
                                    shape: CircleBorder(
                                      side: BorderSide(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.08)
                                            : p.line.withValues(alpha: 0.55),
                                      ),
                                    ),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: () => Navigator.of(context).pop(),
                                      child: SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: Icon(
                                          Icons.chevron_left_rounded,
                                          size: 22,
                                          color: p.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Dashboard',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: p.textPrimary,
                                          letterSpacing: -0.6,
                                          height: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Ringkasan penjualan & performa outlet',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: p.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Tooltip(
                                  message: 'Muat Ulang Data',
                                  child: Material(
                                    color: p.surface,
                                    shape: CircleBorder(
                                      side: BorderSide(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.08)
                                            : p.line.withValues(alpha: 0.55),
                                      ),
                                    ),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: _isRefreshing ? null : () => _handleRefresh(context),
                                      child: SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: Center(
                                          child: _isRefreshing
                                              ? VeloraOrbitLoader.inline(
                                                  size: 18,
                                                  color: primaryColor,
                                                )
                                              : Icon(
                                                  Icons.refresh_rounded,
                                                  size: 19,
                                                  color: p.textPrimary,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

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
      ),
    );
  }
}
