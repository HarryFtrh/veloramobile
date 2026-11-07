import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';

/// Horizontal ribbon displaying table filter tabs and live occupancy status pill.
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

  Widget _buildFilterTab(
    BuildContext context,
    String key,
    String title,
    int count,
    IconData icon,
    Color? badgeColor,
  ) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isSel = selectedFilter == key;

    return GestureDetector(
      onTap: () => onFilterSelected(key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
        decoration: BoxDecoration(
          color: isSel ? primaryColor : p.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSel ? Colors.transparent : p.line,
          ),
          boxShadow: isSel
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSel ? Colors.white : (badgeColor ?? p.textSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              '$title ($count)',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                color: isSel ? Colors.white : p.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterTab(
            context,
            'all',
            'Semua',
            allCount,
            Icons.grid_view_rounded,
            null,
          ),
          const SizedBox(width: 8),
          _buildFilterTab(
            context,
            'available',
            'Kosong',
            availableCount,
            Icons.check_circle_outline_rounded,
            const Color(0xFF059669),
          ),
          const SizedBox(width: 8),
          _buildFilterTab(
            context,
            'occupied',
            'Terisi',
            occupiedCount,
            Icons.restaurant_rounded,
            const Color(0xFF2563EB),
          ),
          const SizedBox(width: 8),
          _buildFilterTab(
            context,
            'reserved',
            'Booking',
            reservedCount,
            Icons.bookmark_outline_rounded,
            const Color(0xFF7C3AED),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.pie_chart_rounded,
                  size: 13,
                  color: Color(0xFFD97706),
                ),
                const SizedBox(width: 5),
                Text(
                  allCount == 0
                      ? '0 Meja'
                      : '${((occupiedCount / allCount) * 100).round()}% Terpakai',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
