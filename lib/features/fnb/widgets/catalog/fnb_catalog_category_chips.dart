import 'package:flutter/material.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/utils/safe_json.dart';
import '../../fnb_register_controller.dart';

/// Horizontal scrollable category pill chips for FnB Catalog
class FnbCatalogCategoryChips extends StatelessWidget {
  final RegisterController ctrl;

  const FnbCatalogCategoryChips({
    super.key,
    required this.ctrl,
  });

  static IconData getCategoryIcon(String cat) {
    final lower = cat.toLowerCase();
    if (lower == 'semua' || lower == 'all') return Icons.grid_view_rounded;
    if (lower.contains('espresso') || lower.contains('kopi') || lower.contains('coffee')) return Icons.coffee_rounded;
    if (lower.contains('manual') || lower.contains('brew') || lower.contains('tea') || lower.contains('teh')) return Icons.local_cafe_rounded;
    if (lower.contains('pastry') || lower.contains('bakery') || lower.contains('roti')) return Icons.bakery_dining_rounded;
    if (lower.contains('food') || lower.contains('makan') || lower.contains('main')) return Icons.restaurant_rounded;
    if (lower.contains('beverage') || lower.contains('minum') || lower.contains('drink') || lower.contains('juice')) return Icons.local_bar_rounded;
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : Gap.lg),
        children: [
          for (final c in ctrl.categories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Builder(builder: (context) {
                final p = context.palette;
                final primaryColor = Theme.of(context).colorScheme.primary;
                final isSelected = ctrl.category == c;
                final count = c == 'Semua'
                    ? ctrl.products.length
                    : ctrl.products.where((p) => p.category == c).length;
                final labelText = c == 'Semua'
                    ? 'Semua Menu ($count)'
                    : (count > 0 ? '$c ($count)' : c);
                return InkWell(
                  onTap: () => ctrl.setCategory(c),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : p.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? primaryColor : p.line,
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.18),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          getCategoryIcon(c),
                          size: 15,
                          color: isSelected ? Colors.white : p.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          sanitizeDisplayName(labelText),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? Colors.white : p.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}
