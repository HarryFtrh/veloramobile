import '../../../core/design/tokens.dart';
import 'package:flutter/material.dart';
import '../customer_models.dart';

class CustomerCartItemCard extends StatelessWidget {
  const CustomerCartItemCard({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  final CustomerCartItem item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Image.network(
                  item.product.imageUrl,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  cacheWidth: 160,
                  cacheHeight: 160,
                  errorBuilder: (_, _, _) => Container(
                    width: 72,
                    height: 72,
                    color: p.surfaceMuted,
                    child: Icon(
                      Icons.coffee,
                      color: primaryColor,
                    ),
                  ),
                ),
                Positioned(
                  left: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.product.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onRemove,
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: p.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.size} • ${item.sweetness} ${item.toppings.isNotEmpty ? "• ${item.toppings.join(", ")}" : ""}',
                  style: TextStyle(
                    fontSize: 11,
                    color: p.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Rp ${item.totalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: p.textPrimary,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: p.surfaceMuted,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28),
                            icon: const Icon(Icons.remove, size: 14),
                            onPressed: () => onQuantityChanged(item.quantity - 1),
                          ),
                          Text(
                            '${item.quantity}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28),
                            icon: const Icon(Icons.add, size: 14),
                            onPressed: () => onQuantityChanged(item.quantity + 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
