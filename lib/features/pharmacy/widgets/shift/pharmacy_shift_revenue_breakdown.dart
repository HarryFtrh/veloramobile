import 'package:material_ui/material_ui.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/utils/currency_formatter.dart';
/// Breakdown of sales revenue per payment method for shift report
class PharmacyShiftRevenueBreakdown extends StatelessWidget {
  final num cashRevenue;
  final num qrisRevenue;
  final num debitRevenue;
  final num insuranceRevenue;

  const PharmacyShiftRevenueBreakdown({
    super.key,
    required this.cashRevenue,
    required this.qrisRevenue,
    required this.debitRevenue,
    required this.insuranceRevenue,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = context.palette.textPrimary;
    final textMuted = context.palette.textSecondary;
    final borderColor = context.palette.line;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rincian Penerimaan Penjualan',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              Text('Metode Bayar', style: TextStyle(fontSize: 11, color: textMuted)),
            ],
          ),
          const SizedBox(height: 12),
          _buildMethodRow('Tunai (Cash)', cashRevenue, Icons.money_rounded, const Color(0xFF059669)),
          Divider(height: 16, color: context.palette.surfaceMuted),
          _buildMethodRow('QRIS (Statis / Dinamis)', qrisRevenue, Icons.qr_code_2_rounded, const Color(0xFF0284C7)),
          Divider(height: 16, color: context.palette.surfaceMuted),
          _buildMethodRow('Kartu Debit / EDC', debitRevenue, Icons.credit_card_rounded, const Color(0xFF7C3AED)),
          Divider(height: 16, color: context.palette.surfaceMuted),
          _buildMethodRow('BPJS / Asuransi Rekanan', insuranceRevenue, Icons.verified_user_rounded, const Color(0xFF0D9488)),
        ],
      ),
    );
  }

  Widget _buildMethodRow(String name, num amount, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
          ],
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
