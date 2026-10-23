import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';
import '../../core/utils/currency_formatter.dart';

class PaymentChoice {
  const PaymentChoice(this.method, this.paid);
  final String method;
  final num paid;
}

class FnbPaymentSheet extends StatefulWidget {
  const FnbPaymentSheet({super.key, required this.total});
  final num total;

  static Future<PaymentChoice?> show(BuildContext context, num total) {
    final isMobile = context.isMobile;
    return showModalBottomSheet<PaymentChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 560,
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.90,
        ),
        child: FnbPaymentSheet(total: total),
      ),
    );
  }

  @override
  State<FnbPaymentSheet> createState() => _FnbPaymentSheetState();
}

class _FnbPaymentSheetState extends State<FnbPaymentSheet> {
  static const _methods = [
    ('cash', 'Tunai', Icons.payments_outlined),
    ('qris', 'QRIS', Icons.qr_code_2),
    ('debit', 'Debit', Icons.credit_card),
    ('transfer', 'Transfer', Icons.account_balance_outlined),
  ];

  String _method = 'cash';
  late num _paid = widget.total;
  final _custom = TextEditingController();

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  /// Nominal uang pas, lalu pembulatan ke atas ke pecahan uang yang lazim.
  List<num> get _presets {
    final t = widget.total;
    final out = <num>{t};
    for (final step in const [10000, 50000, 100000]) {
      final up = ((t / step).ceil() * step);
      if (up > t) out.add(up);
    }
    return out.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final isCash = _method == 'cash';
    final paid = isCash ? _paid : widget.total;
    final enough = paid >= widget.total;
    final isMobile = context.isMobile;
    final paddingHoriz = isMobile ? 12.0 : 16.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(paddingHoriz, 0, paddingHoriz, MediaQuery.viewInsetsOf(context).bottom + Gap.md),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Pembayaran', style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: isMobile ? 18 : 20)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: WarmPalette.textSecondary, size: 20),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Tutup',
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text('Total tagihan', style: text.bodySmall?.copyWith(color: p.textSecondary, fontSize: 11)),
            Text(
              CurrencyFormatter.format(widget.total),
              style: text.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
                fontSize: isMobile ? 22 : 26,
              ),
            ),
            const SizedBox(height: Gap.md),
            Wrap(
              spacing: Gap.xs + 2,
              runSpacing: Gap.xs + 2,
              children: [
                for (final (value, label, icon) in _methods)
                  ChoiceChip(
                    avatar: Icon(icon, size: 16),
                    label: Text(label, style: const TextStyle(fontSize: 12)),
                    selected: _method == value,
                    showCheckmark: false,
                    shape: const StadiumBorder(),
                    onSelected: (_) => setState(() {
                      _method = value;
                      _paid = widget.total;
                      _custom.clear();
                    }),
                  ),
              ],
            ),
            if (isCash) ...[
              const SizedBox(height: Gap.md),
              Wrap(
                spacing: Gap.xs + 2,
                runSpacing: Gap.xs + 2,
                children: [
                  for (final v in _presets)
                    ChoiceChip(
                      label: Text(v == widget.total ? 'Uang pas' : CurrencyFormatter.format(v), style: const TextStyle(fontSize: 12)),
                      selected: _paid == v && _custom.text.isEmpty,
                      showCheckmark: false,
                      shape: const StadiumBorder(),
                      onSelected: (_) => setState(() {
                        _paid = v;
                        _custom.clear();
                      }),
                    ),
                ],
              ),
              const SizedBox(height: Gap.sm),
              TextField(
                controller: _custom,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(labelText: 'Nominal lain', prefixText: 'Rp '),
                onChanged: (v) => setState(() => _paid = num.tryParse(v) ?? 0),
              ),
              const SizedBox(height: Gap.sm),
              Row(
                children: [
                  Text('Kembalian', style: text.bodyMedium?.copyWith(color: p.textSecondary, fontSize: 12)),
                  const Spacer(),
                  Text(
                    enough ? CurrencyFormatter.format(paid - widget.total) : 'Uang kurang',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: enough ? p.success : p.danger,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: Gap.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: enough ? () => Navigator.pop(context, PaymentChoice(_method, paid)) : null,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: const Text('Konfirmasi pembayaran', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
