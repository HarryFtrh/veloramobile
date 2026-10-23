import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/safe_json.dart';
import '../shared_pos/product_catalog_service.dart';
import 'fnb_register_controller.dart';

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

  IconData _getCategoryIcon(String cat) {
    final lower = cat.toLowerCase();
    if (lower == 'semua' || lower == 'all') return Icons.grid_view_rounded;
    if (lower.contains('espresso') || lower.contains('kopi') || lower.contains('coffee')) return Icons.coffee_rounded;
    if (lower.contains('manual') || lower.contains('brew') || lower.contains('tea') || lower.contains('teh')) return Icons.local_cafe_rounded;
    if (lower.contains('pastry') || lower.contains('bakery') || lower.contains('roti')) return Icons.bakery_dining_rounded;
    if (lower.contains('food') || lower.contains('makan') || lower.contains('main')) return Icons.restaurant_rounded;
    if (lower.contains('beverage') || lower.contains('minum') || lower.contains('drink') || lower.contains('juice')) return Icons.local_bar_rounded;
    return Icons.category_outlined;
  }

  void _openBarcodeScanner(BuildContext context) {
    final barcodeCtrl = TextEditingController();
    String? localError;

    showDialog<void>(
      context: context,
      builder: (dCtx) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.qr_code_scanner_rounded, color: WarmPalette.primary),
              SizedBox(width: 8),
              Text('Pindai Barcode / SKU', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Arahkan scanner fisik atau ketik kode barcode/SKU produk:', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 12),
                TextField(
                  controller: barcodeCtrl,
                  autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Kode Barcode / SKU',
                  hintText: 'Contoh: 8991234567...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  errorText: localError,
                  prefixIcon: const Icon(Icons.qr_code_rounded),
                ),
                onSubmitted: (val) {
                  final code = val.trim();
                  if (code.isEmpty) return;
                  final match = ctrl.products.where((p) =>
                    p.barcode.toLowerCase() == code.toLowerCase() ||
                    p.sku.toLowerCase() == code.toLowerCase() ||
                    p.id == code
                  ).firstOrNull;

                  if (match != null) {
                    Navigator.pop(dCtx);
                    onAdd(match);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${match.name} ditambahkan ke keranjang')),
                    );
                  } else {
                    setDState(() {
                      localError = 'Produk dengan kode "$code" tidak ditemukan.';
                    });
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Tutup'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.search_rounded, size: 16),
              label: const Text('Cari & Tambah'),
              onPressed: () {
                final code = barcodeCtrl.text.trim();
                if (code.isEmpty) return;
                final match = ctrl.products.where((p) =>
                  p.barcode.toLowerCase() == code.toLowerCase() ||
                  p.sku.toLowerCase() == code.toLowerCase() ||
                  p.id == code
                ).firstOrNull;

                if (match != null) {
                  Navigator.pop(dCtx);
                  onAdd(match);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${match.name} ditambahkan ke keranjang')),
                  );
                } else {
                  setDState(() {
                    localError = 'Produk dengan kode "$code" tidak ditemukan.';
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final items = ctrl.visibleProducts;
    final isMobile = context.isMobile;

    final content = Column(
      children: [
        // Search & Filter Bar
        Padding(
          padding: EdgeInsets.fromLTRB(isMobile ? 12 : Gap.lg, Gap.xs + 2, isMobile ? 12 : Gap.lg, Gap.xs),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: ctrl.setSearch,
                  onSubmitted: (code) {
                    final trimmed = code.trim();
                    if (trimmed.isEmpty) return;
                    final match = ctrl.products.where((p) =>
                      p.barcode.toLowerCase() == trimmed.toLowerCase() ||
                      p.sku.toLowerCase() == trimmed.toLowerCase() ||
                      p.id == trimmed
                    ).firstOrNull;
                    if (match != null) {
                      onAdd(match);
                      ctrl.setSearch('');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${match.name} ditambahkan ke keranjang')),
                      );
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari kopi, makanan, nomor SKU, atau menu (Ketik /)...',
                    hintStyle: TextStyle(fontSize: isMobile ? 11.5 : 12.5, color: p.textTertiary),
                    prefixIcon: Icon(Icons.search_rounded, color: p.textSecondary, size: 20),
                    suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 24),
                    suffixIcon: isMobile
                        ? null
                        : Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: p.surface,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: p.line),
                                  ),
                                  child: Text(
                                    '⌘K',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: p.textTertiary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                    filled: true,
                    fillColor: p.surfaceMuted,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: p.line)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: p.line)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: WarmPalette.primary, width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(width: Gap.xs + 2),
              OutlinedButton.icon(
                onPressed: () => _openBarcodeScanner(context),
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                label: Text(isMobile ? 'Scan' : 'Scan Barcode', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: WarmPalette.primary,
                  minimumSize: const Size(0, 40),
                  side: const BorderSide(color: WarmPalette.line),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: 10),
                ),
              ),
              if (onHold != null || onOpenBills != null) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: ctrl.lines.isNotEmpty
                      ? 'Simpan pesanan aktif saat ini ke antrean hold'
                      : 'Buka daftar antrean pesanan / hold',
                  child: ctrl.lines.isNotEmpty
                      ? FilledButton.icon(
                          onPressed: !ctrl.busy ? onHold : null,
                          icon: const Icon(Icons.pause_presentation_rounded, size: 16),
                          label: Text(
                            isMobile ? 'Hold' : 'Simpan (Hold)',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: WarmPalette.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 40),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: 10),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: onOpenBills ?? onHold,
                          icon: const Icon(Icons.receipt_long_rounded, size: 16),
                          label: Text(
                            isMobile ? 'Antrean' : 'Antrean (Hold)',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: WarmPalette.textPrimary,
                            minimumSize: const Size(0, 40),
                            side: const BorderSide(color: WarmPalette.line),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: 10),
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),

        // Horizontal Category Chips
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : Gap.lg),
            children: [
              for (final c in ctrl.categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Builder(builder: (context) {
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
                          color: isSelected ? WarmPalette.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? WarmPalette.primary : WarmPalette.line,
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: WarmPalette.primary.withValues(alpha: 0.18),
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
                              _getCategoryIcon(c),
                              size: 15,
                              color: isSelected ? Colors.white : WarmPalette.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              sanitizeDisplayName(labelText),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? Colors.white : WarmPalette.textPrimary,
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
        ),

        // Product Grid
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
                            decoration: const BoxDecoration(
                              color: WarmPalette.surfaceMuted,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.coffee_rounded,
                              size: 44,
                              color: WarmPalette.primary,
                            ),
                          ),
                          const SizedBox(height: Gap.md),
                          Text(
                            ctrl.search.isNotEmpty
                                ? 'Menu "${ctrl.search}" tidak ditemukan'
                                : 'Belum ada menu di kategori "${ctrl.category}"',
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: WarmPalette.textPrimary,
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
                              foregroundColor: WarmPalette.primary,
                              side: const BorderSide(color: WarmPalette.primary),
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
                    final isOutOfStock = item.stock <= 0;
                    final hasVariants = ctrl.groupsFor(item).isNotEmpty;

                    // Dynamic badge tag dari data backend atau status stok
                    String? badgeTag;
                    Color badgeBg = WarmPalette.primary;
                    final tagStr = item.tag?.toString().trim() ?? '';
                    if (isOutOfStock) {
                      badgeTag = 'Habis';
                      badgeBg = WarmPalette.danger;
                    } else if (tagStr.isNotEmpty) {
                      badgeTag = tagStr;
                      final lowerTag = tagStr.toLowerCase();
                      if (lowerTag.contains('plant') || lowerTag.contains('sehat')) {
                        badgeBg = WarmPalette.tertiary;
                      } else if (lowerTag.contains('promo') || lowerTag.contains('diskon')) {
                        badgeBg = WarmPalette.secondary;
                      }
                    } else if (item.stock > 0 && item.stock <= 5) {
                      badgeTag = 'Sisa Sedikit';
                      badgeBg = WarmPalette.secondary;
                    }

                    return Opacity(
                      opacity: isOutOfStock ? 0.65 : 1.0,
                      child: Material(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: WarmPalette.line),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: isOutOfStock ? null : () => onAdd(item),
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
                                                errorBuilder: (_, _, _) => Center(
                                                  child: Icon(item.defaultIcon, size: 28, color: WarmPalette.primary),
                                                ),
                                              )
                                            : Center(
                                                child: Icon(item.defaultIcon, size: 28, color: WarmPalette.primary),
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
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
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
                                        color: isOutOfStock ? WarmPalette.danger : WarmPalette.tertiary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        isOutOfStock ? 'Stok Habis' : (item.stock >= 90 ? 'Tersedia' : 'Stok: ${item.stock.toInt()} porsi'),
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          color: isOutOfStock ? WarmPalette.danger : WarmPalette.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (item.sku.isNotEmpty)
                                      Text(
                                        item.sku,
                                        style: const TextStyle(fontSize: 9, color: WarmPalette.textTertiary, fontWeight: FontWeight.w600),
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
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: WarmPalette.textTertiary,
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
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: WarmPalette.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isOutOfStock)
                                      const CircleAvatar(
                                        radius: 13,
                                        backgroundColor: WarmPalette.surfaceMuted,
                                        child: Icon(Icons.block_rounded, size: 14, color: WarmPalette.textTertiary),
                                      )
                                    else
                                      CircleAvatar(
                                        radius: 13,
                                        backgroundColor: WarmPalette.primary.withValues(alpha: 0.12),
                                        child: const Icon(Icons.add, size: 16, color: WarmPalette.primary),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        _buildBottomBar(context),
      ],
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: content,
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final p = context.palette;
    final availableCount = ctrl.products.where((p) => p.stock > 0).length;
    final outOfStockCount = ctrl.products.where((p) => p.stock <= 0).length;
    final w = maxWidth ?? MediaQuery.sizeOf(context).width;

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: p.line)),
      ),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 7, color: WarmPalette.tertiary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Tersedia: $availableCount • Habis: $outOfStockCount',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: WarmPalette.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (ctrl.billing?.pb1Enabled == true) ...[
            const SizedBox(width: 8),
            const Text('|', style: TextStyle(color: WarmPalette.line)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Pajak Resto ${((ctrl.billing?.pb1Rate ?? 0) > 1 ? (ctrl.billing?.pb1Rate ?? 0) : (ctrl.billing?.pb1Rate ?? 0) * 100).round()}% Aktif (PB1)',
                style: const TextStyle(fontSize: 10, color: WarmPalette.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (w >= 900) ...[
            const Spacer(),
            const Text(
              'Shortcut: [F1] Espresso • [F2] Manual • [F3] Bakery',
              style: TextStyle(fontSize: 10, color: WarmPalette.textSecondary, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}
