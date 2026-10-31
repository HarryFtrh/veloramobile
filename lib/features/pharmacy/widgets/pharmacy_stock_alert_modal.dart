import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';

class PharmacyStockAlertItem {
  final String name;
  final String category;
  final String batchNumber;
  final String expiryDate;
  final int daysToExpiry;
  final int stock;
  final String unit;
  final num price;
  final bool isHardDrug;

  const PharmacyStockAlertItem({
    required this.name,
    required this.category,
    required this.batchNumber,
    required this.expiryDate,
    required this.daysToExpiry,
    required this.stock,
    required this.unit,
    required this.price,
    this.isHardDrug = false,
  });
}

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
          maxHeight: MediaQuery.of(context).size.height * 0.88,
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

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF006948);
    const canvasColor = Color(0xFFFAF8FF);

    // Olah data stok & batch dari katalog aktif
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
        days = parsedDate.difference(DateTime.now()).inDays;
      } else if (ed != '-' && ed.contains('/') && ed.split('/').length == 2) {
        // Handle format MM/YY e.g. 11/26
        final parts = ed.split('/');
        final m = int.tryParse(parts[0]) ?? 1;
        final y = (int.tryParse(parts[1]) ?? 26) + 2000;
        final d = DateTime(y, m, 28);
        days = d.difference(DateTime.now()).inDays;
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

    final filtered = items.where((it) {
      if (_filter == 'near_ed' && it.daysToExpiry > 90) return false;
      if (_filter == 'critical' && it.stock > 10) return false;
      if (_filter == 'rx' && !it.isHardDrug) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return it.name.toLowerCase().contains(q) ||
            it.batchNumber.toLowerCase().contains(q) ||
            it.category.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Container(
      decoration: const BoxDecoration(
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
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stok Obat & Alert ED (FEFO)',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: Color(0xFF131B2E),
                          ),
                        ),
                        Text(
                          'First-Expired First-Out Control System',
                          style: TextStyle(fontSize: 12, color: Color(0xFF6D7A72)),
                        ),
                      ],
                    ),
                  ],
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
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notification_important_rounded, color: Color(0xFFB45309), size: 20),
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
                            color: Color(0xFF92400E),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pastikan sediaan dengan tanggal kadaluarsa (ED) terdekat ditempatkan di rak depan dan didahulukan penjualannya.',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF78350F), height: 1.3),
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
              onChanged: (val) => setState(() => _search = val.trim()),
              decoration: InputDecoration(
                hintText: 'Cari obat, no batch, atau zat aktif...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF6D7A72)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6D7A72), size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
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
                      return _buildStockCard(it, primaryColor);
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
      onTap: () => setState(() => _filter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? primaryColor : const Color(0xFFE2E8F0),
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

  Widget _buildStockCard(PharmacyStockAlertItem item, Color primaryColor) {
    final isCritical = item.stock <= 10;
    final isNearExpiry = item.daysToExpiry <= 90;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNearExpiry
              ? const Color(0xFFFDE68A)
              : (isCritical ? const Color(0xFFFFCDD2) : const Color(0xFFE2E8F0)),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (item.isHardDrug) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFDAD6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Rx Keras',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFBA1A1A)),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF131B2E),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCritical ? const Color(0xFFFFEBEE) : const Color(0xFFF2F3FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Stok: ${item.stock} ${item.unit}',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: isCritical ? Colors.redAccent : primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.category,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF6D7A72)),
          ),
          const SizedBox(height: 8),

          // Batch & Expiry Strip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAEDFF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Batch: ${item.batchNumber}',
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF131B2E),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isNearExpiry ? const Color(0xFFFEF3C7) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isNearExpiry ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      'ED: ${item.expiryDate}',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isNearExpiry ? const Color(0xFFB45309) : const Color(0xFF6D7A72),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                CurrencyFormatter.format(item.price),
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
