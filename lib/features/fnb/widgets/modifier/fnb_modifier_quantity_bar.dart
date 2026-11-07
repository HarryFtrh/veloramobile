import 'package:flutter/material.dart';
import '../../../../core/design/tokens.dart';

/// Portion quantity stepper and barista/kitchen note input section
class FnbModifierQuantityBar extends StatelessWidget {
  final int quantity;
  final TextEditingController noteCtrl;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const FnbModifierQuantityBar({
    super.key,
    required this.quantity,
    required this.noteCtrl,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kontrol Porsi (Quantity)
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jumlah Porsi',
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tentukan banyak porsi dengan varian ini',
                    style: TextStyle(fontSize: 11, color: p.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: p.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: p.line),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: quantity > 1 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    child: InkWell(
                      onTap: quantity > 1 ? onDecrement : null,
                      borderRadius: BorderRadius.circular(7),
                      child: Padding(
                        padding: const EdgeInsets.all(7),
                        child: Icon(
                          Icons.remove_rounded,
                          size: 18,
                          color: quantity > 1 ? p.textPrimary : p.textTertiary,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      '$quantity',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: p.textPrimary,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(7),
                    child: InkWell(
                      onTap: onIncrement,
                      borderRadius: BorderRadius.circular(7),
                      child: Padding(
                        padding: const EdgeInsets.all(7),
                        child: Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Catatan Barista / Dapur
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note_rounded, size: 18, color: primaryColor),
                const SizedBox(width: 6),
                Text(
                  'Catatan Barista / Dapur',
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(Opsional)',
                  style: TextStyle(fontSize: 11, color: p.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              minLines: 1,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'Mis: Pisah sirup, es sedikit, less sugar...',
                hintStyle: TextStyle(fontSize: 12, color: p.textTertiary),
                filled: true,
                fillColor: p.surfaceMuted,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: p.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: p.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: primaryColor, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
