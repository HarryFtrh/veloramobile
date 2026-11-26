import 'package:material_ui/material_ui.dart';

import '../../../core/design/tokens.dart';
import '../../../core/utils/audio_helper.dart';

/// Smooth stadium-pill horizontal filter ribbon for the Tables screen.
class TableFilterRibbon extends StatelessWidget {
  const TableFilterRibbon({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.allCount,
    required this.availableCount,
    required this.occupiedCount,
    required this.reservedCount,
  });

  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;
  final int allCount;
  final int availableCount;
  final int occupiedCount;
  final int reservedCount;

  Widget _buildFilterPill(
    BuildContext context, {
    required String filterKey,
    required String title,
    required int count,
    Color? dotColor,
  }) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isSel = selectedFilter == filterKey;

    return GestureDetector(
      onTap: () {
        if (!isSel) AudioHelper.tapFeedback();
        onFilterSelected(filterKey);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        decoration: BoxDecoration(
          color: isSel ? primaryColor : p.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSel
                ? Colors.transparent
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : p.line.withValues(alpha: 0.65)),
          ),
          boxShadow: [
            BoxShadow(
              color: isSel
                  ? primaryColor.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
              blurRadius: isSel ? 10 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isSel ? Colors.white : dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
            ],
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                color: isSel ? Colors.white : p.textPrimary,
                letterSpacing: -0.1,
              ),
              child: Text(title),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSel
                    ? Colors.white.withValues(alpha: 0.22)
                    : p.surfaceMuted,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isSel ? Colors.white : p.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterPill(
            context,
            filterKey: 'all',
            title: 'Semua',
            count: allCount,
          ),
          const SizedBox(width: 8),
          _buildFilterPill(
            context,
            filterKey: 'available',
            title: 'Kosong',
            count: availableCount,
            dotColor: const Color(0xFF059669),
          ),
          const SizedBox(width: 8),
          _buildFilterPill(
            context,
            filterKey: 'occupied',
            title: 'Terisi',
            count: occupiedCount,
            dotColor: const Color(0xFF2563EB),
          ),
          const SizedBox(width: 8),
          _buildFilterPill(
            context,
            filterKey: 'reserved',
            title: 'Booking',
            count: reservedCount,
            dotColor: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }
}
