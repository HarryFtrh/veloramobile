import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import 'drug_card_components.dart';

export 'drug_card_components.dart';
export 'pharmacy_drug_row.dart';

/// Card Produk Apotek Mode Grid (POS Kasir, Resep Racikan, EMR)
/// Desain modern terinspirasi kartu showcase (Banner Gambar proporsional + Pill Harga + Deskripsi + Chips + Tombol Full Width)
class PharmacyDrugCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;
  final Function(String unit)? onSelectUnit;

  const PharmacyDrugCard({
    super.key,
    required this.item,
    required this.quantity,
    required this.onAdd,
    this.onRemove,
    this.onSelectUnit,
  });

  @override
  Widget build(BuildContext context) {
    const primaryEmerald = Color(0xFF059669);
    const borderColor = Color(0xFFE2E8F0);
    const textPrimary = Color(0xFF0F172A);
    const textMuted = Color(0xFF64748B);

    final classification = DrugClassification.fromItem(item);

    final rawUnits = item['units'];
    final List<Map<String, dynamic>> units = (rawUnits is List)
        ? rawUnits.whereType<Map<String, dynamic>>().toList()
        : [];
    final selectedUnit = item['selectedUnit']?.toString() ?? item['unit']?.toString() ?? 'TAB';

    num currentPrice = (item['price'] as num? ?? 0);
    for (final u in units) {
      if (u['name']?.toString().toUpperCase() == selectedUnit.toUpperCase()) {
        currentPrice = (u['price'] as num?) ?? currentPrice;
        break;
      }
    }

    final stock = (item['stock'] as num? ?? 0).toInt();
    final bool isOutOfStock = stock <= 0;
    final batch = item['batch']?.toString() ?? item['batchNumber']?.toString() ?? '-';
    final ed = item['ed']?.toString() ?? item['expiryDate']?.toString() ?? '-';
    final batchCount = (item['batchCount'] as num?)?.toInt() ??
        (item['batches'] is List ? (item['batches'] as List).length : 1);

    final subInfo = item['kandungan']?.toString().isNotEmpty == true
        ? item['kandungan'].toString()
        : (item['fungsi']?.toString().isNotEmpty == true
            ? item['fungsi'].toString()
            : (item['description']?.toString() ?? item['sku']?.toString() ?? 'Sediaan Farmasi'));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isOutOfStock ? null : onAdd,
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: isOutOfStock
                ? const Color(0xFFF8FAFC)
                : (quantity > 0 ? const Color(0xFFF9FDFB) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOutOfStock
                  ? borderColor
                  : (quantity > 0 ? primaryEmerald : const Color(0xFFE2E8F0)),
              width: quantity > 0 && !isOutOfStock ? 1.5 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Opacity(
            opacity: isOutOfStock ? 0.62 : 1.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Gambar Produk Proporsional (Anti-Lonjong dengan AspectRatio seimbang)
                AspectRatio(
                  aspectRatio: 1.22,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      color: const Color(0xFFF1F5F9),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          DrugThumbnailWidget(
                            item: item,
                            classification: classification,
                            borderRadius: BorderRadius.circular(12),
                            primaryEmerald: primaryEmerald,
                          ),
                          // Floating Golongan BPOM (Top-Left)
                          Positioned(
                            top: 7,
                            left: 7,
                            child: DrugClassBadge(
                              item: item,
                              classification: classification,
                            ),
                          ),
                          // Floating Sisa Stok (Top-Right)
                          Positioned(
                            top: 7,
                            right: 7,
                            child: DrugStockBadge(
                              stock: stock,
                              unit: item['unit']?.toString() ?? 'UNIT',
                              primaryEmerald: primaryEmerald,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 7),

                // 2. Nama Obat Dipisah dari Harga (Bisa 2 baris agar nama panjang tidak terpotong)
                Text(
                  item['name'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: textPrimary,
                    height: 1.22,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),

                // 3. Baris Harga Kapsul Hitam & SKU Produk
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        CurrencyFormatter.format(currentPrice),
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item['sku']?.toString().isNotEmpty == true && item['sku'] != '-'
                            ? item['sku'].toString()
                            : subInfo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 9.5,
                          color: textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // 4. Baris Batch / ED Asli (FEFO)
                BatchExpBadge(
                  batch: batch,
                  ed: ed,
                  batchCount: batchCount,
                  isCompact: true,
                ),

                // 5. Multi-Satuan Selector Pills (TABLET, STRIP, BOX dll)
                if (units.length > 1) ...[
                  const SizedBox(height: 4),
                  DrugUnitSelector(
                    units: units,
                    selectedUnit: selectedUnit,
                    isOutOfStock: isOutOfStock,
                    onSelectUnit: onSelectUnit,
                    primaryEmerald: primaryEmerald,
                  ),
                ],

                // Jarak dinamis halus sebelum tombol
                const Spacer(),

                // 6. Tombol Aksi Full Width (+ Tambah / Stepper / Stok Habis)
                DrugQuantityButton(
                  quantity: quantity,
                  isOutOfStock: isOutOfStock,
                  onAdd: onAdd,
                  onRemove: onRemove,
                  primaryEmerald: primaryEmerald,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
