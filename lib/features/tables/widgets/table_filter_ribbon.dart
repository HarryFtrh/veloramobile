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
    String key,
    String title,
    int count,
    IconData icon,
    Color? badgeColor,
  ) {
    final isSel = selectedFilter == key;
    return GestureDetector(
      onTap: () => onFilterSelected(key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
        decoration: BoxDecoration(
          color: isSel ? WarmPalette.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSel ? Colors.transparent : WarmPalette.line,
          ),
          boxShadow: isSel
              ? [
                  BoxShadow(
                    color: WarmPalette.primary.withValues(alpha: 0.15),
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
              color: isSel ? Colors.white : (badgeColor ?? WarmPalette.textSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              '$title ($count)',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                color: isSel ? Colors.white : WarmPalette.textPrimary,
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
          _buildFilterTab(
            'all',
            'Semua',
            allCount,
            Icons.grid_view_rounded,
            null,
          ),
          const SizedBox(width: 8),
          _buildFilterTab(
            'available',
            'Kosong',
            availableCount,
            Icons.check_circle_outline_rounded,
            WarmPalette.tertiary,
          ),
          const SizedBox(width: 8),
          _buildFilterTab(
            'occupied',
            'Terisi',
            occupiedCount,
            Icons.restaurant_rounded,
            WarmPalette.primary,
          ),
          const SizedBox(width: 8),
          _buildFilterTab(
            'reserved',
            'Booking',
            reservedCount,
            Icons.bookmark_outline_rounded,
            const Color(0xFF6A4C93),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WarmPalette.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.pie_chart_rounded,
                  size: 13,
                  color: WarmPalette.secondary,
                ),
                const SizedBox(width: 5),
                Text(
                  allCount == 0
                      ? '0 Meja'
                      : '${((occupiedCount / allCount) * 100).round()}% Terpakai',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: WarmPalette.textPrimary,
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
