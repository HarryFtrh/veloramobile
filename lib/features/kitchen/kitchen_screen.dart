import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/design/tokens.dart';
import '../../core/storage/session_storage.dart';
import '../shared_pos/services/receipt_printer_service.dart';
import 'kitchen_cubit.dart';
import 'kitchen_service.dart';
import 'widgets/kitchen_ticket_card.dart';

class KitchenScreen extends StatelessWidget {
  const KitchenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => KitchenCubit()..start(),
      child: const _KitchenView(),
    );
  }
}

class _KitchenView extends StatelessWidget {
  const _KitchenView();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isWide = MediaQuery.sizeOf(context).width >= 600;
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: p.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (!isWide || canPop)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
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
                          Row(
                            children: [
                              Text(
                                'Dapur',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: p.textPrimary,
                                  letterSpacing: -0.6,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: p.success.withValues(
                                    alpha: isDark ? 0.20 : 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: p.success,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'LIVE KDS',
                                      style: TextStyle(
                                        color: p.success,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${SessionStorage.instance.getLocationName() ?? "Outlet"} • Antrean Bar & Dapur',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: p.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    BlocBuilder<KitchenCubit, KitchenState>(
                      builder: (context, state) {
                        final isSoundOn =
                            state is KitchenLoaded ? state.soundEnabled : true;
                        return Tooltip(
                          message: isSoundOn
                              ? 'Notifikasi Suara Aktif'
                              : 'Notifikasi Suara Senyap',
                          child: Material(
                            color: isSoundOn
                                ? primaryColor.withValues(alpha: isDark ? 0.22 : 0.12)
                                : p.surface,
                            shape: CircleBorder(
                              side: BorderSide(
                                color: isSoundOn
                                    ? primaryColor.withValues(alpha: 0.28)
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : p.line.withValues(alpha: 0.55)),
                              ),
                            ),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                context.read<KitchenCubit>().toggleSound();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isSoundOn
                                          ? '🔇 Notifikasi suara KDS dimatikan'
                                          : '🔔 Notifikasi suara pesanan KDS diaktifkan',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: Icon(
                                  isSoundOn
                                      ? Icons.volume_up_rounded
                                      : Icons.volume_off_rounded,
                                  color: isSoundOn
                                      ? primaryColor
                                      : p.textSecondary,
                                  size: 19,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Muat Ulang Antrean',
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
                          onTap: () => context
                              .read<KitchenCubit>()
                              .refresh(silent: false),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.refresh_rounded,
                              color: p.textPrimary,
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: BlocConsumer<KitchenCubit, KitchenState>(
        listenWhen: (_, s) => s is KitchenLoaded && s.actionError != null,
        listener: (context, s) {
          final msg = (s as KitchenLoaded).actionError!;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(msg)));
        },
        builder: (context, state) => switch (state) {
          KitchenLoading() => VeloraOrbitLoader.page(
              color: primaryColor,
              label: 'Memuat antrean dapur...',
            ),
          KitchenFailed(:final message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: p.danger.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.cloud_off_rounded, size: 44, color: p.danger),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Gagal Memuat Antrean Dapur',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: p.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: p.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.read<KitchenCubit>().refresh(silent: false),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          KitchenLoaded() => _Board(state: state, isWide: isWide, canPop: canPop),
        },
      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({
    required this.state,
    required this.isWide,
    required this.canPop,
  });

  final KitchenLoaded state;
  final bool isWide;
  final bool canPop;

  static const _stages = [
    (KitchenStage.fresh, 'Pesanan Baru / New', 'Mulai Seduh / Start'),
    (KitchenStage.preparing, 'Sedang Diracik / In Preparation', 'Tandai Siap / Ready'),
    (KitchenStage.ready, 'Siap Diantar / Ready to Serve', 'Selesai / Saji (Dismiss)'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cubit = context.read<KitchenCubit>();
    final allOrders = state.orders;

    final delayedOrders = state.delayedCount;
    final avgMins = state.avgWaitMinutes;
    final avgLabel = allOrders.isEmpty ? '-' : '${avgMins.toStringAsFixed(1)} Menit';

    // Total hitungan tiket per kategori untuk filter chip
    final allStations = state.stations;

    return Column(
      children: [
        // Dedicated Wide Screen Header (saat mode KDS layar penuh tanpa AppBar bawaan)
        if (isWide && !canPop)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: p.surface,
              border: Border(bottom: BorderSide(color: p.line)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.soup_kitchen_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              SessionStorage.instance.getTenantName() ??
                                  SessionStorage.instance.getLocationName() ??
                                  'Kitchen Display System',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: p.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, size: 6, color: Color(0xFF059669)),
                                SizedBox(width: 4),
                                Text(
                                  'LIVE REALTIME KDS',
                                  style: TextStyle(
                                    color: Color(0xFF059669),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${SessionStorage.instance.getLocationName() ?? "Outlet Utama"} • Antrean Pesanan Dapur & Barista Terhubung',
                        style: TextStyle(fontSize: 11, color: p.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Audio Mute/Unmute
                IconButton(
                  tooltip: state.soundEnabled ? 'Matikan Notifikasi Suara' : 'Aktifkan Notifikasi Suara',
                  icon: Icon(
                    state.soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    color: state.soundEnabled ? primaryColor : p.textSecondary,
                    size: 22,
                  ),
                  onPressed: () {
                    cubit.toggleSound();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.soundEnabled
                            ? '🔇 Notifikasi suara dimatikan'
                            : '🔔 Notifikasi suara pesanan baru diaktifkan'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),

                // Refresh Antrean
                OutlinedButton.icon(
                  onPressed: () => cubit.refresh(silent: false),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Segarkan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: p.textPrimary,
                    side: BorderSide(color: p.line),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
          ),

        // Header Metric Banners
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: p.surface,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 130),
                  child: _buildMetricCard(
                    context: context,
                    icon: Icons.receipt_long_rounded,
                    label: 'TOTAL ANTREAN',
                    value: '${allOrders.length} Tiket',
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 130),
                  child: _buildMetricCard(
                    context: context,
                    icon: Icons.soup_kitchen_outlined,
                    label: 'SEDANG DIRACIK',
                    value: '${state.countByStage(KitchenStage.preparing)} Tiket',
                    color: const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 130),
                  child: _buildMetricCard(
                    context: context,
                    icon: Icons.check_circle_outline_rounded,
                    label: 'SIAP DISAJIKAN',
                    value: '${state.countByStage(KitchenStage.ready)} Tiket',
                    color: const Color(0xFF059669),
                  ),
                ),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 140),
                  child: _buildMetricCard(
                    context: context,
                    icon: Icons.timer_outlined,
                    label: 'RATA-RATA SEDUH',
                    value: avgLabel,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 160),
                  child: _buildMetricCard(
                    context: context,
                    icon: Icons.warning_amber_rounded,
                    label: 'MELEBIHI TARGET (>7m)',
                    value: '$delayedOrders Tiket',
                    color: delayedOrders > 0 ? p.danger : p.textSecondary,
                    isAlert: delayedOrders > 0,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Station / Kategori Filters
        Container(
          height: 48,
          color: p.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Builder(
            builder: (context) {
              final stationCounts = <String, int>{};
              for (final order in allOrders) {
                final seen = <String>{};
                for (final item in order.items) {
                  final st = item.station;
                  if (st.isNotEmpty && seen.add(st)) {
                    stationCounts[st] = (stationCounts[st] ?? 0) + 1;
                  }
                }
              }
              return ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildStationChip(
                    context,
                    'Semua Station',
                    allOrders.length,
                    state.station == null,
                    () => cubit.filterStation(null),
                  ),
                  for (final s in allStations)
                    _buildStationChip(
                      context,
                      s,
                      stationCounts[s] ?? 0,
                      state.station == s,
                      () => cubit.filterStation(s),
                    ),
                ],
              );
            },
          ),
        ),
        Divider(height: 1, color: p.line),

        // Kanban Board Columns
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < AppBreakpoints.mobile || constraints.maxHeight < AppBreakpoints.compactHeight;
              final isWideLayout = !isMobile;
              final columns = [
                for (final (stage, title, action) in _stages)
                  _KanbanColumn(
                    title: title,
                    actionLabel: action,
                    orders: state.byStage(stage),
                    station: state.station,
                    stage: stage,
                  ),
              ];

              if (isWideLayout) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final col in columns)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: col,
                          ),
                        ),
                    ],
                  ),
                );
              }

              // Mobile Tabs
              return DefaultTabController(
                length: columns.length,
                child: Column(
                  children: [
                    TabBar(
                      indicatorColor: primaryColor,
                      labelColor: primaryColor,
                      unselectedLabelColor: p.textSecondary,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                      tabs: [
                        for (final s in _stages)
                          Tab(text: '${s.$2.split(" / ")[0]} (${state.byStage(s.$1).length})'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: columns.map((c) => Padding(padding: const EdgeInsets.all(10), child: c)).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Footer Station & Hardware Status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border(top: BorderSide(color: p.line)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.wifi_tethering_rounded, size: 14, color: Color(0xFF059669)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'KDS Live Sync Terhubung • Auto-refresh 6 detik',
                        style: TextStyle(fontSize: 11, color: p.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => ReceiptPrinterService.instance.openSettings(context),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.print_outlined, size: 14, color: Color(0xFF059669)),
                      SizedBox(width: 4),
                      Text(
                        'Printer Thermal Dapur [Siap]',
                        style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isAlert = false,
  }) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isAlert ? p.danger.withValues(alpha: 0.1) : p.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: isAlert ? Border.all(color: p.danger.withValues(alpha: 0.3)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.3)),
              Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: isAlert ? p.danger : p.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStationChip(
    BuildContext context,
    String label,
    int count,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: primaryColor,
        backgroundColor: p.surfaceMuted,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : p.textPrimary,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          fontSize: 11.5,
        ),
        shape: const StadiumBorder(),
        side: BorderSide(color: isSelected ? Colors.transparent : p.line),
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({
    required this.title,
    required this.actionLabel,
    required this.orders,
    required this.station,
    required this.stage,
  });

  final String title;
  final String actionLabel;
  final List<KitchenOrder> orders;
  final String? station;
  final KitchenStage stage;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (tintColor, dotColor, badgeBg) = switch (stage) {
      KitchenStage.fresh => (p.surfaceMuted.withValues(alpha: 0.5), p.textSecondary, p.surface),
      KitchenStage.preparing => (const Color(0xFFD97706).withValues(alpha: 0.14), const Color(0xFFD97706), const Color(0xFFD97706).withValues(alpha: 0.14)),
      KitchenStage.ready => (const Color(0xFF059669).withValues(alpha: 0.14), const Color(0xFF059669), const Color(0xFFD1FAE5)),
    };

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tintColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: p.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  '${orders.length} Tiket',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10.5, color: dotColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 32,
                          color: p.textSecondary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tidak ada tiket',
                          style: TextStyle(color: p.textSecondary.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => KitchenTicketCard(
                      order: orders[i],
                      actionLabel: actionLabel,
                      station: station,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
