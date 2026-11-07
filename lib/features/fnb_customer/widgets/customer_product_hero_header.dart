import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../customer_models.dart';

/// Top hero image, category pill, rating, base price, and description for Customer Product Detail Sheet
class CustomerProductHeroHeader extends StatelessWidget {
  final CustomerMenuItem product;

  const CustomerProductHeroHeader({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image Card
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  cacheWidth: 600,
                  errorBuilder: (_, _, _) => Container(
                    color: p.surfaceMuted,
                    child: Icon(
                      Icons.coffee,
                      size: 64,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 12,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.eco_outlined,
                            size: 14,
                            color: p.tertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Single Origin Blend',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: p.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: p.surfaceMuted.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        product.category.isNotEmpty ? product.category : 'Menu Spesial',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Title & Price
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: p.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${product.rating}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(
                          color: p.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: p.tertiary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.category.toUpperCase(),
                          style: TextStyle(
                            color: p.tertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (product.badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: p.secondary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.badge!,
                            style: TextStyle(
                              color: p.secondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rp ${product.basePrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                  ),
                ),
                Text(
                  'Harga Dasar',
                  style: TextStyle(
                    fontSize: 11,
                    color: p.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          product.description,
          style: TextStyle(
            fontSize: 13,
            color: p.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
