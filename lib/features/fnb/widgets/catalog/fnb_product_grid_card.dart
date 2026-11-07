import 'package:flutter/material.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/safe_json.dart';
import '../../../shared_pos/product_catalog_service.dart';

/// Clean, responsive product grid card for FnB Catalog
class FnbProductGridCard extends StatelessWidget {
  final PosProduct item;
  final bool hasVariants;
  final VoidCallback onAdd;

  const FnbProductGridCard({
    super.key,
    required this.item,
    required this.hasVariants,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final text = Theme.of(context).textTheme;
    final isOutOfStock = item.stock <= 0;

    // Dynamic badge tag from backend data or stock status
    String? badgeTag;
    Color badgeBg = primaryColor;
    final tagStr = item.tag?.toString().trim() ?? '';
    if (isOutOfStock) {
      badgeTag = 'Habis';
      badgeBg = p.danger;
    } else if (tagStr.isNotEmpty) {
      badgeTag = tagStr;
      final lowerTag = tagStr.toLowerCase();
      if (lowerTag.contains('plant') || lowerTag.contains('sehat')) {
        badgeBg = p.tertiary;
      } else if (lowerTag.contains('promo') || lowerTag.contains('diskon')) {
        badgeBg = p.secondary;
      }
    } else if (item.stock > 0 && item.stock <= 5) {
      badgeTag = 'Sisa Sedikit';
      badgeBg = p.secondary;
    }

    return Opacity(
      opacity: isOutOfStock ? 0.65 : 1.0,
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: p.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isOutOfStock ? null : onAdd,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Container with Badge
                SizedBox(
                  height: 84,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: p.surfaceMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                            ? Image.network(
                                item.imageUrl!,
                                fit: BoxFit.cover,
                                cacheWidth: 320,
                                errorBuilder: (_, _, _) => Center(
                                  child: Icon(item.defaultIcon, size: 28, color: primaryColor),
                                ),
                              )
                            : Center(
                                child: Icon(item.defaultIcon, size: 28, color: primaryColor),
                              ),
                      ),
                      if (badgeTag != null)
                        Positioned(
                          top: 5,
                          left: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badgeTag,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      if (hasVariants)
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.tune_rounded, size: 9, color: Colors.white),
                                SizedBox(width: 3),
                                Text(
                                  'Varian',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),

                // Stock & SKU Row
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isOutOfStock ? p.danger : const Color(0xFF059669),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        isOutOfStock ? 'Stok Habis' : (item.stock >= 90 ? 'Tersedia' : 'Stok: ${item.stock.toInt()} porsi'),
                        style: TextStyle(
                          fontSize: 9.5,
                          color: isOutOfStock ? p.danger : p.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.sku.isNotEmpty)
                      Text(
                        item.sku,
                        style: TextStyle(fontSize: 9, color: p.textTertiary, fontWeight: FontWeight.w600),
                        maxLines: 1,
                      ),
                  ],
                ),
                const SizedBox(height: 3),

                // Product Name
                Text(
                  sanitizeDisplayName(item.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    height: 1.2,
                  ),
                ),

                // Description / Subtitle
                if (item.description != null && item.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.description!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: p.textTertiary,
                      height: 1.2,
                    ),
                  ),
                ],

                const Spacer(),

                // Price and Add Button
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        CurrencyFormatter.format(item.price),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: p.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isOutOfStock)
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: p.surfaceMuted,
                        child: Icon(Icons.block_rounded, size: 14, color: p.textTertiary),
                      )
                    else
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: primaryColor.withValues(alpha: 0.12),
                        child: Icon(Icons.add, size: 16, color: primaryColor),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
