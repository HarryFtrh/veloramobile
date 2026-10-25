import 'package:flutter/material.dart';

import '../../../../core/design/components.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/safe_json.dart';
import '../../fnb_register_controller.dart';

/// Circular button for increasing or decreasing item quantities in cart.
class QtyButton extends StatelessWidget {
  const QtyButton({super.key, required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: context.palette.line)),
          child: Icon(icon, size: 18),
        ),
      );
}

/// Dialog for adding or updating barista special notes and kitchen instructions.
class EditNoteDialog extends StatefulWidget {
  const EditNoteDialog({super.key, required this.initialNote, required this.itemName});
  final String? initialNote;
  final String itemName;

  @override
  State<EditNoteDialog> createState() => _EditNoteDialogState();
}

class _EditNoteDialogState extends State<EditNoteDialog> {
  late final TextEditingController _c;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.palette.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.sticky_note_2_outlined, color: context.palette.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Catatan ${widget.itemName}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: TextField(
          controller: _c,
          autofocus: true,
          maxLength: 120,
          decoration: InputDecoration(
            hintText: 'Mis. Less ice, no sugar, dipisah',
            filled: true,
            fillColor: context.palette.surfaceMuted,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.palette.line),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(context, _c.text), child: const Text('Simpan Catatan')),
      ],
    );
  }
}

/// Card representing a single order line in the FnB order panel.
class OrderLineItem extends StatelessWidget {
  const OrderLineItem({
    super.key,
    required this.line,
    required this.onRemove,
    required this.onIncrement,
    required this.onDecrement,
    required this.onEditNote,
  });

  final RegisterLine line;
  final VoidCallback onRemove;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onEditNote;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(Gap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sanitizeDisplayName(line.name),
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              InkWell(
                onTap: onRemove,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 18, color: p.textTertiary),
                ),
              ),
            ],
          ),
          Text(
            '${CurrencyFormatter.format(line.unitPrice)} / item',
            style: text.bodySmall?.copyWith(color: p.textSecondary, fontSize: 11),
          ),
          if (line.options.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(color: p.surfaceMuted, borderRadius: Corner.small),
              child: Column(
                children: [
                  for (final o in line.options)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '• ${sanitizeDisplayName(o.name)}',
                            style: text.bodySmall?.copyWith(fontSize: 11),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(o.price),
                          style: text.bodySmall?.copyWith(color: p.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onEditNote,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      line.note == null ? '+ Tambah catatan barista' : '“${line.note}”',
                      style: text.bodySmall?.copyWith(
                        fontSize: 11,
                        color: line.note == null ? scheme.secondary : WarmPalette.secondary,
                        fontStyle: line.note == null ? FontStyle.normal : FontStyle.italic,
                        fontWeight: line.note == null ? FontWeight.w500 : FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              if (line.note != null)
                InkWell(
                  onTap: onEditNote,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Ubah',
                      style: TextStyle(
                        fontSize: 10,
                        color: WarmPalette.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              QtyButton(icon: Icons.remove, onTap: onDecrement),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.sm + 2),
                child: Text(
                  '${line.quantity}',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
              QtyButton(icon: Icons.add, onTap: onIncrement),
              const Spacer(),
              Text(
                CurrencyFormatter.format(line.subtotal),
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
