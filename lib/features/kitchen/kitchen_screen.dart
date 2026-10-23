import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/design/tokens.dart';
import '../../core/storage/session_storage.dart';
import 'kitchen_cubit.dart';
import 'kitchen_service.dart';
import 'kitchen_ticket_card.dart';

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
    final isWide = MediaQuery.sizeOf(context).width >= 600;
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return Scaffold(
      backgroundColor: WarmPalette.canvas,
      appBar: (!isWide || canPop) ? AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: WarmPalette.primary, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.coffee_maker_rounded, color: Colors.white, size: 20),
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
                          SessionStorage.instance.getTenantName() ?? SessionStorage.instance.getLocationName() ?? 'Kitchen Display',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: WarmPalette.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: WarmPalette.tertiary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 6, color: WarmPalette.tertiary),
                            SizedBox(width: 4),
                            Text('LIVE', style: TextStyle(color: WarmPalette.tertiary, fontSize: 9, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Barista & Kitchen Display (KDS)',
                    style: const TextStyle(fontSize: 11, color: WarmPalette.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: WarmPalette.textPrimary),
            onPressed: () => context.read<KitchenCubit>().refresh(silent: false),
          ),
          IconButton(
            icon: const Icon(Icons.volume_up_outlined, color: WarmPalette.textPrimary),
            onPressed: () {},
          ),
        ],
      ) : null,
      body: BlocConsumer<KitchenCubit, KitchenState>(
        listenWhen: (_, s) => s is KitchenLoaded && s.actionError != null,
        listener: (context, s) {
          final msg = (s as KitchenLoaded).actionError!;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(msg)));
        },
        builder: (context, state) => switch (state) {
          KitchenLoading() => const Center(child: CircularProgressIndicator(color: WarmPalette.primary)),
          KitchenFailed(:final message) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 48, color: WarmPalette.danger),
                  const SizedBox(height: 8),
                  Text(message, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<KitchenCubit>().refresh(silent: false),
                    style: ElevatedButton.styleFrom(backgroundColor: WarmPalette.primary, foregroundColor: Colors.white),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          KitchenLoaded() => _Board(state: state),
        },
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.state});
  final KitchenLoaded state;

  static const _stages = [
    (KitchenStage.fresh, 'Pesanan Baru / New', 'Mulai Seduh / Start'),
    (KitchenStage.preparing, 'Sedang Diracik / In Preparation', 'Tandai Siap / Ready'),
    (KitchenStage.ready, 'Siap Diantar / Ready to Serve', 'Selesai / Dismiss'),
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<KitchenCubit>();
    final allOrders = state.orders;
    final delayedOrders = allOrders.where((o) {
      final mins = DateTime.now().difference(o.createdAt).inMinutes;
      return o.stage != KitchenStage.ready && mins >= kLateAfterMinutes;
    }).length;

    final avgMins = allOrders.isEmpty
        ? 0.0
        : (allOrders
                .map((o) => DateTime.now().difference(o.createdAt).inSeconds / 60.0)
                .reduce((a, b) => a + b) /
            allOrders.length);
    final avgLabel = allOrders.isEmpty ? '-' : '${avgMins.toStringAsFixed(1)} Menit';

    return Column(
      children: [
        // Header Metric Banners
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 140),
                  child: _buildMetricCard(
                    icon: Icons.hourglass_top_rounded,
                    label: 'ANTREAN',
                    value: '${allOrders.length} Tiket',
                    color: WarmPalette.primary,
                  ),
                ),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 150),
                  child: _buildMetricCard(
                    icon: Icons.timer_outlined,
                    label: 'RATA-RATA SEDUH',
                    value: avgLabel,
                    color: WarmPalette.tertiary,
                  ),
                ),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 170),
                  child: _buildMetricCard(
                    icon: Icons.warning_amber_rounded,
                    label: 'MELEBIHI TARGET (>7m)',
                    value: '$delayedOrders Tiket',
                    color: delayedOrders > 0 ? WarmPalette.danger : WarmPalette.textSecondary,
                    isAlert: delayedOrders > 0,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Station Filters
        Container(
          height: 48,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildStationChip('Semua Station', state.station == null, () => cubit.filterStation(null)),
              _buildStationChip('Espresso Bar', state.station == 'Espresso Bar', () => cubit.filterStation('Espresso Bar')),
              _buildStationChip('Manual Brew & Pour Over', state.station == 'Manual Brew', () => cubit.filterStation('Manual Brew')),
              _buildStationChip('Pastry & Toast', state.station == 'Pastry & Toast', () => cubit.filterStation('Pastry & Toast')),
              for (final s in state.stations)
                if (!['Espresso Bar', 'Manual Brew', 'Pastry & Toast'].contains(s))
                  _buildStationChip(s, state.station == s, () => cubit.filterStation(s)),
            ],
          ),
        ),
        const Divider(height: 1, color: WarmPalette.line),

        // Kanban Board Columns
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < AppBreakpoints.mobile || constraints.maxHeight < AppBreakpoints.compactHeight;
              final isWide = !isMobile;
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

              if (isWide) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final col in columns)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
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
                      indicatorColor: WarmPalette.primary,
                      labelColor: WarmPalette.primary,
                      unselectedLabelColor: WarmPalette.textSecondary,
                      tabs: [
                        for (final s in _stages)
                          Tab(text: '${s.$2.split(" / ")[0]} (${state.byStage(s.$1).length})'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: columns.map((c) => Padding(padding: const EdgeInsets.all(12), child: c)).toList(),
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
          color: Colors.white,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.wifi_tethering_rounded, size: 14, color: WarmPalette.tertiary),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'KDS Live Sync Terhubung',
                        style: TextStyle(fontSize: 11, color: WarmPalette.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.print_outlined, size: 14, color: WarmPalette.tertiary),
                  SizedBox(width: 4),
                  Text(
                    'Thermal Printer [OK]',
                    style: TextStyle(fontSize: 11, color: WarmPalette.tertiary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({required IconData icon, required String label, required String value, required Color color, bool isAlert = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isAlert ? WarmPalette.danger.withValues(alpha: 0.1) : WarmPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: isAlert ? Border.all(color: WarmPalette.danger.withValues(alpha: 0.3)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.4)),
              Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isAlert ? WarmPalette.danger : WarmPalette.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStationChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: WarmPalette.primary,
        backgroundColor: WarmPalette.surfaceMuted,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : WarmPalette.textPrimary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          fontSize: 12,
        ),
        shape: const StadiumBorder(),
        side: BorderSide.none,
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
    final (tintColor, dotColor) = switch (stage) {
      KitchenStage.fresh => (WarmPalette.surfaceMuted, WarmPalette.textSecondary),
      KitchenStage.preparing => (const Color(0xFFFDF0E3), WarmPalette.secondary),
      KitchenStage.ready => (const Color(0xFFEAF4EC), WarmPalette.tertiary),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tintColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WarmPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: WarmPalette.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Text('${orders.length} Tiket', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: WarmPalette.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Text('Tidak ada tiket', style: TextStyle(color: WarmPalette.textSecondary.withValues(alpha: 0.6), fontSize: 13)),
                  )
                : ListView.separated(
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) => KitchenTicketCard(order: orders[i], actionLabel: actionLabel, station: station),
                  ),
          ),
        ],
      ),
    );
  }
}
