import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/utils/audio_helper.dart';
import '../../shift_service.dart';

/// Modal dialog to record Petty Cash In / Out (Kas Masuk / Kas Keluar).
Future<void> showPettyCashModal(
  BuildContext context, {
  required String type, // 'in' or 'out'
  required VoidCallback onSuccess,
}) async {
  final amountController = TextEditingController();
  final reasonController = TextEditingController();
  bool isSubmitting = false;
  final isCashIn = type == 'in';

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          final isMobile = context.isMobile;
          final p = context.palette;
          final primaryColor = Theme.of(context).colorScheme.primary;

          return Dialog(
            backgroundColor: p.canvas,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: p.line, width: 1.5),
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
                                ? p.tertiary.withValues(alpha: 0.15)
                                : p.danger.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isCashIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: isCashIn ? p.tertiary : p.danger,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          isCashIn ? 'Kas Masuk (Petty Cash In)' : 'Kas Keluar (Petty Cash Out)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: p.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Jumlah Uang Tunai (Rp)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.textPrimary),
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        hintText: '50000',
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
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Alasan / Keperluan',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonController,
                      style: TextStyle(fontSize: 13, color: p.textPrimary),
                      decoration: InputDecoration(
                        hintText: isCashIn ? 'Misal: Tambah modal koin' : 'Misal: Beli es batu, galon, kurir',
                        hintStyle: TextStyle(color: p.textSecondary),
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
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Batal', style: TextStyle(color: p.textSecondary, fontWeight: FontWeight.w700)),
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
                            backgroundColor: isCashIn ? p.tertiary : p.danger,
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
