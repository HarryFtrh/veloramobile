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

  Widget _buildPriceRow(String label, String value, {bool isPositive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: WarmPalette.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isPositive ? WarmPalette.tertiary : WarmPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: WarmPalette.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: WarmPalette.tertiary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calculate_outlined,
                      color: WarmPalette.tertiary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'KALKULASI KASIR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: WarmPalette.textSecondary,
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
                      ? WarmPalette.tertiary.withValues(alpha: 0.1)
                      : WarmPalette.danger.withValues(alpha: 0.1),
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
                            ? WarmPalette.tertiary
                            : WarmPalette.danger,
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
                              ? WarmPalette.tertiary
                              : WarmPalette.danger,
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
                              ? WarmPalette.tertiary
                              : WarmPalette.danger,
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
                              ? WarmPalette.tertiary
                              : WarmPalette.danger,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildPriceRow(
                'Tagihan Bersih:',
                'Rp ${selectedItemsTotal.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
              ),
              _buildPriceRow(
                'Uang Fisik Diterima:',
                'Rp ${cashReceived.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
              ),
              _buildPriceRow(
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
              backgroundColor: WarmPalette.primary,
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
