import 'package:material_ui/material_ui.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../shared_pos/services/pos_checkout_service.dart';
import '../../pharmacy_colors.dart';

/// Itemized prescription medicines list with batch and Tuslah fee
class PharmacyReceiptItemList extends StatelessWidget {
  final List<PosCartItem> items;
  final num tuslahFee;

  const PharmacyReceiptItemList({
    super.key,
    required this.items,
    required this.tuslahFee,
  });

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = PharmacyColors.primary;
    final borderColor = context.palette.line;
    final textPrimary = context.palette.textPrimary;
    final textMuted = context.palette.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.palette.canvas,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt_long, size: 14, color: emeraldPrimary),
                    SizedBox(width: 6),
                    Text(
                      'Rincian Obat & Resep',
                      style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  '${items.length} Item',
                  style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10.5, color: textMuted),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, _) => Divider(height: 12, color: borderColor),
            itemBuilder: (context, idx) {
              final item = items[idx];
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                        Text(
                          'Qty: ${item.quantity} • Batch: ${item.batchNumber ?? "-"}',
                          style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(item.price * item.quantity),
                    style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                ],
              );
            },
          ),
          if (tuslahFee > 0) ...[
            Divider(height: 1, color: borderColor),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Jasa Resep & Embalase (Tuslah)',
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                  Text(
                    CurrencyFormatter.format(tuslahFee),
                    style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
