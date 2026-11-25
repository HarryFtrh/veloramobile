import 'package:material_ui/material_ui.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/utils/audio_helper.dart';
import '../../pharmacy_colors.dart';

class OpnameItem {
  final String id;
  final String name;
  final String batchNumber;
  final String expiryDate;
  final int systemStock;
  int physicalStock;
  final num price;
  final String unit;

  OpnameItem({
    required this.id,
    required this.name,
    required this.batchNumber,
    required this.expiryDate,
    required this.systemStock,
    required this.physicalStock,
    required this.price,
    required this.unit,
  });

  int get difference => physicalStock - systemStock;
  num get differenceValue => difference * price;
}

/// Item card for Opname physical stock count audit
class PharmacyStockOpnameItemCard extends StatelessWidget {
  final OpnameItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const PharmacyStockOpnameItemCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = PharmacyColors.primary;
    final textPrimary = context.palette.textPrimary;
    final textMuted = context.palette.textSecondary;
    final borderColor = context.palette.line;

    final isDiff = item.difference != 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDiff ? const Color(0xFFBA1A1A).withValues(alpha: 0.5) : borderColor,
          width: isDiff ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDiff ? const Color(0xFFFFDAD6) : const Color(0xFF059669).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isDiff ? 'Selisih ${item.difference} ${item.unit}' : 'Cocok Sesuai',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: isDiff ? const Color(0xFFBA1A1A) : emeraldPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Lot Batch: ${item.batchNumber}  •  ED: ${item.expiryDate}',
            style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: textMuted),
          ),
          const SizedBox(height: 10),

          // Counter and System comparison
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Stok Buku Sistem:', style: TextStyle(fontSize: 10.5, color: textMuted)),
                  Text(
                    '${item.systemStock} ${item.unit}',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Fisik:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                    onPressed: item.physicalStock > 0
                        ? () {
                            AudioHelper.tapFeedback();
                            onDecrement();
                          }
                        : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Container(
                    width: 44,
                    alignment: Alignment.center,
                    child: Text(
                      '${item.physicalStock}',
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: emeraldPrimary),
                    onPressed: () {
                      AudioHelper.tapFeedback();
                      onIncrement();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
