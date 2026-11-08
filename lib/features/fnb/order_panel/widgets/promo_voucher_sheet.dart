import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/utils/audio_helper.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../fnb_register_controller.dart';

typedef PromoAndVoucherSheet = FnbDiscountSheet;

/// Lembar modal modern untuk menerapkan diskon manual transaksi (Persentase % atau Nominal Rp).
class FnbDiscountSheet extends StatefulWidget {
  const FnbDiscountSheet({super.key, required this.ctrl});
  final RegisterController ctrl;

  static Future<void> show(BuildContext context, RegisterController ctrl) {
    final isMobile = context.isMobile;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 520,
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.88,
        ),
        child: FnbDiscountSheet(ctrl: ctrl),
      ),
    );
  }

  @override
  State<FnbDiscountSheet> createState() => _FnbDiscountSheetState();
}

class _FnbDiscountSheetState extends State<FnbDiscountSheet> {
  bool _isPercent = true;
  final _percentCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  double _currentPercent = 0.0;
  double _currentAmount = 0.0;

  static const _percentPresets = [5, 10, 15, 20, 25, 50];

  @override
  void initState() {
    super.initState();
    final ctrl = widget.ctrl;
    if (ctrl.manualDiscountPercent > 0) {
      _isPercent = true;
      _currentPercent = ctrl.manualDiscountPercent;
      _percentCtrl.text = _formatNumber(_currentPercent);
    } else if (ctrl.manualDiscountAmount > 0) {
      _isPercent = false;
      _currentAmount = ctrl.manualDiscountAmount;
      _amountCtrl.text = _currentAmount.toStringAsFixed(0);
    }
  }

  String _formatNumber(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toString();
  }

