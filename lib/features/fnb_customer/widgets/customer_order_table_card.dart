import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../core/storage/session_storage.dart';

/// Card showing table number, outlet name, and request table change button
class CustomerOrderTableCard extends StatelessWidget {
  final String tableNumber;
  final VoidCallback onRequestTableChange;

  const CustomerOrderTableCard({
    super.key,
    required this.tableNumber,
    required this.onRequestTableChange,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: p.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.table_restaurant_rounded,
              color: primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tableNumber.isNotEmpty ? tableNumber : 'Meja Kasir',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: p.tertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Dine In',
                        style: TextStyle(
                          fontSize: 10,
                          color: p.tertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  SessionStorage.instance.getLocationName() ?? 'Area Restoran / Cafe',
                  style: TextStyle(
                    fontSize: 12,
                    color: p.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRequestTableChange,
            child: Text(
              'Pindah Meja?',
              style: TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
