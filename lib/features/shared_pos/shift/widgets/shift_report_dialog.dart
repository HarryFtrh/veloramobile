import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../receipt_printer_service.dart';
import '../../shift_service.dart';
import 'shift_dialog_helpers.dart';

/// Modal dialog showing the finalized Z-Report summary when a shift is closed.
Future<void> showShiftReportModal(
  BuildContext context,
  ShiftCloseSummary summary, {
  required VoidCallback onDone,
}) async {
  String dateFmt(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  final isMobile = context.isMobile;
  final p = context.palette;
  final primaryColor = Theme.of(context).colorScheme.primary;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return Dialog(
        backgroundColor: p.canvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: p.line, width: 1.5),
        ),
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : 36,
          vertical: 20,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 800),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(bottom: BorderSide(color: p.line)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: p.tertiary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.assessment_rounded, color: p.tertiary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Laporan Tutup Shift (Z-Report)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: p.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Kasir: ${summary.cashierName} • Shift #${summary.shiftId}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: p.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Waktu Operasional
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: p.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: p.line),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.schedule_rounded, size: 16, color: p.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Buka: ${dateFmt(summary.openedAt)}  •  Tutup: ${dateFmt(summary.closedAt)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: p.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // CARD 1: REKONSILIASI KAS LACI
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: p.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.point_of_sale_rounded, size: 18, color: primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  'Rekonsiliasi Kas Laci (Cash Drawer)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: p.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            buildSummaryRow('Modal Kas Awal', CurrencyFormatter.format(summary.startingCash), context: context),
                            const SizedBox(height: 8),
                            buildSummaryRow(
                              'Penjualan Tunai (+)',
                              CurrencyFormatter.format(summary.cashSales),
                              textColor: p.tertiary,
                              context: context,
                            ),
                            if (summary.cashIn > 0) ...[
                              const SizedBox(height: 8),
                              buildSummaryRow(
                                'Kas Masuk (+)',
                                CurrencyFormatter.format(summary.cashIn),
                                textColor: p.tertiary,
                                context: context,
                              ),
                            ],
                            if (summary.cashOut > 0) ...[
                              const SizedBox(height: 8),
                              buildSummaryRow(
                                'Kas Keluar (-)',
                                CurrencyFormatter.format(summary.cashOut),
                                textColor: p.danger,
                                context: context,
                              ),
                            ],
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Divider(height: 1, color: p.line),
                            ),
                            buildSummaryRow(
                              'Kas Diharapkan di Laci',
                              CurrencyFormatter.format(summary.expectedCash),
                              isBold: true,
                              context: context,
                            ),
                            const SizedBox(height: 8),
                            buildSummaryRow(
                              'Kas Fisik Aktual Dihitung',
                              CurrencyFormatter.format(summary.actualCash),
                              isBold: true,
                              textColor: primaryColor,
                              valueFontSize: 15,
                              context: context,
                            ),
                            const SizedBox(height: 12),

                            // Status Selisih Banner
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: summary.difference == 0
                                    ? p.tertiary.withValues(alpha: 0.12)
                                    : (summary.difference > 0
                                        ? Colors.blue.withValues(alpha: 0.12)
                                        : p.danger.withValues(alpha: 0.12)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: summary.difference == 0
                                      ? p.tertiary.withValues(alpha: 0.4)
                                      : (summary.difference > 0
                                          ? Colors.blue.withValues(alpha: 0.4)
                                          : p.danger.withValues(alpha: 0.4)),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    summary.difference == 0
                                        ? Icons.check_circle_rounded
                                        : (summary.difference > 0
                                            ? Icons.arrow_upward_rounded
                                            : Icons.arrow_downward_rounded),
                                    size: 18,
                                    color: summary.difference == 0
                                        ? p.tertiary
                                        : (summary.difference > 0 ? Colors.blue.shade700 : p.danger),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      summary.difference == 0
                                          ? 'Selisih Kas: Pas / Seimbang (Rp 0)'
                                          : (summary.difference > 0
                                              ? 'Selisih Kas: Surplus (+${CurrencyFormatter.format(summary.difference)})'
                                              : 'Selisih Kas: Minus (${CurrencyFormatter.format(summary.difference)})'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: summary.difference == 0
                                            ? p.tertiary
                                            : (summary.difference > 0 ? Colors.blue.shade800 : p.danger),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // CARD 2: RINGKASAN PENJUALAN & PEMBAYARAN
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: p.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.payments_outlined, size: 18, color: p.secondary),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Rincian Penjualan',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: p.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${summary.totalTransactions} Transaksi',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            buildSummaryRow(
                              'Total Penjualan Bersih',
                              CurrencyFormatter.format(summary.totalSales),
                              isBold: true,
                              textColor: p.tertiary,
                              valueFontSize: 16,
                              context: context,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Divider(height: 1, color: p.line),
                            ),
                            buildSummaryRow('• Pembayaran Tunai (Cash)', CurrencyFormatter.format(summary.cashSales), context: context),
                            const SizedBox(height: 7),
                            buildSummaryRow('• QRIS', CurrencyFormatter.format(summary.qrisSales), context: context),
                            const SizedBox(height: 7),
                            buildSummaryRow('• Transfer Bank', CurrencyFormatter.format(summary.transferSales), context: context),
                            const SizedBox(height: 7),
                            buildSummaryRow('• EDC / Kartu Debit/Kredit', CurrencyFormatter.format(summary.cardSales), context: context),
                            if (summary.otherSales > 0) ...[
                              const SizedBox(height: 7),
                              buildSummaryRow('• Pembayaran Lainnya', CurrencyFormatter.format(summary.otherSales), context: context),
                            ],
                          ],
                        ),
                      ),

                      // Catatan shift jika ada
                      if (summary.notes != null && summary.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: p.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: p.line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Catatan Serah Terima Kasir:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: p.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                summary.notes!.trim(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: p.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  border: Border(top: BorderSide(color: p.line)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await ReceiptPrinterService.instance.printShiftReport(summary);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Laporan Z-Report dikirim ke printer')),
                                );
                              }
                            },
                            icon: const Icon(Icons.print_outlined, size: 16),
                            label: const Text('Cetak Z-Report', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryColor,
                              side: BorderSide(color: p.line),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await ReceiptPrinterService.instance.shareShiftReport(summary);
                            },
                            icon: const Icon(Icons.share_outlined, size: 16),
                            label: const Text('Bagikan Struk', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: p.textSecondary,
                              side: BorderSide(color: p.line),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onDone();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: const Text(
                        'SELESAI & KELUAR SHIFT',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
