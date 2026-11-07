import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';

/// KPI Summary counters for PBF orders & procurement
class PharmacyPbfOrderKpiCard extends StatelessWidget {
  final num totalPoAmount;
  final int totalPoCount;
  final int uniquePbfCount;
  final num dueSoonAmount;
  final int dueSoonCount;

  const PharmacyPbfOrderKpiCard({
    super.key,
    required this.totalPoAmount,
    required this.totalPoCount,
    required this.uniquePbfCount,
    required this.dueSoonAmount,
    required this.dueSoonCount,
  });

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF059669);
    const borderColor = Color(0xFFE2E8F0);
    const textPrimary = Color(0xFF0F172A);
    const textMuted = Color(0xFF6D7A72);

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total PO Periode Ini', style: TextStyle(fontSize: 11, color: textMuted)),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(totalPoAmount),
                  style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13.5, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                Text(
                  '$totalPoCount Faktur • $uniquePbfCount PBF',
                  style: const TextStyle(fontSize: 10, color: emeraldPrimary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: const Border(left: BorderSide(color: Color(0xFFBA1A1A), width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Jatuh Tempo Segera', style: TextStyle(fontSize: 11, color: Color(0xFFBA1A1A), fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(dueSoonAmount),
                  style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFFBA1A1A)),
                ),
                Text(
                  '$dueSoonCount Faktur Segera Bayar',
                  style: const TextStyle(fontSize: 10, color: textMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
