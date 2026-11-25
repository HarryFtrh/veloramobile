import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/components.dart';
import '../../../core/design/tokens.dart';

/// Warm espresso coffee atmospheric login screen view designed specifically for FnB / Cafe POS.
class FnbWarmLoginView extends StatelessWidget {
  const FnbWarmLoginView({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.rememberMe,
    required this.errorMessage,
    required this.isLoading,
    required this.isGoogleLoading,
    this.isLoginSuccess = false,
    this.greetingText = 'Selamat Datang',
    required this.onToggleObscurePassword,
    required this.onToggleRememberMe,
    required this.onLogin,
    required this.onGoogleLogin,
    required this.onForgotPassword,
    required this.onRegister,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool rememberMe;
  final String? errorMessage;
  final bool isLoading;
  final bool isGoogleLoading;
  final bool isLoginSuccess;
  final String greetingText;
  final VoidCallback onToggleObscurePassword;
  final ValueChanged<bool> onToggleRememberMe;
  final VoidCallback onLogin;
  final VoidCallback onGoogleLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: p.textPrimary,
      body: Stack(
        children: [
          // Atmospheric vertical background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryColor.withValues(alpha: 0.9),
                    Color.alphaBlend(primaryColor.withValues(alpha: 0.7), Colors.black),
                    Colors.black,
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
                      )
                          .animate()
                          .fadeIn(duration: 450.ms)
                          .scale(
                            begin: const Offset(0.84, 0.84),
                            end: const Offset(1, 1),
                            duration: 500.ms,
                            curve: Curves.easeOutBack,
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
                      )
                          .animate(delay: 90.ms)
                          .fadeIn(duration: 380.ms)
                          .slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic),
                      const SizedBox(height: 4),
                      Text(
                        'Solusi POS Kafe & Restoran',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      )
                          .animate(delay: 140.ms)
                          .fadeIn(duration: 380.ms)
                          .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                      const SizedBox(height: 24),

                      // Login Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: p.canvas,
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.waving_hand_rounded, size: 14, color: primaryColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$greetingText!',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Welcome Back!',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                                letterSpacing: -0.5,
                                color: p.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Senang melihat Anda kembali. Masuk untuk melanjutkan shift kasir.',
                              style: TextStyle(
                                fontSize: 13,
                                color: p.textSecondary,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Email atau Username
                            Text(
                              'Email atau Username',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: p.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'nama@email.com atau username',
                                prefixIcon: Icon(
                                  Icons.mail_outline_rounded,
                                  size: 20,
                                  color: p.textSecondary,
                                ),
                                filled: true,
                                fillColor: p.surfaceMuted,
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
                                Text(
                                  'Kata Sandi',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: p.textPrimary,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: onForgotPassword,
                                  child: Text(
                                    'Lupa kata sandi?',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: passwordController,
                              obscureText: obscurePassword,
                              decoration: InputDecoration(
                                hintText: 'Masukkan kata sandi',
                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  size: 20,
                                  color: p.textSecondary,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    size: 20,
                                    color: p.textSecondary,
                                  ),
                                  onPressed: onToggleObscurePassword,
                                ),
                                filled: true,
                                fillColor: p.surfaceMuted,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                isDense: true,
                              ),
                              onSubmitted: (_) => onLogin(),
                            ),
                            const SizedBox(height: 10),

                            // Remember Me Checkbox
                            Row(
                              children: [
                                Checkbox(
                                  value: rememberMe,
                                  onChanged: (v) => onToggleRememberMe(v ?? false),
                                  activeColor: primaryColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                                Text(
                                  'Ingat saya di perangkat ini',
                                  style: TextStyle(fontSize: 13, color: p.textSecondary),
                                ),
                              ],
                            ),

                            // Error Message
                            if (errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: p.danger.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: p.danger.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline_rounded, size: 18, color: p.danger),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        errorMessage!,
                                        style: TextStyle(
                                          color: p.danger,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 200.ms)
                                  .shakeX(hz: 4, amount: 4, duration: 320.ms),
                              const SizedBox(height: 14),
                            ],

                            // Button Masuk Sekarang (3-state animated: idle -> loading -> success)
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: (isLoading || isGoogleLoading || isLoginSuccess) ? null : onLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isLoginSuccess ? const Color(0xFF059669) : primaryColor,
                                  disabledBackgroundColor: isLoginSuccess
                                      ? const Color(0xFF059669)
                                      : primaryColor.withValues(alpha: 0.7),
                                  foregroundColor: Colors.white,
                                  disabledForegroundColor: Colors.white,
                                  shape: const StadiumBorder(),
                                  elevation: 2,
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 260),
                                  switchInCurve: Curves.easeOutBack,
                                  child: isLoginSuccess
                                      ? const Row(
                                          key: ValueKey('login_success'),
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check_circle_rounded, size: 20, color: Colors.white),
                                            SizedBox(width: 8),
                                            Text(
                                              'Berhasil Masuk!',
                                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                            ),
                                          ],
                                        )
                                      : isLoading
                                          ? const Row(
                                              key: ValueKey('login_loading'),
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2.2,
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Text(
                                                  'Memverifikasi...',
                                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                                ),
                                              ],
                                            )
                                          : const Row(
                                              key: ValueKey('login_idle'),
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
                            ),
                            const SizedBox(height: 20),

                            // Divider ATAU MASUK DENGAN
                            Row(
                              children: [
                                Expanded(child: Divider(color: p.line)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'ATAU MASUK DENGAN',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: p.textSecondary.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: p.line)),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Google Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: (isLoading || isGoogleLoading) ? null : onGoogleLogin,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: BorderSide(color: p.line),
                                  shape: const StadiumBorder(),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: isGoogleLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const GoogleLogo(size: 18),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Google',
                                            style: TextStyle(
                                              color: p.textPrimary,
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
                      )
                          .animate(delay: 180.ms)
                          .fadeIn(duration: 460.ms)
                          .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
                      const SizedBox(height: 20),

                      // Footer
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Toko belum terdaftar? ',
                            style: TextStyle(color: p.line, fontSize: 13),
                          ),
                          GestureDetector(
                            onTap: onRegister,
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
}
