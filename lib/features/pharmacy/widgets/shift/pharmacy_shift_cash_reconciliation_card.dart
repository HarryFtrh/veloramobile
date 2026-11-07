import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Card for cash drawer physical counting, denomination modal trigger, and balance/discrepancy status
class PharmacyShiftCashReconciliationCard extends StatelessWidget {
  final TextEditingController countedCashController;
  final num discrepancy;
  final ValueChanged<String> onCountedCashChanged;
  final VoidCallback onOpenDenominationCalculator;

  const PharmacyShiftCashReconciliationCard({
    super.key,
    required this.countedCashController,
    required this.discrepancy,
    required this.onCountedCashChanged,
    required this.onOpenDenominationCalculator,
  });

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF059669);
    const textPrimary = Color(0xFF0F172A);
    const textMuted = Color(0xFF6D7A72);
    const borderColor = Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rekonsiliasi Fisik Uang Kas Laci',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hitung fisik uang tunai di laci kasir dan masukkan total untuk mengaudit selisih kas.',
            style: TextStyle(fontSize: 11.5, color: textMuted),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                flex: 5,
                child: TextField(
                  controller: countedCashController,
                  keyboardType: TextInputType.number,
                  onChanged: onCountedCashChanged,
                  decoration: InputDecoration(
                    labelText: 'Uang Fisik Dihitung (Rp)',
                    labelStyle: const TextStyle(fontSize: 12, color: textMuted),
                    prefixText: 'Rp ',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: emeraldPrimary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: discrepancy == 0
                        ? const Color(0xFFD4F8E8)
                        : (discrepancy < 0 ? const Color(0xFFFFDAD6) : const Color(0xFFE0F2FE)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        discrepancy == 0
                            ? 'Status: Seimbang (Pas)'
                            : (discrepancy < 0 ? 'Status: Kas Kurang' : 'Status: Kas Lebih'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: discrepancy == 0
                              ? const Color(0xFF059669)
                              : (discrepancy < 0 ? const Color(0xFFBA1A1A) : const Color(0xFF0369A1)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(discrepancy.abs()),
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: discrepancy == 0
                              ? const Color(0xFF059669)
                              : (discrepancy < 0 ? const Color(0xFFBA1A1A) : const Color(0xFF0369A1)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenDenominationCalculator,
              icon: const Icon(Icons.calculate_outlined, size: 16),
              label: const Text(
                'Hitung Pecahan Uang Kertas & Koin Laci',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: emeraldPrimary,
                side: const BorderSide(color: emeraldPrimary),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
