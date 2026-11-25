import 'package:material_ui/material_ui.dart';

import '../../../core/design/tokens.dart';
import '../../../core/network/api_exception.dart';
import '../auth_service.dart';

/// Modal bottom sheet for registering a new business tenant and staff account.
Future<void> showRegisterTenantSheet(
  BuildContext context, {
  required void Function(AuthUser user) onRegistered,
}) {
  final nameCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final storeCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();
  String selectedBusinessType = 'cafe';
  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool busy = false;
  String? err;

  const businessTypes = <(String, String, IconData)>[
    ('cafe', 'Kafe / F&B', Icons.coffee_rounded),
    ('retail', 'Retail / Toko', Icons.storefront_rounded),
    ('pharmacy', 'Apotek / Farmasi', Icons.local_pharmacy_rounded),
  ];

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 540,
        maxHeight: MediaQuery.sizeOf(ctx).height * 0.92,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: StatefulBuilder(
          builder: (ctx, setSheetState) {
            final palette = ctx.palette;
            final primaryColor = Theme.of(ctx).colorScheme.primary;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                MediaQuery.viewInsetsOf(ctx).bottom + 24,
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
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: palette.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(err!, style: TextStyle(color: palette.danger, fontSize: 12)),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      'Jenis Bisnis',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: businessTypes.map((entry) {
                        final (code, label, icon) = entry;
                        final isSelected = selectedBusinessType == code;
                        return ChoiceChip(
                          showCheckmark: false,
                          avatar: Icon(
                            icon,
                            size: 16,
                            color: isSelected ? Colors.white : palette.textSecondary,
                          ),
                          label: Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : palette.textPrimary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: primaryColor,
                          backgroundColor: palette.surface,
                          side: BorderSide(color: isSelected ? primaryColor : palette.line),
                          onSelected: busy
                              ? null
                              : (selected) {
                                  if (selected) {
                                    setSheetState(() => selectedBusinessType = code);
                                  }
                                },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap Anda',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: storeCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nama Toko / Bisnis',
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: usernameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Username (opsional)',
                        hintText: 'otomatis dari email jika kosong',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
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
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email Aktif',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi (min. 8 karakter)',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setSheetState(() => obscurePassword = !obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPasswordCtrl,
                      obscureText: obscureConfirm,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Kata Sandi',
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setSheetState(() => obscureConfirm = !obscureConfirm),
                        ),
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
                                final username = usernameCtrl.text.trim();
                                final store = storeCtrl.text.trim();
                                final phone = phoneCtrl.text.trim();
                                final digitsOnlyPhone = phone.replaceAll(AppRegex.nonDigits, '');
                                final email = emailCtrl.text.trim();
                                final pass = passwordCtrl.text;
                                final confirmPass = confirmPasswordCtrl.text;

                                if (name.isEmpty || store.isEmpty || phone.isEmpty || email.isEmpty || pass.isEmpty) {
                                  setSheetState(() => err = 'Nama, nama toko, nomor HP, email, dan kata sandi wajib diisi');
                                  return;
                                }
                                if (digitsOnlyPhone.length < 9) {
                                  setSheetState(() => err = 'Nomor WhatsApp / HP minimal 9 digit angka');
                                  return;
                                }
                                if (pass.length < 8) {
                                  setSheetState(() => err = 'Kata sandi minimal 8 karakter');
                                  return;
                                }
                                if (pass != confirmPass) {
                                  setSheetState(() => err = 'Konfirmasi kata sandi tidak cocok');
                                  return;
                                }

                                setSheetState(() {
                                  busy = true;
                                  err = null;
                                });

                                try {
                                  final user = await AuthService.instance.register(
                                    name: name,
                                    username: username.isNotEmpty ? username : null,
                                    email: email,
                                    password: pass,
                                    storeName: store,
                                    phone: digitsOnlyPhone,
                                    businessType: selectedBusinessType,
                                  );
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  onRegistered(user);
                                } on ApiException catch (e) {
                                  setSheetState(() {
                                    busy = false;
                                    err = e.message;
                                  });
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
