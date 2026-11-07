import 'package:flutter/material.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Sticky bottom footer for FnbModifierSheet with grand total and confirmation action
class FnbModifierActionFooter extends StatelessWidget {
  final bool isValid;
  final int quantity;
  final num grandTotal;
  final double horizontalPadding;
  final VoidCallback onSubmit;

  const FnbModifierActionFooter({
    super.key,
    required this.isValid,
    required this.quantity,
    required this.grandTotal,
    required this.horizontalPadding,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, color: p.line),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              10,
              horizontalPadding,
              12 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isValid)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 15, color: p.danger),
                        const SizedBox(width: 6),
                        Text(
                          'Lengkapi pilihan varian wajib di atas',
                          style: TextStyle(fontSize: 11.5, color: p.danger, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: isValid ? onSubmit : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      disabledBackgroundColor: p.line,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          quantity > 1 ? 'Tambah ke Pesanan ($quantity porsi)' : 'Tambah ke Pesanan',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
                        ),
                        Text(
                          CurrencyFormatter.format(grandTotal),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
