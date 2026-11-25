import 'dart:async';
import '../../../core/design/tokens.dart';
import 'package:material_ui/material_ui.dart';
import 'stock_alert/pharmacy_stock_alert_modal_card.dart';
import '../pharmacy_colors.dart';

export 'stock_alert/pharmacy_stock_alert_modal_card.dart';

class PharmacyStockAlertModal extends StatefulWidget {
  final List<Map<String, dynamic>> catalogItems;
  final Function(String id)? onSelectDrug;

  const PharmacyStockAlertModal({
    super.key,
    required this.catalogItems,
    this.onSelectDrug,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Map<String, dynamic>> catalogItems,
    Function(String id)? onSelectDrug,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          maxWidth: 620,
        ),
        child: PharmacyStockAlertModal(
          catalogItems: catalogItems,
          onSelectDrug: onSelectDrug,
        ),
      ),
    );
  }

  @override
  State<PharmacyStockAlertModal> createState() => _PharmacyStockAlertModalState();
}

class _PharmacyStockAlertModalState extends State<PharmacyStockAlertModal> {
  String _filter = 'all'; // 'all', 'near_ed', 'critical', 'rx'
  String _search = '';
  Timer? _searchDebounce;
  List<PharmacyStockAlertItem> _allItems = const [];
  List<PharmacyStockAlertItem> _filteredItems = const [];

  @override
  void initState() {
    super.initState();
    _rebuildItems();
  }

  @override
  void didUpdateWidget(covariant PharmacyStockAlertModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.catalogItems != widget.catalogItems) {
      _rebuildItems();
    }
  }

  void _rebuildItems() {
    final now = DateTime.now();
    final List<PharmacyStockAlertItem> items = [];
    for (final it in widget.catalogItems) {
      final name = it['name']?.toString() ?? 'Obat';
      final cat = it['category']?.toString() ?? 'Umum';
      final batch = it['batch']?.toString() ?? '-';
      final ed = it['ed']?.toString() ?? '-';
      final stock = (it['stock'] as num? ?? 0).toInt();
      final price = (it['price'] as num? ?? 0);
      final isRx = it['isDotRed'] == true;

      // Kalkulasi hari menuju ED berdasarkan tanggal batch nyata
      int days = 999;
      final parsedDate = ed != '-' ? DateTime.tryParse(ed) : null;
      if (parsedDate != null) {
        days = parsedDate.difference(now).inDays;
      } else if (ed != '-' && ed.contains('/') && ed.split('/').length == 2) {
        final parts = ed.split('/');
        final m = int.tryParse(parts[0]) ?? 1;
        final y = (int.tryParse(parts[1]) ?? 26) + 2000;
        final d = DateTime(y, m, 28);
        days = d.difference(now).inDays;
      }

      items.add(
        PharmacyStockAlertItem(
          name: name,
          category: cat,
          batchNumber: batch,
          expiryDate: ed,
          daysToExpiry: days,
          stock: stock,
          unit: 'pcs',
          price: price,
          isHardDrug: isRx,
        ),
      );
    }
    _allItems = items;
    _recomputeFiltered();
  }

  void _recomputeFiltered() {
    final q = _search.toLowerCase();
    _filteredItems = _allItems.where((it) {
      if (_filter == 'near_ed' && it.daysToExpiry > 90) return false;
      if (_filter == 'critical' && it.stock > 10) return false;
      if (_filter == 'rx' && !it.isHardDrug) return false;
      if (q.isNotEmpty) {
        return it.name.toLowerCase().contains(q) ||
            it.batchNumber.toLowerCase().contains(q) ||
            it.category.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    final trimmed = val.trim();
    _searchDebounce?.cancel();
    if (trimmed.isEmpty) {
      setState(() {
        _search = '';
        _recomputeFiltered();
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (mounted) {
        setState(() {
          _search = trimmed;
          _recomputeFiltered();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = PharmacyColors.primary;
    final canvasColor = context.palette.canvas;

    final items = _allItems;
    final filtered = _filteredItems;

    return Container(
      decoration: BoxDecoration(
        color: canvasColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFBCCAC0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFED7AA), width: 0.8),
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stok Obat & Alert ED (FEFO)',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: context.palette.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'First-Expired First-Out Control System',
                              style: TextStyle(fontSize: 12, color: Color(0xFF6D7A72)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF6D7A72)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Alert Banner (Stitch design component)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notification_important_rounded, color: Color(0xFFEA580C), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Peringatan Kadaluarsa & Stok Kritis!',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Color(0xFFC2410C),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pastikan sediaan dengan tanggal kadaluarsa (ED) terdekat ditempatkan di rak depan dan didahulukan penjualannya.',
                          style: TextStyle(fontSize: 11.5, color: context.palette.textSecondary, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari obat, no batch, atau zat aktif...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF6D7A72)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6D7A72), size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                filled: true,
                fillColor: context.palette.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.palette.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryColor, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildChip('all', 'Semua Stok (${items.length})', primaryColor),
                const SizedBox(width: 8),
                _buildChip('near_ed', 'Mendekati ED', primaryColor),
                const SizedBox(width: 8),
                _buildChip('critical', 'Stok Kritis (≤10)', primaryColor),
                const SizedBox(width: 8),
                _buildChip('rx', 'Resep Keras (Rx)', primaryColor),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Stock List
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada obat yang cocok dengan filter.',
                      style: TextStyle(color: Color(0xFF6D7A72)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, idx) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final it = filtered[i];
                      return PharmacyStockAlertModalCard(item: it, primaryColor: primaryColor);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String key, String label, Color primaryColor) {
    final active = _filter == key;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() {
        _filter = key;
        _recomputeFiltered();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? primaryColor : context.palette.line,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? Colors.white : const Color(0xFF3D4A42),
          ),
        ),
      ),
    );
  }
}
