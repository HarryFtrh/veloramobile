import 'package:flutter/material.dart';
import '../pharmacy_drug_card.dart';

/// Catalog View for Pharmacy POS Screen: handles loading, remote searching, empty states, and Grid/List switching
class PharmacyCatalogView extends StatelessWidget {
  final bool isLoading;
  final bool isSearchingRemote;
  final String searchQuery;
  final List<Map<String, dynamic>> items;
  final bool isGridView;
  final bool isMobile;
  final int Function(dynamic id) getCartQuantity;
  final void Function(String id) onAddToCart;
  final void Function(String id) onRemoveFromCart;
  final void Function(String id, String unit) onSelectUnit;
  final VoidCallback onSyncCatalog;

  const PharmacyCatalogView({
    super.key,
    required this.isLoading,
    required this.isSearchingRemote,
    required this.searchQuery,
    required this.items,
    required this.isGridView,
    required this.isMobile,
    required this.getCartQuantity,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.onSelectUnit,
    required this.onSyncCatalog,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF059669)),
            SizedBox(height: 16),
            Text(
              'Menghubungkan ke Database Velora...',
              style: TextStyle(color: Color(0xFF6D7A72), fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty && isSearchingRemote) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF059669)),
            const SizedBox(height: 14),
            Text(
              'Mencari "$searchQuery" di Katalog & Indikasi Obat...',
              style: const TextStyle(color: Color(0xFF6D7A72), fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication_liquid_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              searchQuery.isNotEmpty
                  ? 'Tidak ada obat yang cocok dengan "$searchQuery"'
                  : 'Katalog Obat Belum Terisi',
              style: const TextStyle(
                color: Color(0xFF6D7A72),
                fontSize: 13,
                fontWeight: FontWeight.normal,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onSyncCatalog,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Sinkronkan Katalog Obat'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF059669),
                side: const BorderSide(color: Color(0xFF059669)),
              ),
            ),
          ],
        ),
      );
    }

    if (isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: isMobile ? 220 : 250,
          childAspectRatio: isMobile ? 0.62 : 0.68,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final idStr = item['id'].toString();
          final qty = getCartQuantity(idStr);
          return PharmacyDrugCard(
            item: item,
            quantity: qty,
            onAdd: () => onAddToCart(idStr),
            onRemove: () => onRemoveFromCart(idStr),
            onSelectUnit: (unit) => onSelectUnit(idStr, unit),
          );
        },
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final idStr = item['id'].toString();
        final qty = getCartQuantity(idStr);
        return PharmacyDrugRow(
          item: item,
          quantity: qty,
          onAdd: () => onAddToCart(idStr),
          onRemove: () => onRemoveFromCart(idStr),
          onSelectUnit: (unit) => onSelectUnit(idStr, unit),
        );
      },
    );
  }
}
