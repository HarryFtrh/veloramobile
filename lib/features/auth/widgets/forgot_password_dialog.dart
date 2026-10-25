import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../auth_service.dart';

/// Dialog for requesting a password reset email link.
Future<void> showForgotPasswordDialog(
  BuildContext context, {
  String? initialEmail,
}) {
  final emailCtrl = TextEditingController(text: initialEmail ?? '');
  bool busy = false;
  String? err;
  final p = context.palette;
  final isMobile = context.isMobile;

  return showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDlgState) {
        return Dialog(
          backgroundColor: p.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: p.line, width: 1.2),
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 32,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.dialogMaxWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 20 : 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: p.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.lock_reset_rounded, color: p.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lupa Kata Sandi',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: p.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Atur ulang kata sandi akun Anda',
                              style: TextStyle(fontSize: 12, color: p.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Masukkan email akun Anda. Kami akan mengirimkan tautan untuk mengatur ulang kata sandi.',
                    style: TextStyle(fontSize: 13, color: p.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  if (err != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: p.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: p.danger.withValues(alpha: 0.3)),
                      ),
                      child: Text(err!, style: TextStyle(color: p.danger, fontSize: 12)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: p.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Alamat Email',
                      labelStyle: TextStyle(color: p.textSecondary),
                      prefixIcon: Icon(Icons.email_outlined, color: p.primary),
                      filled: true,
                      fillColor: p.canvas,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: p.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: p.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: p.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: busy ? null : () => Navigator.pop(ctx),
                        child: Text('Batal', style: TextStyle(color: p.textSecondary, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: p.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        onPressed: busy
                            ? null
                            : () async {
                                final em = emailCtrl.text.trim();
                                if (em.isEmpty) {
                                  setDlgState(() => err = 'Email wajib diisi');
                                  return;
                                }
                                setDlgState(() {
                                  busy = true;
                                  err = null;
                                });
                                try {
                                  await AuthService.instance.forgotPassword(em);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Tautan reset kata sandi telah dikirim ke email Anda.'),
                                        backgroundColor: p.success,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setDlgState(() {
                                    busy = false;
                                    err = e.toString().replaceFirst("ApiException: ", "").replaceFirst("Exception: ", "");
                                  });
                                }
                              },
                        child: busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Kirim Tautan', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
