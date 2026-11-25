import 'package:material_ui/material_ui.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../pharmacy_colors.dart';

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
    const emeraldPrimary = PharmacyColors.primary;
    final borderColor = context.palette.line;
    final textPrimary = context.palette.textPrimary;
    final textMuted = context.palette.textSecondary;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.palette.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total PO Periode Ini', style: TextStyle(fontSize: 11, color: textMuted)),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(totalPoAmount),
                  style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13.5, fontWeight: FontWeight.bold, color: textPrimary),
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
              color: context.palette.surface,
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
                  style: TextStyle(fontSize: 10, color: textMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
