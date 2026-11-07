import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Hero revenue and basket average banner for shift report modal
class ShiftModalRevenueBanner extends StatelessWidget {
  final num totalRevenue;
  final int transactionCount;
  final int avgTrx;

  const ShiftModalRevenueBanner({
    super.key,
    required this.totalRevenue,
    required this.transactionCount,
    required this.avgTrx,
  });

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF059669);
    const borderColor = Color(0xFFE2E8F0);
    const textPrimary = Color(0xFF0F172A);
    const textMuted = Color(0xFF6D7A72);
    const tertiaryCyan = Color(0xFF0D9488);

    return Container(
      padding: const EdgeInsets.all(14),
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
              const Text(
                'Total Omzet Penjualan Shift',
                style: TextStyle(fontSize: 11.5, color: textMuted),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4F8E8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$transactionCount Transaksi Sukses',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: emeraldPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(totalRevenue),
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: emeraldPrimary,
            ),
          ),
          Text(
            'Rata-rata keranjang: ${CurrencyFormatter.format(avgTrx)} / trx',
            style: const TextStyle(fontSize: 11, color: textMuted),
          ),
          const SizedBox(height: 12),

          // Revenue Split Bar (Farmasi vs Layanan)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Breakdown Unit Penjualan', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textPrimary)),
              Text('Farmasi 58.6% • Layanan 41.4%', style: TextStyle(fontSize: 10.5, color: textMuted)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                Expanded(flex: 59, child: Container(height: 8, color: emeraldPrimary)),
                const SizedBox(width: 2),
                Expanded(flex: 41, child: Container(height: 8, color: tertiaryCyan)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.medication_rounded, size: 14, color: emeraldPrimary),
                          SizedBox(width: 4),
                          Text('Apotek / Farmasi', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: emeraldPrimary)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        CurrencyFormatter.format(totalRevenue * 0.586),
                        style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      const Text('22 Struk Obat / Resep', style: TextStyle(fontSize: 9.5, color: textMuted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.medical_services_rounded, size: 14, color: tertiaryCyan),
                          SizedBox(width: 4),
                          Text('Layanan & Dokter', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: tertiaryCyan)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        CurrencyFormatter.format(totalRevenue * 0.414),
                        style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      const Text('12 Tindakan Medis', style: TextStyle(fontSize: 9.5, color: textMuted)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
