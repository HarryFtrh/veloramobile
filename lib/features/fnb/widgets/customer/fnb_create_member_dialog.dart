import 'package:flutter/material.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/network/api_exception.dart';
import '../../../customers/customer_service.dart';
import '../../models/fnb_customer_picker_result.dart';

/// Dialog to register a new loyalty member on the fly in FnB POS
class FnbCreateMemberDialog extends StatefulWidget {
  const FnbCreateMemberDialog({super.key});

  static Future<FnbCustomerPickerResult?> show(BuildContext context) {
    return showDialog<FnbCustomerPickerResult>(
      context: context,
      builder: (ctx) => const FnbCreateMemberDialog(),
    );
  }

  @override
  State<FnbCreateMemberDialog> createState() => _FnbCreateMemberDialogState();
}

class _FnbCreateMemberDialogState extends State<FnbCreateMemberDialog> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  String? err;
  bool saving = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.person_add_alt_1_rounded, color: p.primary, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('Daftar Member Baru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (err != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: p.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(err!, style: TextStyle(color: p.danger, fontSize: 12)),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                prefixIcon: Icon(Icons.badge_outlined),
                hintText: 'Mis. Cindy Wijaya',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor WhatsApp / HP',
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: 'Mis. 081234567890',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email (Opsional)',
                prefixIcon: Icon(Icons.email_outlined),
                hintText: 'nama@email.com',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: saving
              ? null
              : () async {
                  final nm = nameCtrl.text.trim();
                  final ph = phoneCtrl.text.trim();
                  if (nm.isEmpty || ph.isEmpty) {
                    setState(() => err = 'Nama dan Nomor HP wajib diisi');
                    return;
                  }

                  setState(() {
                    saving = true;
                    err = null;
                  });

                  final navigator = Navigator.of(context);
                  try {
                    await CustomerService.instance.createCustomer(
                      name: nm,
                      phone: ph,
                      email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                    );

                    if (!mounted) return;
                    navigator.pop(
                      FnbCustomerPickerResult(
                        name: nm,
                        phone: ph,
                        tier: 'Member Baru',
                        discountPercent: 0,
                      ),
                    );
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        saving = false;
                        err = ApiException.from(e).message;
                      });
                    }
                  }
                },
          child: saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Simpan & Pilih'),
        ),
      ],
    );
  }
}
