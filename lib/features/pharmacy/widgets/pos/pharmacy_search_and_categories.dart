import 'package:flutter/material.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/utils/audio_helper.dart';

/// Bilah Pencarian & Filter Kategori Obat di POS Apotek
class PharmacySearchAndCategories extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final bool isSearchingRemote;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onClearSearch;
  final VoidCallback onOpenBarcodeScanner;
  final List<String> categories;
  final int selectedCategoryIndex;
  final ValueChanged<int> onSelectCategory;

  const PharmacySearchAndCategories({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.isSearchingRemote,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onClearSearch,
    required this.onOpenBarcodeScanner,
    required this.categories,
    required this.selectedCategoryIndex,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = ClinicalPalette.primary;
    const borderColor = Color(0xFFE2E8F0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              onSubmitted: onSearchSubmitted,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Cari obat, SKU, kandungan zat aktif, atau scan barcode...',
                hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSearchingRemote)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: emeraldPrimary,
                          ),
                        ),
                      ),
                    if (searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 15, color: Color(0xFF94A3B8)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        onPressed: onClearSearch,
                      ),
                    InkWell(
                      onTap: onOpenBarcodeScanner,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.qr_code_scanner_rounded, size: 14, color: Color(0xFF475569)),
                            SizedBox(width: 4),
                            Text(
                              'Scan',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 2. Category Tabs
        Container(
          height: 38,
          padding: const EdgeInsets.only(bottom: 6),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, idx) {
              final isSelected = idx == selectedCategoryIndex;
              final catName = categories[idx];
              final catLower = catName.toLowerCase();
              final isRx = catLower.contains('keras') || catLower.contains('rx');
              final isBebasTerbatas = catLower.contains('terbatas');
              final isBebas = catLower.contains('bebas') && !isBebasTerbatas;

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    AudioHelper.tapFeedback();
                    onSelectCategory(idx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF059669), Color(0xFF0D9488)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : borderColor,
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: emeraldPrimary.withValues(alpha: 0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isSelected) ...[
                          if (isRx)
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 5),
                              decoration: const BoxDecoration(
                                color: Color(0xFFDC2626),
                                shape: BoxShape.circle,
                              ),
                            )
                          else if (isBebasTerbatas)
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 5),
                              decoration: const BoxDecoration(
                                color: Color(0xFF2563EB),
                                shape: BoxShape.circle,
                              ),
                            )
                          else if (isBebas)
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 5),
                              decoration: const BoxDecoration(
                                color: Color(0xFF16A34A),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                        Text(
                          catName,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
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