  @override
  void dispose() {
    _percentCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  List<int> get _amountPresets {
    final sub = widget.ctrl.subtotal.round();
    final base = [5000, 10000, 20000, 50000, 100000];
    return base.where((b) => b < sub).toList();
  }

  double get _calculatedDiscount {
    final sub = widget.ctrl.subtotal.toDouble();
    if (sub <= 0) return 0.0;
    if (_isPercent) {
      return (sub * (_currentPercent / 100)).clamp(0.0, sub);
    } else {
      return _currentAmount.clamp(0.0, sub);
    }
  }

  double get _newSubtotal {
    final sub = widget.ctrl.subtotal.toDouble();
    return (sub - _calculatedDiscount).clamp(0.0, double.infinity);
  }

  void _applyDiscount() {
    AudioHelper.actionFeedback();
    if (_isPercent) {
      widget.ctrl.applyManualDiscount(percent: _currentPercent, amount: 0);
    } else {
      widget.ctrl.applyManualDiscount(percent: 0, amount: _currentAmount);
    }
    Navigator.pop(context);
  }

  void _removeDiscount() {
    AudioHelper.tapFeedback();
    widget.ctrl.removeManualDiscount();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final subtotal = widget.ctrl.subtotal.toDouble();
    final discountVal = _calculatedDiscount;
    final newTotal = _newSubtotal;

    final hasActiveDiscount =
        widget.ctrl.manualDiscountPercent > 0 || widget.ctrl.manualDiscountAmount > 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Dialog
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.discount_rounded, color: Color(0xFFEF4444), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Diskon Transaksi',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: p.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Subtotal Belanja: ${CurrencyFormatter.format(subtotal)}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Tutup',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 2. Mode Selector: [Persentase (%)] vs [Nominal (Rp)]
            Container(
              decoration: BoxDecoration(
                color: p.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.line),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        AudioHelper.tapFeedback();
                        setState(() {
                          _isPercent = true;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _isPercent ? p.surface : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _isPercent
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.percent_rounded,
                              size: 15,
                              color: _isPercent ? primaryColor : p.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Persentase (%)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _isPercent ? FontWeight.w800 : FontWeight.w600,
                                color: _isPercent ? p.textPrimary : p.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        AudioHelper.tapFeedback();
                        setState(() {
                          _isPercent = false;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: !_isPercent ? p.surface : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: !_isPercent
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.payments_rounded,
                              size: 15,
                              color: !_isPercent ? primaryColor : p.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Nominal (Rp)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: !_isPercent ? FontWeight.w800 : FontWeight.w600,
                                color: !_isPercent ? p.textPrimary : p.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. Konten Input Sesuai Mode
            if (_isPercent) ...[
              // Preset Persentase Cepat
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final pVal in _percentPresets)
                    ChoiceChip(
                      label: Text('$pVal%', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      selected: _currentPercent == pVal,
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      selectedColor: primaryColor.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: _currentPercent == pVal ? primaryColor : p.textSecondary,
                      ),
                      side: BorderSide(
                        color: _currentPercent == pVal ? primaryColor : p.line,
                      ),
                      onSelected: (_) {
                        AudioHelper.tapFeedback();
                        setState(() {
                          _currentPercent = pVal.toDouble();
                          _percentCtrl.text = pVal.toString();
                        });
                      },
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Custom Input Persentase
              TextField(
                controller: _percentCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                decoration: InputDecoration(
                  labelText: 'Ketik Persentase Diskon',
                  hintText: 'Contoh: 12.5',
                  suffixText: '%',
                  suffixStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.textPrimary),
                  filled: true,
                  fillColor: p.surfaceMuted,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.line)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (v) {
                  final parsed = double.tryParse(v.trim().replaceAll(',', '.')) ?? 0.0;
                  setState(() {
                    _currentPercent = parsed.clamp(0.0, 100.0);
                  });
                },
              ),
            ] else ...[
              // Preset Nominal Cepat
              if (_amountPresets.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final aVal in _amountPresets)
                      ChoiceChip(
                        label: Text(
                          CurrencyFormatter.format(aVal),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                        selected: _currentAmount == aVal,
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        selectedColor: primaryColor.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: _currentAmount == aVal ? primaryColor : p.textSecondary,
                        ),
                        side: BorderSide(
                          color: _currentAmount == aVal ? primaryColor : p.line,
                        ),
                        onSelected: (_) {
                          AudioHelper.tapFeedback();
                          setState(() {
                            _currentAmount = aVal.toDouble();
                            _amountCtrl.text = aVal.toString();
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Custom Input Nominal
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                decoration: InputDecoration(
                  labelText: 'Ketik Nominal Potongan Rupiah',
                  prefixText: 'Rp ',
                  prefixStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.textPrimary),
                  filled: true,
                  fillColor: p.surfaceMuted,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.line)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (v) {
                  final clean = v.replaceAll('.', '').replaceAll(',', '').replaceAll(' ', '');
                  final parsed = double.tryParse(clean) ?? 0.0;
                  setState(() {
                    _currentAmount = parsed.clamp(0.0, subtotal);
                  });
                },
              ),
            ],

            const SizedBox(height: 16),

            // 4. Kartu Live Preview Hasil Diskon
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.line),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal Awal', style: TextStyle(fontSize: 12, color: p.textSecondary)),
                      Text(CurrencyFormatter.format(subtotal), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Potongan Diskon',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFFEF4444)),
                      ),
                      Text(
                        '-${CurrencyFormatter.format(discountVal)}',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFFEF4444)),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Setelah Diskon',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: p.textPrimary),
                      ),
                      Text(
                        CurrencyFormatter.format(newTotal),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 5. Tombol Aksi: [Hapus Diskon] + [Terapkan Diskon]
            Row(
              children: [
                if (hasActiveDiscount) ...[
                  OutlinedButton.icon(
                    onPressed: _removeDiscount,
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: FilledButton.icon(
                    onPressed: discountVal > 0 ? _applyDiscount : null,
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: const Text(
                      'Terapkan Diskon',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
