import 'package:material_ui/material_ui.dart';
import 'package:shimmer/shimmer.dart';

import '../design/tokens.dart';

/// Theme-aware Shimmer Skeleton placeholders for smooth, modern loading states
/// across lists, product/table grids, and KPI dashboards.
class VeloraShimmerSkeleton extends StatelessWidget {
  const VeloraShimmerSkeleton._(
    this._kind, {
    this.itemCount = 5,
    this.crossAxisCount = 2,
    this.padding = const EdgeInsets.all(16),
  });

  factory VeloraShimmerSkeleton.list({
    int itemCount = 5,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) =>
      VeloraShimmerSkeleton._(
        _SkeletonKind.list,
        itemCount: itemCount,
        padding: padding,
      );

  factory VeloraShimmerSkeleton.grid({
    int itemCount = 6,
    int crossAxisCount = 2,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) =>
      VeloraShimmerSkeleton._(
        _SkeletonKind.grid,
        itemCount: itemCount,
        crossAxisCount: crossAxisCount,
        padding: padding,
      );

  factory VeloraShimmerSkeleton.dashboard({
    EdgeInsets padding = const EdgeInsets.all(16),
  }) =>
      VeloraShimmerSkeleton._(
        _SkeletonKind.dashboard,
        padding: padding,
      );

  final _SkeletonKind _kind;
  final int itemCount;
  final int crossAxisCount;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? p.surfaceMuted : p.line.withValues(alpha: 0.55);
    final highlightColor = isDark
        ? p.line.withValues(alpha: 0.7)
        : p.surface.withValues(alpha: 0.9);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: padding,
        child: switch (_kind) {
          _SkeletonKind.list => _buildList(),
          _SkeletonKind.grid => _buildGrid(),
          _SkeletonKind.dashboard => _buildDashboard(),
        },
      ),
    );
  }

  Widget _box({
    double? width,
    required double height,
    double radius = 10,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildList() {
    return Column(
      children: [
        for (var i = 0; i < itemCount; i++) ...[
          Row(
            children: [
              _box(width: 48, height: 48, radius: 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(width: double.infinity, height: 14, radius: 6),
                    const SizedBox(height: 8),
                    _box(width: 150, height: 11, radius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _box(width: 56, height: 26, radius: 10),
            ],
          ),
          if (i < itemCount - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: itemCount,
      itemBuilder: (_, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _box(width: double.infinity, height: 100, radius: 14)),
          const SizedBox(height: 8),
          _box(width: double.infinity, height: 13, radius: 6),
          const SizedBox(height: 6),
          _box(width: 78, height: 11, radius: 6),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _box(height: 92, radius: 18)),
            const SizedBox(width: 12),
            Expanded(child: _box(height: 92, radius: 18)),
          ],
        ),
        const SizedBox(height: 14),
        _box(width: double.infinity, height: 170, radius: 20),
        const SizedBox(height: 16),
        _box(width: 140, height: 14, radius: 6),
        const SizedBox(height: 12),
        _buildList(),
      ],
    );
  }
}

enum _SkeletonKind { list, grid, dashboard }
