import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/audio_helper.dart';
import 'receipt_printer_service.dart';
import 'shift_service.dart';

class ShiftDialogs {
  /// Opens dialog to start a new cashier shift with starting cash
  static Future<bool> showOpenShiftDialog(
    BuildContext context, {
    required Function(ShiftStatus) onOpened,
  }) async {
    num startingCash = 200000;
    final cashController = TextEditingController(text: '200000');
    final notesController = TextEditingController();
    bool isSubmitting = false;
    final presets = [50000, 100000, 200000, 500000, 1000000];

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isMobile = context.isMobile;
            return Dialog(
              backgroundColor: WarmPalette.canvas,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: WarmPalette.line, width: 1.5),
              ),
              insetPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 40,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 18 : 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: WarmPalette.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.point_of_sale_rounded,
                            color: WarmPalette.primary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Buka Shift Kasir Baru',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: WarmPalette.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Masukkan modal uang tunai awal di laci register',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: WarmPalette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Modal Awal (Starting Cash)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: WarmPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: WarmPalette.line),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Rp',
                            style: TextStyle(
                              color: WarmPalette.textSecondary,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: cashController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: WarmPalette.primary,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (val) {
                                final parsed = num.tryParse(val.replaceAll('.', '').replaceAll(',', '')) ?? 0;
                                setState(() => startingCash = parsed);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presets.map((amount) {
                        final isSelected = startingCash == amount;
                        return ChoiceChip(
                          label: Text(
                            CurrencyFormatter.format(amount),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : WarmPalette.textSecondary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: WarmPalette.primary,
                          backgroundColor: WarmPalette.surfaceMuted,
                          side: BorderSide(
                            color: isSelected ? WarmPalette.primary : WarmPalette.line,
                          ),
                          shape: const StadiumBorder(),
                          onSelected: (selected) {
                            if (selected) {
                              AudioHelper.tapFeedback();
                              cashController.text = amount.toString();
                              setState(() => startingCash = amount);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      style: const TextStyle(fontSize: 13, color: WarmPalette.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Catatan pembukaan shift (opsional)...',
                        hintStyle: const TextStyle(fontSize: 12, color: WarmPalette.textSecondary),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: WarmPalette.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: WarmPalette.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: WarmPalette.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              AudioHelper.actionFeedback();
                              setState(() => isSubmitting = true);
                              try {
                                final cleanCash = cashController.text.trim().replaceAll('.', '').replaceAll(',', '');
                                final amountToOpen = num.tryParse(cleanCash) ?? startingCash;
                                await ShiftService.instance.openShift(
                                    startingCash: amountToOpen,
                                    notes: notesController.text.trim().isNotEmpty
                                        ? notesController.text.trim()
                                        : null,
                                );
                                final status = await ShiftService.instance.getShiftStatus();
                                onOpened(status);
                                if (ctx.mounted) Navigator.pop(ctx, true);
                              } catch (e) {
                                setState(() => isSubmitting = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Gagal membuka shift: $e'),
                                      backgroundColor: WarmPalette.danger,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WarmPalette.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'BUKA LACI & REGISTER KASIR',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
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

    return result ?? false;
  }

  /// Dialog to record Petty Cash In / Out (Kas Masuk / Kas Keluar)
  static Future<void> showPettyCashDialog(
    BuildContext context, {
    required String type, // 'in' or 'out'
    required VoidCallback onSuccess,
  }) async {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    bool isSubmitting = false;
    final isCashIn = type == 'in';

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isMobile = context.isMobile;
            return Dialog(
              backgroundColor: WarmPalette.canvas,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: WarmPalette.line, width: 1.5),
              ),
              insetPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 40,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 18 : 26),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isCashIn
                                ? WarmPalette.tertiary.withValues(alpha: 0.15)
                                : WarmPalette.danger.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isCashIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: isCashIn ? WarmPalette.tertiary : WarmPalette.danger,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          isCashIn ? 'Kas Masuk (Petty Cash In)' : 'Kas Keluar (Petty Cash Out)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: WarmPalette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Jumlah Uang Tunai (Rp)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: WarmPalette.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: WarmPalette.textPrimary),
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        hintText: '50000',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: WarmPalette.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: WarmPalette.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: WarmPalette.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Alasan / Keperluan',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: WarmPalette.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonController,
                      style: const TextStyle(fontSize: 13, color: WarmPalette.textPrimary),
                      decoration: InputDecoration(
                        hintText: isCashIn ? 'Misal: Tambah modal koin' : 'Misal: Beli es batu, galon, kurir',
                        hintStyle: const TextStyle(color: WarmPalette.textSecondary),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: WarmPalette.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: WarmPalette.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: WarmPalette.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal', style: TextStyle(color: WarmPalette.textSecondary, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final cleanAmount = amountController.text.trim().replaceAll('.', '').replaceAll(',', '');
                                  final amount = num.tryParse(cleanAmount) ?? 0;
                                  final reason = reasonController.text.trim();
                                  if (amount <= 0 || reason.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Isi nominal dan alasan dengan benar.')),
                                    );
                                    return;
                                  }

                                  setState(() => isSubmitting = true);
                                  try {
                                    await ShiftService.instance.recordPettyCash(
                                      type: type,
                                      amount: amount,
                                      reason: reason,
                                    );
                                    AudioHelper.successFeedback();
                                    onSuccess();
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  } catch (e) {
                                    setState(() => isSubmitting = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Gagal mencatat kas: $e')),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCashIn ? WarmPalette.tertiary : WarmPalette.danger,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            elevation: 0,
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Simpan Kas', style: TextStyle(fontWeight: FontWeight.w700)),
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

  /// Dialog to reconcile cash drawer and close shift
  static Future<void> showCloseShiftDialog(
    BuildContext context,
    ShiftStatus currentShift, {
    required VoidCallback onClosed,
  }) async {
    final actualCashController = TextEditingController();
    final notesController = TextEditingController();
    bool isSubmitting = false;

    // Calculate expected cash in drawer
    final expectedCash = currentShift.expectedCash > 0
        ? currentShift.expectedCash
        : ((currentShift.startingCash ?? 0) + currentShift.cashSales + currentShift.cashIn - currentShift.cashOut);

    final nonCashTotal = currentShift.qrisSales + currentShift.transferSales + currentShift.cardSales + currentShift.otherSales;

    num actualCash = 0;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isMobile = context.isMobile;
            final difference = actualCash - expectedCash;

            void addDenom(num amount) {
              AudioHelper.tapFeedback();
              actualCash += amount;
              actualCashController.text = actualCash.toInt().toString();
              setState(() {});
            }

            void setPas() {
              AudioHelper.tapFeedback();
              actualCash = expectedCash;
              actualCashController.text = actualCash.toInt().toString();
              setState(() {});
            }

            void resetCash() {
              AudioHelper.tapFeedback();
              actualCash = 0;
              actualCashController.text = '0';
              setState(() {});
            }

            return Dialog(
              backgroundColor: WarmPalette.canvas,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: WarmPalette.line, width: 1.5),
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
                              color: WarmPalette.secondary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.lock_clock_rounded, color: WarmPalette.secondary, size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tutup Shift & Rekonsiliasi Kasir',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: WarmPalette.textPrimary),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Hitung total uang fisik di laci kasir & cetak Z-Report',
                                  style: TextStyle(fontSize: 12, color: WarmPalette.textSecondary),
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
                          border: Border.all(color: WarmPalette.line),
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
                                    const Text('Kasir Bertugas', style: TextStyle(fontSize: 11, color: WarmPalette.textSecondary)),
                                    const SizedBox(height: 2),
                                    Text(
                                      currentShift.cashierName ?? 'Kasir',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: WarmPalette.textPrimary),
                                    ),
                                  ],
                                ),
                                if (currentShift.shiftId != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: WarmPalette.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Shift #${currentShift.shiftId}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: WarmPalette.primary),
                                    ),
                                  ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(height: 1, color: WarmPalette.line),
                            ),
                            _buildSummaryRow('Modal Kas Awal', CurrencyFormatter.format(currentShift.startingCash ?? 0)),
                            const SizedBox(height: 6),
                            _buildSummaryRow(
                              'Penjualan Tunai (+)',
                              CurrencyFormatter.format(currentShift.cashSales),
                              textColor: WarmPalette.tertiary,
                            ),
                            if (currentShift.cashIn > 0) ...[
                              const SizedBox(height: 6),
                              _buildSummaryRow(
                                'Kas Masuk (+)',
                                CurrencyFormatter.format(currentShift.cashIn),
                                textColor: WarmPalette.tertiary,
                              ),
                            ],
                            if (currentShift.cashOut > 0) ...[
                              const SizedBox(height: 6),
                              _buildSummaryRow(
                                'Kas Keluar (-)',
                                CurrencyFormatter.format(currentShift.cashOut),
                                textColor: WarmPalette.danger,
                              ),
                            ],
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(height: 1, color: WarmPalette.line),
                            ),
                            _buildSummaryRow(
                              'Estimasi Kas di Laci',
                              CurrencyFormatter.format(expectedCash),
                              isBold: true,
                              valueFontSize: 15,
                            ),
                            if (nonCashTotal > 0) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: WarmPalette.surfaceMuted,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Info Non-Tunai (QRIS/EDC/TF): ${CurrencyFormatter.format(nonCashTotal)}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: WarmPalette.textSecondary),
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
                          const Flexible(
                            child: Text(
                              'Hitung Uang Fisik di Laci (Actual Cash)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: WarmPalette.textPrimary),
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
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: WarmPalette.primary),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: actualCashController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: WarmPalette.primary),
                        decoration: InputDecoration(
                          prefixText: 'Rp ',
                          hintText: '0',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: WarmPalette.line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: WarmPalette.line),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: WarmPalette.primary),
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
                            _buildQuickCashChip('+100rb', () => addDenom(100000)),
                            const SizedBox(width: 6),
                            _buildQuickCashChip('+50rb', () => addDenom(50000)),
                            const SizedBox(width: 6),
                            _buildQuickCashChip('+20rb', () => addDenom(20000)),
                            const SizedBox(width: 6),
                            _buildQuickCashChip('+10rb', () => addDenom(10000)),
                            const SizedBox(width: 6),
                            _buildQuickCashChip('+5rb', () => addDenom(5000)),
                            const SizedBox(width: 6),
                            _buildQuickCashChip('Reset', resetCash, isDanger: true),
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
                              ? WarmPalette.tertiary.withValues(alpha: 0.12)
                              : (difference > 0
                                  ? Colors.blue.withValues(alpha: 0.12)
                                  : WarmPalette.danger.withValues(alpha: 0.12)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: difference == 0
                                ? WarmPalette.tertiary.withValues(alpha: 0.35)
                                : (difference > 0 ? Colors.blue.withValues(alpha: 0.35) : WarmPalette.danger.withValues(alpha: 0.35)),
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
                                  ? WarmPalette.tertiary
                                  : (difference > 0 ? Colors.blue.shade700 : WarmPalette.danger),
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
                                      ? WarmPalette.tertiary
                                      : (difference > 0 ? Colors.blue.shade800 : WarmPalette.danger),
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
                        style: const TextStyle(fontSize: 13, color: WarmPalette.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Catatan serah terima kasir / keterangan selisih...',
                          hintStyle: const TextStyle(fontSize: 12, color: WarmPalette.textSecondary),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: WarmPalette.line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: WarmPalette.line),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: WarmPalette.primary),
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
                                foregroundColor: WarmPalette.textSecondary,
                                side: const BorderSide(color: WarmPalette.line),
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
                                          await showShiftReportDialog(
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
                                              backgroundColor: WarmPalette.danger,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: WarmPalette.primary,
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

  /// Menampilkan modal rincian tutup shift kasir komplit (Z-Report):
  /// Modal awal, kas masuk/keluar, penjualan tunai vs non-tunai, kas aktual vs ekspektasi, dan selisih kas.
  static Future<void> showShiftReportDialog(
    BuildContext context,
    ShiftCloseSummary summary, {
    required VoidCallback onDone,
  }) async {
    String dateFmt(DateTime dt) =>
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    final isMobile = context.isMobile;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: WarmPalette.canvas,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: WarmPalette.line, width: 1.5),
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 36,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(bottom: BorderSide(color: WarmPalette.line)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: WarmPalette.tertiary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.assessment_rounded, color: WarmPalette.tertiary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Laporan Tutup Shift (Z-Report)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: WarmPalette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Kasir: ${summary.cashierName} • Shift #${summary.shiftId}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: WarmPalette.textSecondary,
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
                            color: WarmPalette.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: WarmPalette.line),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.schedule_rounded, size: 16, color: WarmPalette.textSecondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Buka: ${dateFmt(summary.openedAt)}  •  Tutup: ${dateFmt(summary.closedAt)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: WarmPalette.textSecondary,
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
                            border: Border.all(color: WarmPalette.line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.point_of_sale_rounded, size: 18, color: WarmPalette.primary),
                                  SizedBox(width: 8),
                                  Text(
                                    'Rekonsiliasi Kas Laci (Cash Drawer)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: WarmPalette.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildSummaryRow('Modal Kas Awal', CurrencyFormatter.format(summary.startingCash)),
                              const SizedBox(height: 8),
                              _buildSummaryRow('Penjualan Tunai (+)', CurrencyFormatter.format(summary.cashSales), textColor: WarmPalette.tertiary),
                              if (summary.cashIn > 0) ...[
                                const SizedBox(height: 8),
                                _buildSummaryRow('Kas Masuk (+)', CurrencyFormatter.format(summary.cashIn), textColor: WarmPalette.tertiary),
                              ],
                              if (summary.cashOut > 0) ...[
                                const SizedBox(height: 8),
                                _buildSummaryRow('Kas Keluar (-)', CurrencyFormatter.format(summary.cashOut), textColor: WarmPalette.danger),
                              ],
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Divider(height: 1, color: WarmPalette.line),
                              ),
                              _buildSummaryRow(
                                'Kas Diharapkan di Laci',
                                CurrencyFormatter.format(summary.expectedCash),
                                isBold: true,
                              ),
                              const SizedBox(height: 8),
                              _buildSummaryRow(
                                'Kas Fisik Aktual Dihitung',
                                CurrencyFormatter.format(summary.actualCash),
                                isBold: true,
                                textColor: WarmPalette.primary,
                                valueFontSize: 15,
                              ),
                              const SizedBox(height: 12),

                              // Status Selisih Banner
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: summary.difference == 0
                                      ? WarmPalette.tertiary.withValues(alpha: 0.12)
                                      : (summary.difference > 0
                                          ? Colors.blue.withValues(alpha: 0.12)
                                          : WarmPalette.danger.withValues(alpha: 0.12)),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: summary.difference == 0
                                        ? WarmPalette.tertiary.withValues(alpha: 0.4)
                                        : (summary.difference > 0
                                            ? Colors.blue.withValues(alpha: 0.4)
                                            : WarmPalette.danger.withValues(alpha: 0.4)),
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
                                          ? WarmPalette.tertiary
                                          : (summary.difference > 0 ? Colors.blue.shade700 : WarmPalette.danger),
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
                                              ? WarmPalette.tertiary
                                              : (summary.difference > 0 ? Colors.blue.shade800 : WarmPalette.danger),
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
                            border: Border.all(color: WarmPalette.line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.payments_outlined, size: 18, color: WarmPalette.secondary),
                                      SizedBox(width: 8),
                                      Text(
                                        'Rincian Penjualan',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: WarmPalette.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: WarmPalette.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${summary.totalTransactions} Transaksi',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: WarmPalette.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildSummaryRow(
                                'Total Penjualan Bersih',
                                CurrencyFormatter.format(summary.totalSales),
                                isBold: true,
                                textColor: WarmPalette.tertiary,
                                valueFontSize: 16,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Divider(height: 1, color: WarmPalette.line),
                              ),
                              _buildSummaryRow('• Pembayaran Tunai (Cash)', CurrencyFormatter.format(summary.cashSales)),
                              const SizedBox(height: 7),
                              _buildSummaryRow('• QRIS', CurrencyFormatter.format(summary.qrisSales)),
                              const SizedBox(height: 7),
                              _buildSummaryRow('• Transfer Bank', CurrencyFormatter.format(summary.transferSales)),
                              const SizedBox(height: 7),
                              _buildSummaryRow('• EDC / Kartu Debit/Kredit', CurrencyFormatter.format(summary.cardSales)),
                              if (summary.otherSales > 0) ...[
                                const SizedBox(height: 7),
                                _buildSummaryRow('• Pembayaran Lainnya', CurrencyFormatter.format(summary.otherSales)),
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
                              color: WarmPalette.surfaceMuted,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: WarmPalette.line),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Catatan Serah Terima Kasir:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: WarmPalette.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  summary.notes!.trim(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: WarmPalette.textPrimary,
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
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                    border: Border(top: BorderSide(color: WarmPalette.line)),
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
                                foregroundColor: WarmPalette.primary,
                                side: const BorderSide(color: WarmPalette.line),
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
                                foregroundColor: WarmPalette.textSecondary,
                                side: const BorderSide(color: WarmPalette.line),
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
                          backgroundColor: WarmPalette.primary,
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

  static Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? textColor,
    double? valueFontSize,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: isBold ? WarmPalette.textPrimary : WarmPalette.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize ?? (isBold ? 14 : 12),
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
              color: textColor ?? WarmPalette.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildQuickCashChip(String label, VoidCallback onTap, {bool isDanger = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDanger ? WarmPalette.danger.withValues(alpha: 0.1) : WarmPalette.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDanger ? WarmPalette.danger.withValues(alpha: 0.3) : WarmPalette.line,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDanger ? WarmPalette.danger : WarmPalette.textPrimary,
          ),
        ),
      ),
    );
  }
}

