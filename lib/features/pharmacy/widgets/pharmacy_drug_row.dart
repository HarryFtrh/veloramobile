import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import 'drug_card_components.dart';

/// Card Produk Apotek Mode Baris / List View (POS Kasir, Resep Racikan, EMR)
class PharmacyDrugRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;
  final Function(String unit)? onSelectUnit;

  const PharmacyDrugRow({
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
            : (item['description']?.toString() ?? item['sku']?.toString() ?? ''));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: isOutOfStock ? null : onAdd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isOutOfStock
                ? const Color(0xFFF8FAFC)
                : (quantity > 0 ? const Color(0xFFF9FDFB) : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isOutOfStock
                  ? borderColor
                  : (quantity > 0 ? primaryEmerald : borderColor),
              width: quantity > 0 && !isOutOfStock ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: isOutOfStock ? 0.01 : 0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Opacity(
            opacity: isOutOfStock ? 0.62 : 1.0,
            child: Row(
              children: [
                DrugThumbnailWidget(
                  item: item,
                  classification: classification,
                  size: 46,
                  primaryEmerald: primaryEmerald,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item['name'] ?? '',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          DrugClassBadge(
                            item: item,
                            classification: classification,
                          ),
                          if (stock <= 5) ...[
                            const SizedBox(width: 5),
                            DrugStockBadge(
                              stock: stock,
                              unit: selectedUnit,
                              primaryEmerald: primaryEmerald,
                            ),
                          ],
                        ],
                      ),
                      if (subInfo.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subInfo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5, color: textMuted),
                        ),
                      ],
                      const SizedBox(height: 5),
                      BatchExpBadge(
                        batch: batch,
                        ed: ed,
                        batchCount: batchCount,
                        isCompact: true,
                      ),
                      if (units.length > 1) ...[
                        const SizedBox(height: 5),
                        DrugUnitSelector(
                          units: units,
                          selectedUnit: selectedUnit,
                          isOutOfStock: isOutOfStock,
                          onSelectUnit: onSelectUnit,
                          primaryEmerald: primaryEmerald,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      CurrencyFormatter.format(currentPrice),
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        color: primaryEmerald,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '/$selectedUnit',
                      style: const TextStyle(color: textMuted, fontSize: 9.5),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                if (isOutOfStock)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.remove_shopping_cart_outlined, size: 13, color: Color(0xFF94A3B8)),
                        SizedBox(width: 4),
                        Text(
                          'Habis',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (quantity > 0)
                  Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: primaryEmerald.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: onRemove ?? onAdd,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Icon(Icons.remove, size: 14, color: textPrimary),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            '$quantity',
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: primaryEmerald,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: onAdd,
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: const BoxDecoration(
                              color: primaryEmerald,
                              borderRadius: BorderRadius.horizontal(right: Radius.circular(7)),
                            ),
                            child: const Icon(Icons.add, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: const Icon(Icons.add, size: 16, color: primaryEmerald),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
