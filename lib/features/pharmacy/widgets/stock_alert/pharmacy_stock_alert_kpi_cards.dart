import 'package:flutter/material.dart';

/// Top KPI metric cards for Pharmacy Stock & FEFO Expiry Alert screen
class PharmacyStockAlertKpiCards extends StatelessWidget {
  final int criticalCount;
  final int warningCount;
  final int lowStockCount;

  const PharmacyStockAlertKpiCards({
    super.key,
    required this.criticalCount,
    required this.warningCount,
    required this.lowStockCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildKpiCard(
              label: 'ED < 30 Hari',
              value: '$criticalCount Batch',
              color: const Color(0xFFBA1A1A),
              bg: const Color(0xFFFFDAD6),
              icon: Icons.error_outline_rounded,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildKpiCard(
              label: 'ED < 90 Hari',
              value: '$warningCount Batch',
              color: const Color(0xFFEA580C),
              bg: const Color(0xFFFFF7ED),
              icon: Icons.warning_amber_rounded,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildKpiCard(
              label: 'Stok Menipis',
              value: '$lowStockCount Obat',
              color: const Color(0xFF0D9488),
              bg: const Color(0xFFE0F2FE),
              icon: Icons.inventory_2_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required Color color,
    required Color bg,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
