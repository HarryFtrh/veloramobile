import 'package:material_ui/material_ui.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../pharmacy_colors.dart';

/// Financial totals breakdown for pharmacy checkout receipt
class PharmacyReceiptFinancialBreakdown extends StatelessWidget {
  final num subtotal;
  final String paymentMethod;
  final num grandTotal;

  const PharmacyReceiptFinancialBreakdown({
    super.key,
    required this.subtotal,
    required this.paymentMethod,
    required this.grandTotal,
  });

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = PharmacyColors.primary;
    final borderColor = context.palette.line;
    final textMuted = context.palette.textSecondary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal Obat', style: TextStyle(fontSize: 11, color: textMuted)),
              Text(
                CurrencyFormatter.format(subtotal),
                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Metode Pembayaran', style: TextStyle(fontSize: 11, color: textMuted)),
              Text(
                paymentMethod.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D9488),
                ),
              ),
            ],
          ),
          Divider(height: 14, color: borderColor),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL SETTLEMENT',
                style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              Text(
                CurrencyFormatter.format(grandTotal),
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: emeraldPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
