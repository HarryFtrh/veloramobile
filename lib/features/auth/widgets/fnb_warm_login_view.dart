import 'package:flutter/material.dart';

import '../../../core/components/velora_logo.dart';
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
  final VoidCallback onToggleObscurePassword;
  final ValueChanged<bool> onToggleRememberMe;
  final VoidCallback onLogin;
  final VoidCallback onGoogleLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
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

                            // Email atau Username
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
                              controller: emailController,
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
                                  onTap: onForgotPassword,
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
                              controller: passwordController,
                              obscureText: obscurePassword,
                              decoration: InputDecoration(
                                hintText: 'Masukkan kata sandi',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 20,
                                  color: WarmPalette.textSecondary,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    size: 20,
                                    color: WarmPalette.textSecondary,
                                  ),
                                  onPressed: onToggleObscurePassword,
                                ),
                                filled: true,
                                fillColor: WarmPalette.surfaceMuted,
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
                            if (errorMessage != null) ...[
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
                                        errorMessage!,
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
                                onPressed: (isLoading || isGoogleLoading) ? null : onLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6F3512),
                                  foregroundColor: Colors.white,
                                  shape: const StadiumBorder(),
                                  elevation: 2,
                                ),
                                child: isLoading
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

                            // Google Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: (isLoading || isGoogleLoading) ? null : onGoogleLogin,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: WarmPalette.line),
                                  shape: const StadiumBorder(),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: isGoogleLoading
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
