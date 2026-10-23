import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';
import '../../core/config/app_theme.dart';
import '../../core/design/tokens.dart';
import '../../core/components/google_logo.dart';
import '../../core/components/velora_logo.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/audio_helper.dart';
import 'auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// Teks & perilaku login yang berbeda untuk tiap app (flavor).
class _LoginBranding {
  const _LoginBranding({
    required this.badge,
    required this.icon,
    required this.subtitle,
    required this.buttonLabel,
    required this.idLabel,
    required this.branchTitle,
    this.showRegister = true,
  });

  final String badge;
  final IconData icon;
  final String subtitle;
  final String buttonLabel;
  final String idLabel;
  final String branchTitle;
  final bool showRegister;

  static _LoginBranding of(AppFlavor flavor) {
    switch (flavor) {
      case AppFlavor.pharmacy:
        return const _LoginBranding(
          badge: 'APOTEK',
          icon: Icons.medical_services_rounded,
          subtitle: 'Masuk untuk membuka kasir apotek & resep',
          buttonLabel: 'Masuk ke Apotek',
          idLabel: 'Email atau Username Apoteker',
          branchTitle: 'Pilih Cabang Apotek',
        );
      case AppFlavor.sales:
        return const _LoginBranding(
          badge: 'SALES FIELD',
          icon: Icons.route_rounded,
          subtitle: 'Masuk untuk memulai absensi & kunjungan sales',
          buttonLabel: 'Masuk Sales',
          idLabel: 'Email atau Username Sales',
          branchTitle: 'Pilih Area / Cabang',
          showRegister: false,
        );
      case AppFlavor.marketplace:
        return const _LoginBranding(
          badge: 'MARKETPLACE',
          icon: Icons.storefront_rounded,
          subtitle: 'Masuk untuk mengelola pesanan marketplace',
          buttonLabel: 'Masuk Marketplace',
          idLabel: 'Email atau Username Penjual',
          branchTitle: 'Pilih Toko',
        );
      case AppFlavor.customer:
        return const _LoginBranding(
          badge: 'SELF-ORDER',
          icon: Icons.coffee_rounded,
          subtitle: 'Masuk untuk memesan langsung dari meja',
          buttonLabel: 'Masuk Self-Order',
          idLabel: 'Email atau Nomor HP',
          branchTitle: 'Pilih Outlet Kafe',
        );
      case AppFlavor.fnb:
        return const _LoginBranding(
          badge: 'F&B',
          icon: Icons.coffee_rounded,
          subtitle: 'Masuk untuk mengelola pesanan & kafe',
          buttonLabel: 'Masuk Sekarang',
          idLabel: 'Email atau Username',
          branchTitle: 'Pilih Cabang',
        );
    }
  }
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  String? _errorMessage;

