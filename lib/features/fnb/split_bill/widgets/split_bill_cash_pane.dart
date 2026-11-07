import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';

class SplitBillCashPane extends StatelessWidget {
  const SplitBillCashPane({
    super.key,
    required this.isPaymentSufficient,
    required this.changeAmount,
    required this.selectedItemsTotal,
    required this.cashReceived,
    required this.submitting,
    required this.onFinishPayment,
  });

  final bool isPaymentSufficient;
  final int changeAmount;
  final int selectedItemsTotal;
  final int cashReceived;
  final bool submitting;
  final VoidCallback onFinishPayment;

  Widget _buildPriceRow(BuildContext context, String label, String value, {bool isPositive = false}) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: p.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isPositive ? p.tertiary : p.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: p.tertiary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calculate_outlined,
                      color: p.tertiary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'KALKULASI KASIR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: p.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isPaymentSufficient
                      ? p.tertiary.withValues(alpha: 0.1)
                      : p.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      'KEMBALIAN KONSUMEN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isPaymentSufficient
                            ? p.tertiary
                            : p.danger,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Rp ${changeAmount.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: isPaymentSufficient
                              ? p.tertiary
                              : p.danger,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isPaymentSufficient
                              ? Icons.check_circle_rounded
                              : Icons.warning_amber_rounded,
                          size: 14,
                          color: isPaymentSufficient
                              ? p.tertiary
                              : p.danger,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPaymentSufficient
                              ? 'Pembayaran Cukup'
                              : 'Uang Kurang',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isPaymentSufficient
                              ? p.tertiary
                              : p.danger,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildPriceRow(
                context,
                'Tagihan Bersih:',
                'Rp ${selectedItemsTotal.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
              ),
              _buildPriceRow(
                context,
                'Uang Fisik Diterima:',
                'Rp ${cashReceived.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
              ),
              _buildPriceRow(
                context,
                'Status Laci Kas:',
                'Siap Otomatis Buka',
                isPositive: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: isPaymentSufficient && !submitting
                ? onFinishPayment
                : null,
            icon: submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.print_rounded, size: 20),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                submitting
                    ? 'Memproses Transaksi...'
                    : 'Selesaikan & Cetak Struk',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}
