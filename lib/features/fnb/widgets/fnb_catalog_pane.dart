import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../shared_pos/product_catalog_service.dart';
import '../fnb_register_controller.dart';
import 'catalog/fnb_catalog_category_chips.dart';
import 'catalog/fnb_catalog_search_bar.dart';
import 'catalog/fnb_catalog_status_footer.dart';
import 'catalog/fnb_product_grid_card.dart';

export 'catalog/fnb_catalog_category_chips.dart';
export 'catalog/fnb_catalog_search_bar.dart';
export 'catalog/fnb_catalog_status_footer.dart';
export 'catalog/fnb_product_grid_card.dart';

/// Main catalog pane for FnB POS displaying search, category pills, and product grid
class FnbCatalogPane extends StatelessWidget {
  const FnbCatalogPane({
    super.key,
    required this.ctrl,
    required this.onAdd,
    this.maxWidth,
    this.onHold,
    this.onOpenBills,
  });

  final RegisterController ctrl;
  final void Function(PosProduct) onAdd;
  final double? maxWidth;
  final VoidCallback? onHold;
  final VoidCallback? onOpenBills;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final text = Theme.of(context).textTheme;
    final items = ctrl.visibleProducts;
    final isMobile = context.isMobile;

    final content = Column(
      children: [
        // Search & Action Bar
        FnbCatalogSearchBar(
          ctrl: ctrl,
          onAdd: onAdd,
          onHold: onHold,
          onOpenBills: onOpenBills,
        ),

        // Horizontal Category Chips
        FnbCatalogCategoryChips(ctrl: ctrl),

        // Product Grid or Empty State
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: p.surfaceMuted,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.coffee_rounded,
                              size: 44,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: Gap.md),
                          Text(
                            ctrl.search.isNotEmpty
                                ? 'Menu "${ctrl.search}" tidak ditemukan'
                                : 'Belum ada menu di kategori "${ctrl.category}"',
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: p.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Data menu dimuat langsung dari server cabang aktif.',
                            style: TextStyle(
                              fontSize: 12,
                              color: p.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: Gap.lg),
                          OutlinedButton.icon(
                            onPressed: ctrl.load,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text(
                              'Muat Ulang dari Server',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryColor,
                              side: BorderSide(color: primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : GridView.builder(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 12 : Gap.lg,
                    Gap.sm,
                    isMobile ? 12 : Gap.lg,
                    isMobile && ctrl.lines.isNotEmpty ? 84 : Gap.lg,
                  ),
                  gridDelegate: isMobile
                      ? const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.68,
                        )
                      : const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 185,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          mainAxisExtent: 228,
                        ),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final hasVariants = ctrl.groupsFor(item).isNotEmpty;
                    return FnbProductGridCard(
                      item: item,
                      hasVariants: hasVariants,
                      onAdd: () => onAdd(item),
                    );
                  },
                ),
        ),

        // Bottom status & PB1 tax info footer
        FnbCatalogStatusFooter(
          ctrl: ctrl,
          maxWidth: maxWidth,
        ),
      ],
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: content,
    );
  }
}
