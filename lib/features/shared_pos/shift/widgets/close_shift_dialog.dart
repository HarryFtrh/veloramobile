import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/utils/audio_helper.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../shift_service.dart';
import 'shift_dialog_helpers.dart';
import 'shift_report_dialog.dart';

/// Modal dialog for cashier reconciliation and closing the shift.
Future<void> showCloseShiftModal(
  BuildContext context,
  ShiftStatus currentShift, {
  required VoidCallback onClosed,
}) async {
  final expectedCash = (currentShift.startingCash ?? 0) +
      currentShift.cashSales +
      currentShift.cashIn -
      currentShift.cashOut;

  num actualCash = expectedCash;
  final actualCashController = TextEditingController(text: expectedCash.toString());
  final notesController = TextEditingController();
  bool isSubmitting = false;

  final nonCashTotal = currentShift.qrisSales + currentShift.debitSales + currentShift.transferSales;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          final isMobile = context.isMobile;
          final p = context.palette;
          final primaryColor = Theme.of(context).colorScheme.primary;
          final difference = actualCash - expectedCash;

          void addDenom(num val) {
            AudioHelper.tapFeedback();
            actualCash += val;
            actualCashController.text = actualCash.toString();
            setState(() {});
          }

          void setPas() {
            AudioHelper.tapFeedback();
            actualCash = expectedCash;
            actualCashController.text = expectedCash.toString();
            setState(() {});
          }

          void resetCash() {
            AudioHelper.tapFeedback();
            actualCash = 0;
            actualCashController.text = '0';
            setState(() {});
          }

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
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 780),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: p.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.lock_clock_rounded, color: p.secondary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentShift.cashierName != null && currentShift.cashierName != 'Kasir'
                                    ? 'Tutup Shift: ${currentShift.cashierName}'
                                    : 'Tutup Shift & Rekonsiliasi Kasir',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Hitung total uang fisik di laci kasir & cetak Z-Report',
                                style: TextStyle(fontSize: 12, color: p.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card: Estimasi Kas di Laci (Drawer Breakdown)
                    Container(
                      padding: const EdgeInsets.all(14),
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Kasir Bertugas', style: TextStyle(fontSize: 11, color: p.textSecondary)),
                                  const SizedBox(height: 2),
                                  Text(
                                    currentShift.cashierName ?? 'Kasir',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: p.textPrimary),
                                  ),
                                ],
                              ),
                              if (currentShift.shiftId != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Shift #${currentShift.shiftId}',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: primaryColor),
                                  ),
                                ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1, color: p.line),
                          ),
                          buildSummaryRow('Modal Kas Awal', CurrencyFormatter.format(currentShift.startingCash ?? 0), context: context),
                          const SizedBox(height: 6),
                          buildSummaryRow(
                            'Penjualan Tunai (+)',
                            CurrencyFormatter.format(currentShift.cashSales),
                            textColor: p.tertiary,
                            context: context,
                          ),
                          if (currentShift.cashIn > 0) ...[
                            const SizedBox(height: 6),
                            buildSummaryRow(
                              'Kas Masuk (+)',
                              CurrencyFormatter.format(currentShift.cashIn),
                              textColor: p.tertiary,
                              context: context,
                            ),
                          ],
                          if (currentShift.cashOut > 0) ...[
                            const SizedBox(height: 6),
                            buildSummaryRow(
                              'Kas Keluar (-)',
                              CurrencyFormatter.format(currentShift.cashOut),
                              textColor: p.danger,
                              context: context,
                            ),
                          ],
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1, color: p.line),
                          ),
                          buildSummaryRow(
                            'Estimasi Kas di Laci',
                            CurrencyFormatter.format(expectedCash),
                            isBold: true,
                            valueFontSize: 15,
                            context: context,
                          ),
                          if (nonCashTotal > 0) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: p.surfaceMuted,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Info Non-Tunai (QRIS/EDC/TF): ${CurrencyFormatter.format(nonCashTotal)}',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.textSecondary),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Input: Uang Fisik Aktual
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Hitung Uang Fisik di Laci (Actual Cash)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: setPas,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Text(
                              'Hitung Pas (${CurrencyFormatter.format(expectedCash)})',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: primaryColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: actualCashController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: primaryColor),
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        hintText: '0',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: p.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: p.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor),
                        ),
                      ),
                      onChanged: (val) {
                        final clean = val.replaceAll('.', '').replaceAll(',', '');
                        setState(() {
                          actualCash = num.tryParse(clean) ?? 0;
                        });
                      },
                    ),
                    const SizedBox(height: 8),

                    // Quick Denominations
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          buildQuickCashChip('+100rb', () => addDenom(100000), context: context),
                          const SizedBox(width: 6),
                          buildQuickCashChip('+50rb', () => addDenom(50000), context: context),
                          const SizedBox(width: 6),
                          buildQuickCashChip('+20rb', () => addDenom(20000), context: context),
                          const SizedBox(width: 6),
                          buildQuickCashChip('+10rb', () => addDenom(10000), context: context),
                          const SizedBox(width: 6),
                          buildQuickCashChip('+5rb', () => addDenom(5000), context: context),
                          const SizedBox(width: 6),
                          buildQuickCashChip('Reset', resetCash, isDanger: true, context: context),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Live Discrepancy (Selisih) Indicator
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: difference == 0
                            ? p.tertiary.withValues(alpha: 0.12)
                            : (difference > 0
                                ? Colors.blue.withValues(alpha: 0.12)
                                : p.danger.withValues(alpha: 0.12)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: difference == 0
                              ? p.tertiary.withValues(alpha: 0.35)
                              : (difference > 0 ? Colors.blue.withValues(alpha: 0.35) : p.danger.withValues(alpha: 0.35)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            difference == 0
                                ? Icons.check_circle_rounded
                                : (difference > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
                            size: 16,
                            color: difference == 0
                                ? p.tertiary
                                : (difference > 0 ? Colors.blue.shade700 : p.danger),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              difference == 0
                                  ? 'Selisih Kas: Pas / Seimbang (Rp 0)'
                                  : (difference > 0
                                      ? 'Selisih Kas: Surplus (+${CurrencyFormatter.format(difference)})'
                                      : 'Selisih Kas: Kurang (${CurrencyFormatter.format(difference)})'),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: difference == 0
                                    ? p.tertiary
                                    : (difference > 0 ? Colors.blue.shade800 : p.danger),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Notes TextField
                    TextField(
                      controller: notesController,
                      style: TextStyle(fontSize: 13, color: p.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Catatan serah terima kasir / keterangan selisih...',
                        hintStyle: TextStyle(fontSize: 12, color: p.textSecondary),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: p.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: p.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: p.textSecondary,
                              side: BorderSide(color: p.line),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    final cleanActual = actualCashController.text.trim().replaceAll('.', '').replaceAll(',', '');
                                    final actual = num.tryParse(cleanActual) ?? actualCash;
                                    setState(() => isSubmitting = true);
                                    try {
                                      final summary = await ShiftService.instance.closeShift(
                                        currentShift: currentShift,
                                        actualCash: actual,
                                        notes: notesController.text.trim().isNotEmpty
                                            ? notesController.text.trim()
                                            : null,
                                      );
                                      AudioHelper.actionFeedback();
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      if (context.mounted) {
                                        await showShiftReportModal(
                                          context,
                                          summary,
                                          onDone: onClosed,
                                        );
                                      }
                                    } catch (e) {
                                      setState(() => isSubmitting = false);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Gagal menutup shift: $e'),
                                            backgroundColor: p.danger,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              elevation: 0,
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('TUTUP & LIHAT LAPORAN', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
