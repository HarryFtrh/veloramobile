import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Top fast moving medicines list card
class PharmacyExecutiveTopMedicines extends StatelessWidget {
  final List<Map<String, dynamic>> topMedicines;

  const PharmacyExecutiveTopMedicines({
    super.key,
    required this.topMedicines,
  });

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF059669);
    const textMuted = Color(0xFF6D7A72);
    const borderColor = Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Top Fast-Moving Medicines', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 14)),
              Text('Performa Live', style: TextStyle(fontSize: 11, color: emeraldPrimary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),

          if (topMedicines.isNotEmpty)
            ...topMedicines.map((med) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(med['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Volume: ${med['sales']}', style: const TextStyle(fontSize: 11, color: textMuted)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(med['revenue'] as num),
                          style: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(med['growth'] as String, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: emeraldPrimary)),
                      ],
                    ),
                  ],
                ),
              );
            })
          else
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: const Text('Belum ada obat terjual pada periode ini.', style: TextStyle(color: textMuted, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
