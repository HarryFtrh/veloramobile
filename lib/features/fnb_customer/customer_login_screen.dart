import '../../core/design/tokens.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/storage/session_storage.dart';
import '../auth/auth_service.dart';

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key, this.onLoginSuccess});

  final VoidCallback? onLoginSuccess;

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  final _emailCtrl = TextEditingController(text: '');
  final _passCtrl = TextEditingController(text: '');
  bool _obscurePass = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _errorMessage = 'Email dan kata sandi wajib diisi');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.login(email: email, password: pass);
      if (mounted) {
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        } else {
          Navigator.of(context).pop();
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        String? msg;
        final resData = e.response?.data;
        if (resData is Map) {
          msg = resData['message']?.toString();
        } else if (resData is String && resData.isNotEmpty) {
          msg = resData;
        }
        setState(() {
          _errorMessage = msg ?? 'Login gagal. Periksa koneksi internet atau akun Anda.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loginGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await AuthService.instance.loginWithGoogle();
      if (mounted) {
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        } else {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _continueAsGuest() {
    if (widget.onLoginSuccess != null) {
      widget.onLoginSuccess!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF24150D),
      body: Stack(
        children: [
          // Background coffee atmosphere
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: WarmPalette.secondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Kopi & Eatery',
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () {},
                        icon: const Icon(Icons.help_outline_rounded, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Brand Logo & Header
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: WarmPalette.canvas,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.coffee_rounded, size: 36, color: WarmPalette.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    SessionStorage.instance.getTenantName() ?? 'Velora Self-Order',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Taste the Crafted Perfection',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),

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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: WarmPalette.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'PENGALAMAN RASA',
                            style: TextStyle(
                              color: WarmPalette.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Selamat Datang Kembali',
                          style: text.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: WarmPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Masuk untuk menikmati aroma kopi favoritmu',
                          style: text.bodyMedium?.copyWith(
                            color: WarmPalette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Email
                        const Text(
                          'Email atau Nomor Telepon',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: WarmPalette.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _emailCtrl,
                          decoration: InputDecoration(
                            hintText: 'nama@email.com',
                            prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20, color: WarmPalette.textSecondary),
                            filled: true,
                            fillColor: WarmPalette.surfaceMuted,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Kata Sandi',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: WarmPalette.textPrimary),
                            ),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Lupa kata sandi?',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: WarmPalette.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passCtrl,
                          obscureText: _obscurePass,
                          decoration: InputDecoration(
                            hintText: 'Minimal 8 karakter',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: WarmPalette.textSecondary),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                              onPressed: () => setState(() => _obscurePass = !_obscurePass),
                            ),
                            filled: true,
                            fillColor: WarmPalette.surfaceMuted,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Remember Me
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (v) => setState(() => _rememberMe = v ?? false),
                              activeColor: WarmPalette.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            const Text(
                              'Ingat saya di perangkat ini',
                              style: TextStyle(fontSize: 13, color: WarmPalette.textSecondary),
                            ),
                          ],
                        ),
                        // Error message
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
                                  child: Text(_errorMessage!, style: const TextStyle(color: WarmPalette.danger, fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Button Masuk
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: WarmPalette.primary,
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
                                      Text('Masuk Sekarang', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_rounded, size: 18),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Divider
                        Row(
                          children: [
                            const Expanded(child: Divider(color: WarmPalette.line)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'ATAU MASUK DENGAN',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: WarmPalette.textSecondary.withValues(alpha: 0.8)),
                              ),
                            ),
                            const Expanded(child: Divider(color: WarmPalette.line)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Social Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _loginGoogle,
                                icon: const Icon(Icons.g_mobiledata_rounded, size: 24, color: Colors.red),
                                label: const Text('Google', style: TextStyle(color: WarmPalette.textPrimary, fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: WarmPalette.line),
                                  shape: const StadiumBorder(),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _continueAsGuest,
                                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18, color: WarmPalette.primary),
                                label: const Text('Tamu (Meja)', style: TextStyle(color: WarmPalette.textPrimary, fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: WarmPalette.line),
                                  shape: const StadiumBorder(),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
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
                        'Belum punya akun? ',
                        style: TextStyle(color: WarmPalette.line, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'Daftar gratis ↗',
                          style: TextStyle(color: WarmPalette.secondary, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Velora Self-Order • Pesan Cepat dari Meja •',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