  _LoginBranding get _branding => _LoginBranding.of(AppConfig.instance.flavor);

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  void _loadRememberedCredentials() {
    final remember = SessionStorage.instance.getRememberMe();
    final savedId = SessionStorage.instance.getSavedLoginIdentifier();
    setState(() {
      _rememberMe = remember;
      if (remember && savedId != null && savedId.isNotEmpty) {
        _emailController.text = savedId;
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Email atau username dan kata sandi wajib diisi');
      AudioHelper.errorFeedback();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.instance.login(
        email: email,
        password: password,
      );

      // Simpan preferensi Ingat Saya dan kredensial login
      await SessionStorage.instance.saveRememberMe(
        rememberMe: _rememberMe,
        identifier: _rememberMe ? email : null,
      );

      AudioHelper.successFeedback();

      if (mounted) {
        if (user.locations.length > 1) {
          _showBranchSelectorDialog(user.locations);
        } else {
          widget.onLoginSuccess();
        }
      }
    } on DioException catch (e) {
      AudioHelper.errorFeedback();
      String? msg;
      final resData = e.response?.data;
      if (resData is Map) {
        msg = resData['message']?.toString();
      } else if (resData is String && resData.isNotEmpty) {
        msg = resData;
      }
      setState(() => _errorMessage = msg ?? 'Login gagal. Periksa koneksi internet atau kredensial Anda.');
    } catch (e) {
      AudioHelper.errorFeedback();
      final errText = e.toString().replaceFirst('Exception: ', '');
      setState(() => _errorMessage = errText.isNotEmpty ? errText : 'Terjadi kesalahan tidak terduga.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.instance.loginWithGoogle();
      AudioHelper.successFeedback();

      if (mounted) {
        if (user.locations.length > 1) {
          _showBranchSelectorDialog(user.locations);
        } else {
          widget.onLoginSuccess();
        }
      }
    } on DioException catch (e) {
      AudioHelper.errorFeedback();
      String? msg;
      final resData = e.response?.data;
      if (resData is Map) {
        msg = resData['message']?.toString();
      } else if (resData is String && resData.isNotEmpty) {
        msg = resData;
      }
      setState(() => _errorMessage = msg ?? 'Login Google gagal. Hubungi administrator toko.');
    } catch (e) {
      AudioHelper.errorFeedback();
      final errText = e.toString().replaceFirst('Exception: ', '');
      setState(() => _errorMessage = errText.isNotEmpty ? errText : 'Terjadi kesalahan saat otentikasi Google.');
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  void _showBranchSelectorDialog(List<BranchLocation> locations) {
    final p = context.palette;
    final isMobile = context.isMobile;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
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
            child: Padding(
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
                        child: Icon(Icons.storefront_rounded, color: p.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _branding.branchTitle,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: p.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pilih cabang untuk memulai sesi kasir',
                              style: TextStyle(fontSize: 12, color: p.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (locations.length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: p.surfaceMuted,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: p.line),
                          ),
                          child: Text(
                            '${locations.length} Cabang',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.textSecondary),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: locations.map((loc) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: p.canvas,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: loc.isMain ? p.primary.withValues(alpha: 0.5) : p.line,
                                  width: loc.isMain ? 1.5 : 1,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async {
                                  AudioHelper.tapFeedback();
                                  await AuthService.instance.selectBranch(loc);
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                  }
                                  if (mounted) {
                                    widget.onLoginSuccess();
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: loc.isMain ? p.primary.withValues(alpha: 0.15) : p.surfaceMuted,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          loc.isMain ? Icons.star_rounded : Icons.location_on_rounded,
                                          color: loc.isMain ? p.primary : p.textSecondary,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              loc.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: p.textPrimary,
                                              ),
                                            ),
                                            if (loc.isMain) ...[
                                              const SizedBox(height: 3),
                                              Text(
                                                'Cabang Utama',
                                                style: TextStyle(
                                                  color: p.primary,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: p.surfaceMuted,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: p.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      onPressed: () async {
                        await AuthService.instance.logout();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      icon: Icon(Icons.logout_rounded, size: 16, color: p.danger),
                      label: Text(
                        'Keluar / Ganti Akun',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.danger),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    bool busy = false;
    String? err;
    final p = context.palette;
    final isMobile = context.isMobile;

    showDialog(
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
                                    if (mounted) {
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
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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

  void _showRegisterDialog() {
    final nameCtrl = TextEditingController();
    final storeCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool busy = false;
    String? err;

    showModalBottomSheet(
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
                                if (mounted) {
                                  if (user.locations.length > 1) {
                                    _showBranchSelectorDialog(user.locations);
                                  } else {
                                    widget.onLoginSuccess();
                                  }
                                }
                              } catch (e) {
                                setSheetState(() {
                                  busy = false;
                                  err = 'Registrasi gagal: ${e.toString().replaceFirst("ApiException: ", "").replaceFirst("Exception: ", "")}';
                                });
                              }
                            },
                      child: busy
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final config = AppConfig.instance;
    final accentColor = AppTheme.getAccentColor(config.flavor);
    final isWarm = config.flavor == AppFlavor.fnb && theme.brightness == Brightness.light;

    if (isWarm) {
      return Scaffold(
        backgroundColor: const Color(0xFF24150D),
        body: Stack(
          children: [
            // Atmospheric espresso coffee background gradient
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF381F12),
                      Color(0xFF24150D),
                      Color(0xFF160D07),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),

                        const VeloraLogo(
                          size: 76,
                          borderRadius: 22,
                          withGlow: true,
                          useHeroImage: true,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Velora F&B',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Solusi POS Kafe & Restoran',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 26),

                        // Login Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: WarmPalette.canvas,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Masuk ke Velora',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                  color: WarmPalette.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Masukkan email atau username dan kata sandi Anda',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: WarmPalette.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Email atau Nomor Telepon
                              const Text(
                                'Email atau Username',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: WarmPalette.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: 'nama@email.com atau username',
                                  prefixIcon: const Icon(
                                    Icons.mail_outline_rounded,
                                    size: 20,
                                    color: WarmPalette.textSecondary,
                                  ),
                                  filled: true,
                                  fillColor: WarmPalette.surfaceMuted,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Kata Sandi & Lupa kata sandi
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Kata Sandi',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: WarmPalette.textPrimary,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _showForgotPasswordDialog,
                                    child: const Text(
                                      'Lupa kata sandi?',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF6F3512),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: 'Masukkan kata sandi',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 20,
                                    color: WarmPalette.textSecondary,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      size: 20,
                                      color: WarmPalette.textSecondary,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  filled: true,
                                  fillColor: WarmPalette.surfaceMuted,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  isDense: true,
                                ),
                                onSubmitted: (_) => _handleLogin(),
                              ),
                              const SizedBox(height: 10),

                              // Remember Me Checkbox
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                    activeColor: const Color(0xFF6F3512),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  ),
                                  const Text(
                                    'Ingat saya di perangkat ini',
                                    style: TextStyle(fontSize: 13, color: WarmPalette.textSecondary),
                                  ),
                                ],
                              ),

                              // Error Message
                              if (_errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: WarmPalette.danger.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: WarmPalette.danger.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline_rounded, size: 18, color: WarmPalette.danger),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            color: WarmPalette.danger,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],

                              // Button Masuk Sekarang
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: (_isLoading || _isGoogleLoading) ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6F3512),
                                    foregroundColor: Colors.white,
                                    shape: const StadiumBorder(),
                                    elevation: 2,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Masuk Sekarang',
                                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward_rounded, size: 18),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Divider ATAU MASUK DENGAN
                              Row(
                                children: [
                                  const Expanded(child: Divider(color: WarmPalette.line)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'ATAU MASUK DENGAN',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: WarmPalette.textSecondary.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ),
                                  const Expanded(child: Divider(color: WarmPalette.line)),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Google (Apple dihapus: sebelumnya auto-login kredensial hardcode)
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: (_isLoading || _isGoogleLoading) ? null : _handleGoogleLogin,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(color: WarmPalette.line),
                                    shape: const StadiumBorder(),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: _isGoogleLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            GoogleLogo(size: 18),
                                            SizedBox(width: 8),
                                            Text(
                                              'Google',
                                              style: TextStyle(
                                                color: WarmPalette.textPrimary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Toko belum terdaftar? ',
                              style: TextStyle(color: WarmPalette.line, fontSize: 13),
                            ),
                            GestureDetector(
                              onTap: _showRegisterDialog,
                              child: const Text(
                                'Daftar toko baru ↗',
                                style: TextStyle(
                                  color: Color(0xFFD97706),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Velora F&B • Solusi POS Bisnis',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: palette.line),
                  boxShadow: [
                    BoxShadow(
                      color: isWarm
                          ? const Color(0xFF4E2A11).withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const VeloraLogo(
                      size: 76,
                      borderRadius: 22,
                      withGlow: true,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_branding.icon, size: 14, color: accentColor),
                          const SizedBox(width: 6),
                          Text(
                            _branding.badge,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      config.appName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _branding.subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: palette.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: palette.danger.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline_rounded, color: palette.danger, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: palette.danger, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: _branding.idLabel,
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      onSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (v) => setState(() => _rememberMe = v ?? false),
                              activeColor: accentColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            Text(
                              'Ingat saya',
                              style: TextStyle(fontSize: 13, color: palette.textSecondary),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: _showForgotPasswordDialog,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Lupa kata sandi?',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: palette.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: accentColor.computeLuminance() > 0.4 ? Colors.black : Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: (_isLoading || _isGoogleLoading) ? null : _handleLogin,
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: accentColor.computeLuminance() > 0.4 ? Colors.black : Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_branding.buttonLabel),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: Divider(color: palette.line)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'atau',
                            style: TextStyle(color: palette.textTertiary, fontSize: 12),
                          ),
                        ),
                        Expanded(child: Divider(color: palette.line)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: (_isLoading || _isGoogleLoading) ? null : _handleGoogleLogin,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: palette.surface,
                        foregroundColor: palette.textPrimary,
                        side: BorderSide(color: palette.line, width: 1.2),
                        minimumSize: const Size.fromHeight(48),
                        shape: isWarm
                            ? const StadiumBorder()
                            : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isGoogleLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: accentColor,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const GoogleLogo(size: 18),
                                const SizedBox(width: 10),
                                Text(
                                  'Masuk dengan Google',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 24),
                    if (_branding.showRegister)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Belum punya akun toko? ',
                          style: TextStyle(color: palette.textSecondary, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: _showRegisterDialog,
                          child: Text(
                            'Daftar Toko Baru',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
