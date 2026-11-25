import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/config/app_config.dart';
import '../../../core/design/components.dart';
import '../../../core/design/tokens.dart';
import 'login_branding.dart';

/// Clean card login screen view for standard application themes (Pharmacy, Sales, Marketplace, Customer).
class StandardLoginView extends StatelessWidget {
  const StandardLoginView({
    super.key,
    required this.branding,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.rememberMe,
    required this.errorMessage,
    required this.isLoading,
    required this.isGoogleLoading,
    this.isLoginSuccess = false,
    this.greetingText = 'Selamat Datang',
    required this.accentColor,
    required this.isWarm,
    required this.onToggleObscurePassword,
    required this.onToggleRememberMe,
    required this.onLogin,
    required this.onGoogleLogin,
    required this.onForgotPassword,
    required this.onRegister,
  });

  final LoginBranding branding;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool rememberMe;
  final String? errorMessage;
  final bool isLoading;
  final bool isGoogleLoading;
  final bool isLoginSuccess;
  final String greetingText;
  final Color accentColor;
  final bool isWarm;
  final VoidCallback onToggleObscurePassword;
  final ValueChanged<bool> onToggleRememberMe;
  final VoidCallback onLogin;
  final VoidCallback onGoogleLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final config = AppConfig.instance;

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
                    )
                        .animate()
                        .fadeIn(duration: 450.ms)
                        .scale(
                          begin: const Offset(0.84, 0.84),
                          end: const Offset(1, 1),
                          duration: 500.ms,
                          curve: Curves.easeOutBack,
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
                          Icon(branding.icon, size: 14, color: accentColor),
                          const SizedBox(width: 6),
                          Text(
                            '${branding.badge} • $greetingText',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate(delay: 90.ms)
                        .fadeIn(duration: 380.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                    const SizedBox(height: 10),
                    Text(
                      'Welcome Back!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: palette.textPrimary,
                      ),
                    )
                        .animate(delay: 140.ms)
                        .fadeIn(duration: 380.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                    const SizedBox(height: 4),
                    Text(
                      '${config.appName} — ${branding.subtitle}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.textSecondary,
                      ),
                    )
                        .animate(delay: 180.ms)
                        .fadeIn(duration: 380.ms),
                    const SizedBox(height: 24),
                    if (errorMessage != null) ...[
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
                                errorMessage!,
                                style: TextStyle(color: palette.danger, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 200.ms)
                          .shakeX(hz: 4, amount: 4, duration: 320.ms),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: branding.idLabel,
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          ),
                          onPressed: onToggleObscurePassword,
                        ),
                      ),
                      onSubmitted: (_) => onLogin(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: rememberMe,
                              onChanged: (v) => onToggleRememberMe(v ?? false),
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
                          onPressed: onForgotPassword,
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
                        backgroundColor: isLoginSuccess ? const Color(0xFF059669) : accentColor,
                        disabledBackgroundColor: isLoginSuccess
                            ? const Color(0xFF059669)
                            : accentColor.withValues(alpha: 0.7),
                        foregroundColor: isLoginSuccess
                            ? Colors.white
                            : (accentColor.computeLuminance() > 0.4 ? Colors.black : Colors.white),
                        disabledForegroundColor: isLoginSuccess
                            ? Colors.white
                            : (accentColor.computeLuminance() > 0.4 ? Colors.black : Colors.white),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: (isLoading || isGoogleLoading || isLoginSuccess) ? null : onLogin,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutBack,
                        child: isLoginSuccess
                            ? const Row(
                                key: ValueKey('std_login_success'),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 20, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Berhasil Masuk!', style: TextStyle(fontWeight: FontWeight.w800)),
                                ],
                              )
                            : isLoading
                                ? Row(
                                    key: const ValueKey('std_login_loading'),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: accentColor.computeLuminance() > 0.4 ? Colors.black : Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text('Memverifikasi...'),
                                    ],
                                  )
                                : Row(
                                    key: const ValueKey('std_login_idle'),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(branding.buttonLabel),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_rounded, size: 18),
                                    ],
                                  ),
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
                      onPressed: (isLoading || isGoogleLoading) ? null : onGoogleLogin,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: palette.surface,
                        foregroundColor: palette.textPrimary,
                        side: BorderSide(color: palette.line, width: 1.2),
                        minimumSize: const Size.fromHeight(48),
                        shape: isWarm
                            ? const StadiumBorder()
                            : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isGoogleLoading
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
                    if (branding.showRegister)
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Belum punya akun toko? ',
                            style: TextStyle(color: palette.textSecondary, fontSize: 13),
                          ),
                          GestureDetector(
                            onTap: onRegister,
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
              )
                  .animate()
                  .fadeIn(duration: 420.ms)
                  .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
            ),
          ),
        ),
      ),
    );
  }
}
