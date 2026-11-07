import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';

/// KPI summary strip for Pharmacy Stock Opname Workstation
class PharmacyStockOpnameKpiStrip extends StatelessWidget {
  final int totalItems;
  final int totalSystemQty;
  final int totalPhysicalQty;
  final int totalDiffQty;
  final num totalDiffValue;

  const PharmacyStockOpnameKpiStrip({
    super.key,
    required this.totalItems,
    required this.totalSystemQty,
    required this.totalPhysicalQty,
    required this.totalDiffQty,
    required this.totalDiffValue,
  });

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF059669);

    return Container(
      padding: const EdgeInsets.all(14),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildMetricTile(
              label: 'Total Batch',
              value: '$totalItems Lot',
              color: emeraldPrimary,
              bg: emeraldPrimary.withValues(alpha: 0.08),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricTile(
              label: 'Stok Sistem',
              value: '$totalSystemQty Unit',
              color: const Color(0xFF0D9488),
              bg: const Color(0xFFE0F2FE),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricTile(
              label: 'Stok Fisik',
              value: '$totalPhysicalQty Unit',
              color: totalDiffQty == 0 ? emeraldPrimary : const Color(0xFFEA580C),
              bg: totalDiffQty == 0 ? const Color(0xFFD4F8E8) : const Color(0xFFFFF7ED),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricTile(
              label: 'Selisih Nilai',
              value: CurrencyFormatter.format(totalDiffValue),
              color: totalDiffValue == 0
                  ? emeraldPrimary
                  : (totalDiffValue < 0 ? const Color(0xFFBA1A1A) : const Color(0xFF0284C7)),
              bg: totalDiffValue == 0
                  ? const Color(0xFFD4F8E8)
                  : (totalDiffValue < 0 ? const Color(0xFFFFDAD6) : const Color(0xFFE0F2FE)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
