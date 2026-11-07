import 'package:flutter/material.dart';
import '../../../../core/design/tokens.dart';

/// Dialog to input a hold customer/tag name before parking an order
class FnbHoldOrderDialog extends StatefulWidget {
  final String defaultLabel;

  const FnbHoldOrderDialog({
    super.key,
    required this.defaultLabel,
  });

  static Future<String?> show(BuildContext context, {required String defaultLabel}) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => FnbHoldOrderDialog(defaultLabel: defaultLabel),
    );
  }

  @override
  State<FnbHoldOrderDialog> createState() => _FnbHoldOrderDialogState();
}

class _FnbHoldOrderDialogState extends State<FnbHoldOrderDialog> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.defaultLabel);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
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
              color: context.palette.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.pause_circle_outline_rounded, color: context.palette.secondary, size: 22),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Simpan Antrean (Hold)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Beri nama atau penanda pelanggan untuk antrean ini:',
            style: TextStyle(fontSize: 13, color: context.palette.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nama Pelanggan / Penanda Antrean',
              filled: true,
              fillColor: context.palette.surfaceMuted,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.palette.line)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _nameCtrl.text.trim()),
          child: const Text('Simpan Antrean'),
        ),
      ],
    );
  }
}
