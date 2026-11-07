import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';

/// Horizontal category chip selector ribbon with adaptive icons.
class CustomerCategoryRibbon extends StatelessWidget {
  const CustomerCategoryRibbon({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelectCategory,
    required this.onViewAll,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelectCategory;
  final VoidCallback onViewAll;

  static IconData categoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('semua') || lower.contains('all')) return Icons.restaurant_rounded;
    if (lower.contains('kopi') || lower.contains('coffee') || lower.contains('signature') || lower.contains('espresso')) {
      return Icons.coffee_rounded;
    }
    if (lower.contains('cold') || lower.contains('es') || lower.contains('ice') || lower.contains('brew')) {
      return Icons.ac_unit_rounded;
    }
    if (lower.contains('pastry') || lower.contains('bakery') || lower.contains('roti') || lower.contains('cake')) {
      return Icons.bakery_dining_rounded;
    }
    if (lower.contains('snack') || lower.contains('cemilan') || lower.contains('bite')) return Icons.cookie_rounded;
    if (lower.contains('tea') || lower.contains('teh')) return Icons.emoji_food_beverage_rounded;
    return Icons.local_dining_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kategori',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: p.textPrimary,
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFD97706),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((title) {
              final isSel = selectedCategory == title;
              final icon = categoryIcon(title);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => onSelectCategory(title),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSel ? primaryColor : p.line,
                      ),
                      boxShadow: isSel
                          ? [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.2),
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
                          size: 16,
                          color: isSel ? Colors.white : p.textPrimary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          title,
                          style: TextStyle(
                            color: isSel ? Colors.white : p.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
