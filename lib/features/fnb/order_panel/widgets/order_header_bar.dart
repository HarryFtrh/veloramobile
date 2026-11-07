import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/utils/safe_json.dart';
import '../../fnb_register_controller.dart';

/// Top section of the FnB order panel: Order type (Dine-In/Takeaway/Online),
/// Customer / Member selection, and Table indicator.
class OrderHeaderBar extends StatelessWidget {
  const OrderHeaderBar({
    super.key,
    required this.ctrl,
    required this.onPickTable,
    required this.onEditCustomer,
    required this.horizontalPadding,
  });

  final RegisterController ctrl;
  final VoidCallback onPickTable;
  final VoidCallback onEditCustomer;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Order Type Selector
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<OrderType>(
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return primaryColor;
                  }
                  return p.surface;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return p.textPrimary;
                }),
                side: WidgetStateProperty.all(BorderSide(color: p.line)),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              segments: [
                ButtonSegment(
                  value: OrderType.dineIn,
                  icon: const Icon(Icons.restaurant, size: 15),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      ctrl.table == null ? 'Dine-In' : 'Dine-In (${sanitizeDisplayName(ctrl.table!.name)})',
                      maxLines: 1,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const ButtonSegment(
                  value: OrderType.takeaway,
                  icon: Icon(Icons.shopping_bag_outlined, size: 15),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Takeaway', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
                const ButtonSegment(
                  value: OrderType.online,
                  icon: Icon(Icons.delivery_dining_rounded, size: 15),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Online', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
              selected: {ctrl.orderType},
              onSelectionChanged: (s) {
                if (s.isEmpty) return;
                final newType = s.first;
                Future.microtask(() {
                  ctrl.setOrderType(newType);
                  if (newType == OrderType.dineIn && ctrl.table == null) {
                    onPickTable();
                  }
                });
              },
            ),
          ),
        ),
        const SizedBox(height: Gap.xs + 2),

        // Customer & Table Information Bar
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 6),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onEditCustomer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundColor: ctrl.memberTier != null
                                ? const Color(0xFFFEF3C7)
                                : (ctrl.customerName.isNotEmpty
                                    ? const Color(0xFFE0E7FF)
                                    : p.surfaceMuted),
                            child: Icon(
                              ctrl.memberTier != null
                                  ? Icons.stars_rounded
                                  : (ctrl.customerName.isNotEmpty ? Icons.person_rounded : Icons.person_outline_rounded),
                              size: 17,
                              color: ctrl.memberTier != null
                                  ? const Color(0xFFD97706)
                                  : (ctrl.customerName.isNotEmpty ? const Color(0xFF4338CA) : p.textSecondary),
                            ),
                          ),
                          const SizedBox(width: Gap.xs + 2),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  ctrl.customerName.isEmpty ? 'Pelanggan Umum' : sanitizeDisplayName(ctrl.customerName),
                                  style: text.bodyMedium?.copyWith(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: ctrl.customerName.isNotEmpty ? p.textPrimary : p.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (ctrl.memberTier != null)
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${ctrl.memberTier!.toUpperCase()} • ${ctrl.memberDiscountPercent.round()}% OFF',
                                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (ctrl.customerName.isNotEmpty) ...[
                            Tooltip(
                              message: 'Kembali ke Pelanggan Umum',
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  ctrl.setMember('', tier: null, discountPercent: 0);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: p.surfaceMuted,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.close_rounded, size: 14, color: p.textSecondary),
                                ),
                              ),
                            ),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Ganti',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (ctrl.orderType == OrderType.dineIn) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onPickTable,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ctrl.table == null
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFF059669).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ctrl.table == null
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF059669).withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.table_restaurant_rounded,
                            size: 13,
                            color: ctrl.table == null
                                ? const Color(0xFFB45309)
                                : const Color(0xFF059669),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ctrl.table == null ? 'Pilih Meja' : ctrl.table!.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: ctrl.table == null
                                  ? const Color(0xFFB45309)
                                  : const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
