import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';

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
    const emeraldPrimary = Color(0xFF059669);
    const borderColor = Color(0xFFE2E8F0);
    const textMuted = Color(0xFF6D7A72);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal Obat', style: TextStyle(fontSize: 11, color: textMuted)),
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
              const Text('Metode Pembayaran', style: TextStyle(fontSize: 11, color: textMuted)),
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
          const Divider(height: 14, color: borderColor),
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
