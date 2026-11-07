import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Drug revenue contribution by category with multi-segment bar
class PharmacyExecutiveCategoryBreakdown extends StatelessWidget {
  final List<Map<String, dynamic>> categoryShare;

  const PharmacyExecutiveCategoryBreakdown({
    super.key,
    required this.categoryShare,
  });

  @override
  Widget build(BuildContext context) {
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
              Text(
                'Kontribusi Omzet per Kategori Obat',
                style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text('Share %', style: TextStyle(fontSize: 11, color: textMuted)),
            ],
          ),
          const SizedBox(height: 14),

          if (categoryShare.isNotEmpty) ...[
            // Multi-segment progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Row(
                children: categoryShare.map((cat) {
                  final pct = (cat['pct'] as int?) ?? 1;
                  return Expanded(
                    flex: pct > 0 ? pct : 1,
                    child: Container(height: 12, color: cat['color'] as Color),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            ...categoryShare.map((cat) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: cat['color'] as Color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(cat['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                    Text('${cat['pct']}%', style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Text(
                      CurrencyFormatter.format(cat['value'] as num),
                      style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ] else
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: const Text('Belum ada data penjualan obat per kategori pada periode ini.', style: TextStyle(color: textMuted, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
