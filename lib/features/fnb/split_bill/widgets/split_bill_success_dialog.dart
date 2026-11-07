import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../../../shared_pos/receipt_printer_service.dart';

class SplitBillSuccessDialog extends StatelessWidget {
  const SplitBillSuccessDialog({
    super.key,
    required this.hasRemainingSplit,
    required this.invoiceNumber,
    required this.selectedMethod,
    required this.selectedItemsTotal,
    required this.changeAmount,
    required this.splitMode,
    required this.remainingItemsCount,
    required this.paxToPay,
    required this.paxCount,
    required this.receiptData,
    required this.onContinueSplit,
    required this.onDone,
  });

  final bool hasRemainingSplit;
  final String invoiceNumber;
  final String selectedMethod;
  final int selectedItemsTotal;
  final int changeAmount;
  final String splitMode;
  final int remainingItemsCount;
  final int paxToPay;
  final int paxCount;
  final ReceiptData receiptData;
  final VoidCallback onContinueSplit;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AlertDialog(
      backgroundColor: p.canvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: p.line, width: 1.2),
      ),
      title: Row(
        children: [
          Icon(
            hasRemainingSplit ? Icons.call_split_rounded : Icons.check_circle_rounded,
            color: hasRemainingSplit ? p.secondary : p.tertiary,
            size: 26,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              hasRemainingSplit ? 'Split Bill Berhasil!' : 'Pembayaran Berhasil!',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: p.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.dialogMaxWidth),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nomor Struk: $invoiceNumber', style: TextStyle(fontWeight: FontWeight.w600, color: p.textPrimary)),
              const SizedBox(height: 4),
              Text('Metode: ${selectedMethod.toUpperCase()}', style: TextStyle(color: p.textSecondary)),
              const SizedBox(height: 4),
              Text(
                'Total Sesi Ini: Rp ${selectedItemsTotal.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                style: TextStyle(fontWeight: FontWeight.w700, color: primaryColor),
              ),
              if (selectedMethod == 'cash') ...[
                const SizedBox(height: 4),
                Text(
                  'Kembalian: Rp ${changeAmount.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                  style: TextStyle(fontWeight: FontWeight.w600, color: p.tertiary),
                ),
              ],
              const SizedBox(height: 12),
              if (hasRemainingSplit) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.secondary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: p.secondary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          splitMode == 'item'
                              ? 'Masih ada $remainingItemsCount jenis item tagihan yang belum lunas.'
                              : 'Telah dibayar $paxToPay dari $paxCount orang (Sisa ${paxCount - paxToPay} orang belum bayar).',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.secondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.line),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, size: 20, color: primaryColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Laci kasir otomatis dibuka & transaksi tersimpan rapi.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actionsOverflowButtonSpacing: 8,
      actionsOverflowDirection: VerticalDirection.down,
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => ReceiptPrinterService.instance.shareReceipt(receiptData),
                icon: const Icon(Icons.share_rounded, size: 16),
                label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Bagi Nota')),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ReceiptPrinterService.instance.printReceipt(receiptData);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Perintah cetak dikirim ke thermal printer')),
                    );
                  }
                },
                icon: const Icon(Icons.print_rounded, size: 16),
                label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Cetak Struk')),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        ),
        if (hasRemainingSplit) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onContinueSplit();
              },
              icon: const Icon(Icons.sync_alt_rounded, size: 16),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Lanjut Bayar Sisa Item (Split Berikutnya)', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: p.secondary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDone();
              },
              child: Text('Keluar (Sisa Tagihan Nanti)', style: TextStyle(color: p.textSecondary)),
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDone();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              child: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ],
    );
  }
}
