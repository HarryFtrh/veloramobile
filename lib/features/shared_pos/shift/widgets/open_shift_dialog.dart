import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/utils/audio_helper.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../shift_service.dart';

/// Modal dialog to start a new cashier shift with starting cash presets.
Future<bool> showOpenShiftModal(
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
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.point_of_sale_rounded,
                            color: primaryColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Buka Shift Kasir Baru',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: p.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Masukkan modal uang tunai awal di laci register',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: p.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Modal Awal (Starting Cash)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: p.line),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Rp',
                            style: TextStyle(
                              color: p.textSecondary,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: cashController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: primaryColor,
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
                              color: isSelected ? Colors.white : p.textSecondary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: primaryColor,
                          backgroundColor: p.surfaceMuted,
                          side: BorderSide(
                            color: isSelected ? primaryColor : p.line,
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
                      style: TextStyle(fontSize: 13, color: p.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Catatan pembukaan shift (opsional)...',
                        hintStyle: TextStyle(fontSize: 12, color: p.textSecondary),
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
                                      backgroundColor: p.danger,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
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
