import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Top metric KPI cards and handover pair banner for shift report screen
class PharmacyShiftMetricCards extends StatelessWidget {
  final String? shiftId;
  final String cashierName;
  final String branchName;
  final num openingCash;
  final num totalRevenue;
  final num expectedTotalDrawer;
  final int transactionCount;

  const PharmacyShiftMetricCards({
    super.key,
    required this.shiftId,
    required this.cashierName,
    required this.branchName,
    required this.openingCash,
    required this.totalRevenue,
    required this.expectedTotalDrawer,
    required this.transactionCount,
  });

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF059669);
    const textMuted = Color(0xFF6D7A72);
    const borderColor = Color(0xFFE2E8F0);

    return Column(
      children: [
        // Handover Pair Card
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: Color(0xFF0284C7), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Sesi Serah Terima Shift Berlangsung',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                      ),
                    ],
                  ),
                  Text(
                    shiftId != null ? 'Shift #$shiftId' : 'Serah Terima Shift',
                    style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: FontWeight.bold, color: emeraldPrimary),
                  ),
                ],
              ),
              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('KASIR BERTUGAS', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: textMuted)),
                          const SizedBox(height: 3),
                          Text(cashierName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                          Text('Shift Aktif • $branchName', style: const TextStyle(fontSize: 10, color: textMuted)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SERAH TERIMA SHIFT', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: textMuted)),
                          SizedBox(height: 3),
                          Text('Kasir / Petugas Pengganti', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                          Text('Rekonsiliasi Kas Laci Berjalan', style: TextStyle(fontSize: 10, color: textMuted)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 4 KPI Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                  child: _buildMetricTile(
                    title: 'Modal Awal Kasir',
                    value: CurrencyFormatter.format(openingCash),
                    icon: Icons.account_balance_wallet_outlined,
                    accentColor: const Color(0xFF0D9488),
                  ),
                ),
                SizedBox(
                  width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                  child: _buildMetricTile(
                    title: 'Total Omzet Shift',
                    value: CurrencyFormatter.format(totalRevenue),
                    icon: Icons.payments_outlined,
                    accentColor: emeraldPrimary,
                  ),
                ),
                SizedBox(
                  width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                  child: _buildMetricTile(
                    title: 'Ekspektasi Kas Laci',
                    value: CurrencyFormatter.format(expectedTotalDrawer),
                    icon: Icons.point_of_sale_rounded,
                    accentColor: const Color(0xFF059669),
                  ),
                ),
                SizedBox(
                  width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                  child: _buildMetricTile(
                    title: 'Jumlah Transaksi',
                    value: '$transactionCount Resep',
                    icon: Icons.receipt_long_rounded,
                    accentColor: const Color(0xFF475569),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF6D7A72))),
              Icon(icon, size: 16, color: accentColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
