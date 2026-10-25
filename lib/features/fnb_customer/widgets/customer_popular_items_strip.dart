import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../../shared_pos/product_catalog_service.dart';
import '../customer_models.dart';

/// Horizontal strip displaying the most popular menu items for patrons.
class CustomerPopularItemsStrip extends StatelessWidget {
  const CustomerPopularItemsStrip({
    super.key,
    required this.products,
    required this.onTapItem,
    required this.onViewAll,
  });

  final List<PosProduct> products;
  final ValueChanged<CustomerMenuItem> onTapItem;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    if (products.length <= 2) return const SizedBox.shrink();

    final cardWidth = (MediaQuery.of(context).size.width * 0.68).clamp(200.0, 260.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Menu Terpopuler',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: WarmPalette.textPrimary,
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              child: const Text(
                'Semua',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFD97706),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 84,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (ctx, i) {
              final p = products[i];
              final item = CustomerMenuItem(
                id: p.id,
                name: p.name,
                category: p.category,
                description: 'Stok: ${p.stock > 0 ? p.stock.toInt() : "Habis"} • SKU: ${p.sku}',
                basePrice: p.price.toInt(),
                rating: 4.9,
                imageUrl: p.imageUrl ?? '',
              );

              return GestureDetector(
                onTap: () => onTapItem(item),
                child: Container(
                  width: cardWidth,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: WarmPalette.line),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            SizedBox(
                              width: 68,
                              height: 68,
                              child: item.imageUrl.isNotEmpty
                                  ? Image.network(
                                      item.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        color: WarmPalette.surfaceMuted,
                                        child: const Icon(Icons.coffee, color: WarmPalette.primary),
                                      ),
                                    )
                                  : Container(
                                      color: WarmPalette.surfaceMuted,
                                      child: const Icon(Icons.coffee, color: WarmPalette.primary),
                                    ),
                            ),
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star_rounded, size: 10, color: WarmPalette.secondary),
                                    const SizedBox(width: 2),
                                    Text('${item.rating}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: WarmPalette.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: WarmPalette.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rp ${item.basePrice.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: WarmPalette.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
