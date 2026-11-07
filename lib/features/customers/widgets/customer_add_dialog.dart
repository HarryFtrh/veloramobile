import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../core/network/api_exception.dart';
import '../customer_service.dart';

/// Modal dialog for registering a new customer / loyalty member
class CustomerAddDialog extends StatefulWidget {
  final VoidCallback onSaved;

  const CustomerAddDialog({
    super.key,
    required this.onSaved,
  });

  static Future<void> show(BuildContext context, {required VoidCallback onSaved}) {
    return showDialog(
      context: context,
      builder: (ctx) => CustomerAddDialog(onSaved: onSaved),
    );
  }

  @override
  State<CustomerAddDialog> createState() => _CustomerAddDialogState();
}

class _CustomerAddDialogState extends State<CustomerAddDialog> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _saving = false;
  String? _err;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nm = _nameCtrl.text.trim();
    final ph = _phoneCtrl.text.trim();
    if (nm.isEmpty || ph.isEmpty) {
      setState(() => _err = 'Nama dan Nomor HP wajib diisi');
      return;
    }

    setState(() {
      _saving = true;
      _err = null;
    });

    try {
      await CustomerService.instance.createCustomer(
        name: nm,
        phone: ph,
        email: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ Pelanggan $nm berhasil ditambahkan')),
        );
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _err = ApiException.from(e).message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.person_add_rounded, color: primaryColor),
          const SizedBox(width: 10),
          const Text('Tambah Pelanggan Baru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_err != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: p.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_err!, style: TextStyle(color: p.danger, fontSize: 12)),
              ),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap *',
                hintText: 'Mis. Budi Santoso',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor WhatsApp / HP *',
                hintText: '0812xxxxxxx',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email (Opsional)',
                hintText: 'budi@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
