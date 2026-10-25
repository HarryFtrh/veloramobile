import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../auth_service.dart';

/// Modal bottom sheet for registering a new business tenant and staff account.
Future<void> showRegisterTenantSheet(
  BuildContext context, {
  required void Function(AuthUser user) onRegistered,
}) {
  final nameCtrl = TextEditingController();
  final storeCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool busy = false;
  String? err;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 540,
        maxHeight: MediaQuery.sizeOf(ctx).height * 0.90,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: StatefulBuilder(
          builder: (ctx, setSheetState) {
            final palette = ctx.palette;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daftar Toko Baru',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: busy ? null : () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    Text(
                      'Buka akun toko dan bisnis baru Anda di ekosistem Velora',
                      style: TextStyle(fontSize: 13, color: palette.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    if (err != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: palette.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(err!, style: TextStyle(color: palette.danger, fontSize: 12)),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap Anda',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: storeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Toko / Kafe',
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Nomor WhatsApp / HP',
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: '08123456789',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Aktif',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Kata Sandi (min. 8 karakter)',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: busy
                            ? null
                            : () async {
                                final name = nameCtrl.text.trim();
                                final store = storeCtrl.text.trim();
                                final phone = phoneCtrl.text.trim();
                                final email = emailCtrl.text.trim();
                                final pass = passwordCtrl.text;

                                if (name.isEmpty || store.isEmpty || email.isEmpty || pass.isEmpty) {
                                  setSheetState(() => err = 'Nama, nama toko, email, dan kata sandi wajib diisi');
                                  return;
                                }
                                if (pass.length < 8) {
                                  setSheetState(() => err = 'Kata sandi minimal 8 karakter');
                                  return;
                                }

                                setSheetState(() {
                                  busy = true;
                                  err = null;
                                });

                                try {
                                  final user = await AuthService.instance.register(
                                    name: name,
                                    email: email,
                                    password: pass,
                                    storeName: store,
                                    phone: phone.isNotEmpty ? phone : null,
                                    businessType: 'cafe',
                                  );
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  onRegistered(user);
                                } catch (e) {
                                  setSheetState(() {
                                    busy = false;
                                    err = 'Registrasi gagal: ${e.toString().replaceFirst("ApiException: ", "").replaceFirst("Exception: ", "")}';
                                  });
                                }
                              },
                        child: busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Daftar & Masuk'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
