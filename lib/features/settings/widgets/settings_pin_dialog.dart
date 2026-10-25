// features/settings/widgets/settings_pin_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/tokens.dart';
import '../../auth/auth_service.dart';

class SettingsPinDialog extends StatefulWidget {
  const SettingsPinDialog({super.key, required this.isUpdate});
  final bool isUpdate;

  @override
  State<SettingsPinDialog> createState() => _SettingsPinDialogState();
}

class _SettingsPinDialogState extends State<SettingsPinDialog> {
  static const _length = 4;
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_pin.text.length != _length) {
      setState(() => _error = 'PIN harus $_length digit');
      return;
    }
    if (_pin.text != _confirm.text) {
      setState(() => _error = 'Konfirmasi PIN tidak sama');
      return;
    }
    await AuthService.instance.setQuickPin(_pin.text);
    if (mounted) Navigator.pop(context, true);
  }

  Widget _field(TextEditingController c, String label) => TextField(
        controller: c,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: _length,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: label, counterText: ''),
      );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.lock_outline_rounded,
                color: p.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.isUpdate ? 'Ubah PIN Cepat' : 'Atur PIN Cepat',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.dialogMaxWidth),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_pin, 'PIN baru'),
              const SizedBox(height: Gap.md),
              _field(_confirm, 'Ulangi PIN'),
              if (_error != null) ...[
                const SizedBox(height: Gap.sm),
                Text(
                  _error!,
                  style: TextStyle(
                    color: p.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Simpan PIN'),
        ),
      ],
    );
  }
}
