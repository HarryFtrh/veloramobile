import 'package:flutter/material.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../shared_pos/pos_checkout_service.dart';

/// Mobile order summary card on checkout screen
class PharmacyCheckoutMobileSummary extends StatelessWidget {
  final String patientName;
  final String queueNumber;
  final List<PosCartItem> items;
  final num grandTotal;

  const PharmacyCheckoutMobileSummary({
    super.key,
    required this.patientName,
    required this.queueNumber,
    required this.items,
    required this.grandTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ClinicalPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pasien: $patientName',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: ClinicalPalette.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ClinicalPalette.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  queueNumber,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: ClinicalPalette.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${items.length} item obat terdaftar',
            style: const TextStyle(fontSize: 11, color: ClinicalPalette.textTertiary),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Tagihan', style: TextStyle(fontSize: 12, color: ClinicalPalette.textSecondary)),
              Text(
                CurrencyFormatter.formatRupiah(grandTotal),
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: ClinicalPalette.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
