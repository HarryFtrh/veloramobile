// features/fnb_customer/widgets/customer_cart_summary_card.dart
import '../../../core/utils/currency_formatter.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/tokens.dart';
import '../../fnb/billing.dart';

class CustomerCartSummaryCard extends StatelessWidget {
  const CustomerCartSummaryCard({
    super.key,
    required this.itemCount,
    required this.subtotal,
    required this.discount,
    this.voucherCode,
    required this.calculatedBill,
    this.taxName,
  });

  final int itemCount;
  final int subtotal;
  final int discount;
  final String? voucherCode;
  final BillBreakdown calculatedBill;
  final String? taxName;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_outlined,
                size: 18,
                color: primaryColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'Rincian Pembayaran',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SummaryRow(
            label: 'Subtotal ($itemCount item)',
            value: subtotal.toRupiah(),
          ),
          if (discount > 0)
            _SummaryRow(
              label: 'Diskon Promo (${voucherCode ?? "PROMO"})',
              value: '-${discount.toRupiah()}',
              isDiscount: true,
            ),
          if (calculatedBill.serviceCharge > 0)
            _SummaryRow(
              label: 'Biaya Layanan',
              value: calculatedBill.serviceCharge.toRupiah(),
            ),
          if (calculatedBill.tax > 0)
            _SummaryRow(
              label: 'Pajak (${taxName ?? 'PB1'})',
              value: calculatedBill.tax.toRupiah(),
            ),
          if (calculatedBill.rounding != 0)
            _SummaryRow(
              label: 'Pembulatan',
              value: calculatedBill.rounding.toRupiah(),
            ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isDiscount = false,
  });

  final String label;
  final String value;
  final bool isDiscount;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: p.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDiscount ? p.tertiary : p.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
