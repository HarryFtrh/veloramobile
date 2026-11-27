import 'package:material_ui/material_ui.dart';

import '../../../core/config/app_config.dart';
import '../../../core/design/tokens.dart';
import '../../../core/network/api_exception.dart';
import '../auth_service.dart';

/// Modal bottom sheet for registering a new business tenant and owner account.
/// Dynamically adapts fields & labels for `cafe`, `retail`, `pharmacy`, and `pbf`
/// using `GET /api/v1/auth/settings` (`registration_schema`) and submits to
/// `POST /api/v1/register`.
Future<void> showRegisterTenantSheet(
  BuildContext context, {
  required void Function(AuthUser user) onRegistered,
  AuthPublicSettings? initialSettings,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _RegisterTenantSheetContent(
      onRegistered: onRegistered,
      initialSettings: initialSettings,
    ),
  );
}

class _RegisterTenantSheetContent extends StatefulWidget {
  const _RegisterTenantSheetContent({
    required this.onRegistered,
    this.initialSettings,
  });

  final void Function(AuthUser user) onRegistered;
  final AuthPublicSettings? initialSettings;

  @override
  State<_RegisterTenantSheetContent> createState() =>
      _RegisterTenantSheetContentState();
}

class _RegisterTenantSheetContentState
    extends State<_RegisterTenantSheetContent> {
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _storeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _voucherCtrl = TextEditingController();
  final Map<String, TextEditingController> _extraCtrls = {};

  late AuthPublicSettings _settings;
  late String _selectedBusinessType;
  bool _loadingSettings = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _busy = false;
  String? _err;

  static final _hasUpper = RegExp(r'[A-Z]');
  static final _hasLower = RegExp(r'[a-z]');
  static final _hasDigit = RegExp(r'[0-9]');
  static final _hasSymbol = RegExp(r'[^a-zA-Z0-9]');
  static final _usernameRegex = RegExp(r'^[a-z0-9_.-]{3,50}$');
  static final _npwpRegex = RegExp(r'^[\d\-]{1,20}$');
  static final _voucherRegex = RegExp(r'^[A-Z0-9\-]{1,50}$');

  List<String> _filteredBusinessTypes() {
    final allKeys = _settings.registrationSchema.keys.toList();
    final config = AppConfig.instance;
    // Pada app unified (`Velora POS`), tampilkan semua 4 tipe bisnis.
    if (config.appName == 'Velora POS') return allKeys;
    return switch (config.flavor) {
      AppFlavor.pharmacy => allKeys.where((k) => k == 'pharmacy' || k == 'pbf').toList(),
      AppFlavor.fnb => allKeys.where((k) => k == 'cafe' || k == 'retail').toList(),
      _ => allKeys,
    };
  }

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings ?? AuthPublicSettings.defaults();
    _selectedBusinessType = switch (AppConfig.instance.flavor) {
      AppFlavor.pharmacy => 'pharmacy',
      AppFlavor.fnb => 'cafe',
      _ => 'retail',
    };
    if (widget.initialSettings == null) {
      _loadSettings();
    }
  }

  Future<void> _loadSettings() async {
    setState(() => _loadingSettings = true);
    final loaded = await AuthService.instance.getAuthSettings();
    if (!mounted) return;
    setState(() {
      _settings = loaded;
      _loadingSettings = false;
    });
  }

  TextEditingController _extraCtrlFor(String key) =>
      _extraCtrls.putIfAbsent(key, TextEditingController.new);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _storeCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _addressCtrl.dispose();
    _voucherCtrl.dispose();
    for (final c in _extraCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  IconData _iconForType(String code) {
    return switch (code) {
      'cafe' => Icons.coffee_rounded,
      'retail' => Icons.storefront_rounded,
      'pharmacy' => Icons.local_pharmacy_rounded,
      'pbf' => Icons.local_shipping_rounded,
      _ => Icons.business_rounded,
    };
  }

  IconData _iconForExtraField(String key) {
    return switch (key) {
      'sia_number' => Icons.verified_outlined,
      'sipa_number' => Icons.badge_outlined,
      'pharmacist_name' => Icons.medical_information_outlined,
      'npwp_number' => Icons.receipt_long_outlined,
      _ => Icons.description_outlined,
    };
  }

  Future<void> _submit() async {
    final schema = _settings.schemaFor(_selectedBusinessType);
    final name = _nameCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    final store = _storeCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final digitsOnlyPhone = phone.replaceAll(AppRegex.nonDigits, '');
    final email = _emailCtrl.text.trim();
    final pass = _passwordCtrl.text;
    final confirmPass = _confirmPasswordCtrl.text;

    if (name.isEmpty ||
        store.isEmpty ||
        phone.isEmpty ||
        email.isEmpty ||
        pass.isEmpty) {
      setState(() => _err =
          'Nama lengkap, ${schema.businessNameLabel.toLowerCase()}, nomor HP, email, dan kata sandi wajib diisi.');
      return;
    }
    if (store.length < 3) {
      setState(() => _err = '${schema.businessNameLabel} minimal 3 karakter.');
      return;
    }
    if (username.isNotEmpty && !_usernameRegex.hasMatch(username)) {
      setState(() => _err =
          'Username harus 3–50 karakter huruf kecil, angka, titik, strip, atau underscore (contoh: kopi_senja).');
      return;
    }
    if (digitsOnlyPhone.length < 9 || digitsOnlyPhone.length > 15) {
      setState(() => _err = 'Nomor WhatsApp / HP harus 9–15 digit angka.');
      return;
    }
    if (pass.length < 8 ||
        !_hasUpper.hasMatch(pass) ||
        !_hasLower.hasMatch(pass) ||
        !_hasDigit.hasMatch(pass) ||
        !_hasSymbol.hasMatch(pass)) {
      setState(() => _err =
          'Kata sandi minimal 8 karakter dan wajib mengandung huruf besar, huruf kecil, angka, serta simbol (contoh: Velora123!).');
      return;
    }
    if (pass != confirmPass) {
      setState(() => _err = 'Konfirmasi kata sandi tidak cocok.');
      return;
    }

    final voucher = _voucherCtrl.text.trim().toUpperCase();
    if (voucher.isNotEmpty && !_voucherRegex.hasMatch(voucher)) {
      setState(() => _err = 'Kode voucher hanya boleh huruf kapital, angka, dan tanda hubung (-).');
      return;
    }

    // Validasi extra fields yang ditandai required oleh server + format NPWP
    final extraValues = <String, String>{};
    for (final field in schema.extraFields) {
      final val = _extraCtrlFor(field.key).text.trim();
      if (field.required && val.isEmpty) {
        setState(() => _err = '${field.label} wajib diisi.');
        return;
      }
      if (field.key == 'npwp_number' && val.isNotEmpty && !_npwpRegex.hasMatch(val)) {
        setState(() => _err = 'Format NPWP hanya boleh angka dan tanda hubung (-) maksimal 20 karakter.');
        return;
      }
      if (val.isNotEmpty) {
        extraValues[field.key] = val;
      }
    }

    setState(() {
      _busy = true;
      _err = null;
    });

    try {
      final user = await AuthService.instance.register(
        name: name,
        username: username.isNotEmpty ? username : null,
        email: email,
        password: pass,
        storeName: store,
        phone: digitsOnlyPhone,
        businessType: _selectedBusinessType,
        extraFields: extraValues,
        address: _addressCtrl.text.trim(),
        voucherCode: _voucherCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
      widget.onRegistered(user);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _err = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _err =
              'Registrasi gagal: ${e.toString().replaceFirst("ApiException: ", "").replaceFirst("Exception: ", "")}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final schema = _settings.schemaFor(_selectedBusinessType);
    final availableTypes = _filteredBusinessTypes();
    if (availableTypes.isNotEmpty && !availableTypes.contains(_selectedBusinessType)) {
      _selectedBusinessType = availableTypes.first;
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 540,
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            18,
            24,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: palette.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daftar Bisnis Baru',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _busy ? null : () => Navigator.pop(context),
                    ),
                  ],
                ),
                Text(
                  'Buka akun toko, apotek, atau PBF baru Anda di ekosistem Velora',
                  style: TextStyle(fontSize: 13, color: palette.textSecondary),
                ),
                const SizedBox(height: 16),

                if (_loadingSettings) ...[
                  VeloraOrbitLoader.page(
                    size: 64,
                    label: 'Memuat konfigurasi pendaftaran...',
                  ),
                ] else if (!_settings.allowPublicRegistration) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: palette.warning.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lock_outline_rounded,
                            color: palette.warning, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pendaftaran Publik Ditutup',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: palette.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pendaftaran akun baru saat ini dinonaktifkan oleh administrator Velora. Silakan hubungi tim admin untuk aktivasi akun bisnis Anda.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: palette.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup'),
                    ),
                  ),
                ] else ...[
                  if (_err != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: palette.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: palette.danger.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _err!,
                        style: TextStyle(
                          color: palette.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                    children: availableTypes.map((code) {
                      final typeSchema = _settings.schemaFor(code);
                      final isSelected = _selectedBusinessType == code;
                      return ChoiceChip(
                        showCheckmark: false,
                        avatar: Icon(
                          _iconForType(code),
                          size: 16,
                          color: isSelected ? Colors.white : palette.textSecondary,
                        ),
                        label: Text(
                          typeSchema.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : palette.textPrimary,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: primaryColor,
                        backgroundColor: palette.surface,
                        side: BorderSide(
                          color: isSelected ? primaryColor : palette.line,
                        ),
                        onSelected: _busy
                            ? null
                            : (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedBusinessType = code;
                                    _err = null;
                                  });
                                }
                              },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap Owner',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _storeCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: schema.businessNameLabel,
                      prefixIcon: Icon(_iconForType(_selectedBusinessType)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _usernameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Username (opsional)',
                      hintText: 'otomatis dari email jika kosong',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nomor WhatsApp / HP',
                      prefixIcon: Icon(Icons.phone_outlined),
                      hintText: '081234567890',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email Aktif',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Kata Sandi',
                      helperText: 'Min. 8 karakter: huruf besar, kecil, angka & simbol',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPasswordCtrl,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Kata Sandi',
                      prefixIcon: const Icon(Icons.lock_reset_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                  ),

                  // Dynamic Extra Fields per Business Type (Pharmacy / PBF / Cafe / Retail)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (schema.extraFields.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            _selectedBusinessType == 'pharmacy' ||
                                    _selectedBusinessType == 'pbf'
                                ? 'Data Legalitas & Perizinan (Opsional)'
                                : 'Informasi Tambahan (Opsional)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: palette.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final field in schema.extraFields) ...[
                            TextField(
                              controller: _extraCtrlFor(field.key),
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: field.required
                                    ? '${field.label} *'
                                    : '${field.label} (opsional)',
                                prefixIcon: Icon(_iconForExtraField(field.key)),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ],
                    ),
                  ),

                  TextField(
                    controller: _addressCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Alamat Bisnis (opsional)',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _voucherCtrl,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Kode Voucher / Referral (opsional)',
                      prefixIcon: Icon(Icons.confirmation_number_outlined),
                    ),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const VeloraOrbitLoader.inline(
                              size: 20,
                              color: Colors.white,
                            )
                          : const Text('Daftar & Masuk'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
