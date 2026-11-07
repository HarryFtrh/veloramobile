import 'package:flutter/material.dart';
import '../../../../core/design/tokens.dart';
import '../../../shared_pos/product_catalog_service.dart';
import '../../fnb_register_controller.dart';

/// Top search bar with barcode scan and hold action buttons for FnB Catalog
class FnbCatalogSearchBar extends StatelessWidget {
  final RegisterController ctrl;
  final void Function(PosProduct) onAdd;
  final VoidCallback? onHold;
  final VoidCallback? onOpenBills;

  const FnbCatalogSearchBar({
    super.key,
    required this.ctrl,
    required this.onAdd,
    this.onHold,
    this.onOpenBills,
  });

  void _openBarcodeScanner(BuildContext context) {
    final barcodeCtrl = TextEditingController();
    String? localError;

    showDialog<void>(
      context: context,
      builder: (dCtx) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.qr_code_scanner_rounded, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Pindai Barcode / SKU', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isMobile = context.isMobile;

    return Padding(
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
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryColor, width: 1.5)),
              ),
            ),
          ),
          const SizedBox(width: Gap.xs + 2),
          OutlinedButton.icon(
            onPressed: () => _openBarcodeScanner(context),
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
            label: Text(isMobile ? 'Scan' : 'Scan Barcode', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              minimumSize: const Size(0, 40),
              side: BorderSide(color: p.line),
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
                        backgroundColor: primaryColor,
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
                        foregroundColor: p.textPrimary,
                        minimumSize: const Size(0, 40),
                        side: BorderSide(color: p.line),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: 10),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
