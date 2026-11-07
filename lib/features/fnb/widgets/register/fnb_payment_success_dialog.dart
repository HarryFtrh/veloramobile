import 'package:flutter/material.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../shared_pos/receipt_printer_service.dart';

/// Success dialog after settlement in FnB POS with receipt printing and drawer trigger
class FnbPaymentSuccessDialog extends StatelessWidget {
  final String invoiceNumber;
  final num changeAmount;
  final ReceiptData finalReceipt;

  const FnbPaymentSuccessDialog({
    super.key,
    required this.invoiceNumber,
    required this.changeAmount,
    required this.finalReceipt,
  });

  static Future<void> show(
    BuildContext context, {
    required String invoiceNumber,
    required num changeAmount,
    required ReceiptData finalReceipt,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => FnbPaymentSuccessDialog(
        invoiceNumber: invoiceNumber,
        changeAmount: changeAmount,
        finalReceipt: finalReceipt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.palette.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.check_circle_rounded, color: context.palette.success, size: 24),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Pembayaran Berhasil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (invoiceNumber.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: context.palette.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.palette.line),
              ),
              child: Text(
                'No. Faktur: #$invoiceNumber',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.palette.textSecondary),
              ),
            ),
          if (changeAmount > 0) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.palette.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.palette.success.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UANG KEMBALIAN',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: context.palette.success),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(changeAmount),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: context.palette.success),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: Gap.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ReceiptPrinterService.instance.shareReceipt(finalReceipt),
                  icon: const Icon(Icons.share_rounded, size: 15),
                  label: const Text('Bagi (WA)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: Gap.xs),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ReceiptPrinterService.instance.printReceipt(finalReceipt);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Struk dikirim ke printer')));
                    }
                  },
                  icon: const Icon(Icons.print_outlined, size: 15),
                  label: const Text('Cetak Struk', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: Gap.xs),
              IconButton.outlined(
                tooltip: 'Buka laci kasir',
                onPressed: () async {
                  await ReceiptPrinterService.instance.openCashDrawer();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sinyal laci kasir dikirim')));
                  }
                },
                icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Pesanan Baru'),
        ),
      ],
    );
  }
}
