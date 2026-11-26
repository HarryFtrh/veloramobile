import 'package:material_ui/material_ui.dart';

import '../../../core/design/tokens.dart';
import '../../../core/utils/audio_helper.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/safe_json.dart';
import '../table_service.dart';

/// Flagship visual floor-plan table card with status tint, mini chair/table
/// indicator, tactile press bounce, and smooth selection animation.
class TableGridTile extends StatefulWidget {
  const TableGridTile({
    super.key,
    required this.table,
    required this.isSelected,
    required this.onSelect,
    this.onOpenTable,
  });

  final CafeTableInfo table;
  final bool isSelected;
  final VoidCallback onSelect;
  final void Function(CafeTableInfo)? onOpenTable;

  @override
  State<TableGridTile> createState() => _TableGridTileState();
}

class _TableGridTileState extends State<TableGridTile> {
  bool _pressed = false;

  Color _statusColor(TableStatus status) {
    return switch (status) {
      TableStatus.available => const Color(0xFF059669),
      TableStatus.ordered => const Color(0xFF2563EB),
      TableStatus.occupied => const Color(0xFFD97706),
      TableStatus.reserved => const Color(0xFF7C3AED),
    };
  }

  String _statusLabel(TableStatus status) {
    return switch (status) {
      TableStatus.available => 'Kosong',
      TableStatus.ordered => 'Terisi',
      TableStatus.occupied => 'Bill',
      TableStatus.reserved => 'Booking',
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final t = widget.table;
    final color = _statusColor(t.status);
    final isOccupied =
        t.status == TableStatus.ordered || t.status == TableStatus.occupied;

    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          AudioHelper.tapFeedback();
          widget.onSelect();
        },
        onDoubleTap: widget.onOpenTable != null
            ? () {
                AudioHelper.tapFeedback();
                widget.onOpenTable!(t);
              }
            : null,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: widget.isSelected
                    ? primaryColor
                    : (isOccupied
                        ? color.withValues(alpha: isDark ? 0.35 : 0.25)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : p.line.withValues(alpha: 0.65))),
                width: widget.isSelected ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isSelected
                      ? primaryColor.withValues(alpha: isDark ? 0.28 : 0.16)
                      : Colors.black.withValues(alpha: isDark ? 0.26 : 0.045),
                  blurRadius: widget.isSelected ? 18 : 14,
                  spreadRadius: widget.isSelected ? -1 : -3,
                  offset: Offset(0, widget.isSelected ? 6 : 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Status Pill + Seat Capacity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: isDark ? 0.20 : 0.11),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _statusLabel(t.status),
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: p.surfaceMuted,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chair_alt_rounded,
                            size: 11.5,
                            color: p.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${t.capacity}',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: p.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Row 2: Visual Floor-Plan Icon + Table Name
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: isDark ? 0.18 : 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.table_restaurant_rounded,
                        size: 19,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            sanitizeDisplayName(t.name),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                              color: p.textPrimary,
                              letterSpacing: -0.35,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${t.capacity} Kursi',
                            style: TextStyle(
                              fontSize: 11,
                              color: p.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Row 3: Soft Sub-Pill Footer
                if (isOccupied)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: p.surfaceMuted,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              t.order != null
                                  ? '${t.order!.itemCount} item'
                                  : 'Aktif',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: p.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                t.order != null
                                    ? t.order!.total.toRupiah()
                                    : 'Aktif',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: color,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (t.order?.customerName?.trim().isNotEmpty == true)
                              ? t.order!.customerName!.trim()
                              : 'Dine In',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: p.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  )
                else if (t.status == TableStatus.reserved)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.16 : 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          t.reservation?.customerName ?? 'Reservasi',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${t.reservation?.time ?? "-"} • ${t.reservation?.pax ?? t.capacity} Pax',
                          style: TextStyle(
                            fontSize: 10,
                            color: p.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 13.5,
                          color: color,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Siap digunakan',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
