// features/fnb_customer/widgets/customer_cart_order_type_bar.dart
import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';

class CustomerCartOrderTypeBar extends StatelessWidget {
  const CustomerCartOrderTypeBar({
    super.key,
    required this.currentType,
    required this.tableName,
    required this.onChanged,
  });

  final String currentType;
  final String tableName;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dineInLabel = 'Dine-In ($tableName)';

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surfaceMuted,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _buildTab(context, dineInLabel, Icons.restaurant_rounded),
          _buildTab(context, 'Takeaway', Icons.shopping_bag_outlined),
          _buildTab(context, 'Delivery', Icons.delivery_dining_outlined),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, String title, IconData icon) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isSel = currentType == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSel ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSel ? Colors.white : p.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                      color: isSel ? Colors.white : p.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
