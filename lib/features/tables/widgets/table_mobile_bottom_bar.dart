import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../../../core/utils/safe_json.dart';
import '../table_service.dart';

/// Floating mobile selection bar docked at the bottom of the screen.
class TableMobileBottomBar extends StatelessWidget {
  const TableMobileBottomBar({
    super.key,
    required this.table,
    required this.activeOrder,
    required this.onTapDetails,
    required this.onPayment,
    this.onOpenPos,
    required this.onClose,
  });

  final CafeTableInfo table;
  final ActiveTableOrder? activeOrder;
  final VoidCallback onTapDetails;
  final VoidCallback onPayment;
  final VoidCallback? onOpenPos;
  final VoidCallback onClose;

  Color _statusColor(TableStatus s) {
    return switch (s) {
      TableStatus.available => WarmPalette.tertiary,
      TableStatus.ordered => WarmPalette.primary,
      TableStatus.occupied => WarmPalette.secondary,
      TableStatus.reserved => const Color(0xFF6A4C93),
    };
  }

  String _statusLabel(TableStatus s) {
    return switch (s) {
      TableStatus.available => 'Kosong',
      TableStatus.ordered => 'Terisi',
      TableStatus.occupied => 'Bill',
      TableStatus.reserved => 'Booking',
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(table.status);
    final label = _statusLabel(table.status);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: WarmPalette.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTapDetails,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.table_restaurant_rounded,
                      color: color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                sanitizeDisplayName(table.name),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: WarmPalette.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activeOrder != null
                              ? 'Rp ${activeOrder!.totalAmount.round().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")} (${activeOrder!.items.length} item)'
                              : (table.order != null
                                  ? 'Rp ${table.order!.total.round().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")} (${table.order!.itemCount} item)'
                                  : 'Kapasitas ${table.capacity} Kursi • Kosong'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: table.status != TableStatus.available
                                ? WarmPalette.primary
                                : WarmPalette.tertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (table.status != TableStatus.available)
                    FilledButton(
                      onPressed: onPayment,
                      style: FilledButton.styleFrom(
                        backgroundColor: WarmPalette.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Bayar', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                    )
                  else if (onOpenPos != null)
                    FilledButton(
                      onPressed: onOpenPos,
                      style: FilledButton.styleFrom(
                        backgroundColor: WarmPalette.tertiary,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Buka POS', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                    ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded, size: 18, color: WarmPalette.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
