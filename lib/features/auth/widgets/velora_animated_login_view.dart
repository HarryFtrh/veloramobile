import 'dart:math' as math;

import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/config/app_config.dart';
import '../../../core/design/components.dart';
import '../../../core/design/tokens.dart';
import 'login_branding.dart';
import 'velora_login_overlay.dart';

/// Clean split-header + overlapping rounded sheet login view with Velora branding,
/// smooth focus-state field transitions, and a frosted-glass orbiting loading overlay.
class VeloraAnimatedLoginView extends StatefulWidget {
  const VeloraAnimatedLoginView({
    super.key,
    required this.branding,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.rememberMe,
    required this.errorMessage,
    required this.isLoading,
    required this.isGoogleLoading,
    required this.isLoginSuccess,
    required this.greetingText,
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
  final VoidCallback onToggleObscurePassword;
  final ValueChanged<bool> onToggleRememberMe;
  final VoidCallback onLogin;
  final VoidCallback onGoogleLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onRegister;

  @override
  State<VeloraAnimatedLoginView> createState() => _VeloraAnimatedLoginViewState();
}

class _VeloraAnimatedLoginViewState extends State<VeloraAnimatedLoginView>
    with SingleTickerProviderStateMixin {
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  late final AnimationController _arcCtrl;

  @override
  void initState() {
    super.initState();
    _arcCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
    _emailFocus.addListener(_onFocusChange);
    _passwordFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _emailFocus.removeListener(_onFocusChange);
    _passwordFocus.removeListener(_onFocusChange);
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _arcCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final config = AppConfig.instance;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    final heroHeight = (screenHeight * 0.34).clamp(220.0, 310.0);
    final showOverlay = widget.isLoading || widget.isGoogleLoading || widget.isLoginSuccess;

    return Scaffold(
      backgroundColor: p.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Main scrollable split layout (Hero Header + Overlapping Rounded Card)
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: screenHeight),
              child: Column(
                children: [
                  // Top Illustrated / Atmospheric Velora Brand Header
                  _buildHeroHeader(
                    context: context,
                    p: p,
                    primaryColor: primaryColor,
                    isDark: isDark,
                    heroHeight: heroHeight,
                    appName: config.appName,
                  ),

                  // Bottom Overlapping Rounded Sheet Card
                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isWide ? 460 : double.infinity),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: p.surface,
                            borderRadius: BorderRadius.vertical(
                              top: const Radius.circular(32),
                              bottom: isWide ? const Radius.circular(28) : Radius.zero,
                            ),
                            border: isWide ? Border.all(color: p.line) : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                                blurRadius: 28,
                                offset: const Offset(0, -6),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.fromLTRB(
                            26,
                            30,
                            26,
                            MediaQuery.paddingOf(context).bottom + 24,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Heading: "Welcome back"
                              Text(
                                'Welcome back',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: p.textPrimary,
                                  letterSpacing: -0.6,
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 380.ms)
                                  .slideY(begin: 0.14, end: 0, curve: Curves.easeOutCubic),
                              const SizedBox(height: 6),
                              Text(
                                '${widget.greetingText} • ${widget.branding.subtitle}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: p.textSecondary,
                                  height: 1.35,
                                ),
                              )
                                  .animate(delay: 70.ms)
                                  .fadeIn(duration: 380.ms)
                                  .slideY(begin: 0.14, end: 0, curve: Curves.easeOutCubic),
                              const SizedBox(height: 26),

                              // Email / Username Input with smooth Focus Animation
                              _buildAnimatedField(
                                p: p,
                                primaryColor: primaryColor,
                                controller: widget.emailController,
                                focusNode: _emailFocus,
                                hintText: 'Masukkan email atau username',
                                prefixIcon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) => _passwordFocus.requestFocus(),
                              )
                                  .animate(delay: 120.ms)
                                  .fadeIn(duration: 380.ms)
                                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                              const SizedBox(height: 14),

                              // Password Input with smooth Focus Animation
                              _buildAnimatedField(
                                p: p,
                                primaryColor: primaryColor,
                                controller: widget.passwordController,
                                focusNode: _passwordFocus,
                                hintText: 'Masukkan kata sandi',
                                prefixIcon: Icons.lock_outline_rounded,
                                obscureText: widget.obscurePassword,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => widget.onLogin(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    widget.obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                    color: _passwordFocus.hasFocus ? p.textPrimary : p.textTertiary,
                                  ),
                                  onPressed: widget.onToggleObscurePassword,
                                ),
                              )
                                  .animate(delay: 170.ms)
                                  .fadeIn(duration: 380.ms)
                                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                              const SizedBox(height: 14),

                              // Auxiliary Row: Remember Me + Forgot Password
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () => widget.onToggleRememberMe(!widget.rememberMe),
                                    behavior: HitTestBehavior.opaque,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 180),
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: widget.rememberMe ? primaryColor : Colors.transparent,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: widget.rememberMe ? primaryColor : p.line,
                                              width: 1.6,
                                            ),
                                          ),
                                          child: widget.rememberMe
                                              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Ingat saya',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: p.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: widget.onForgotPassword,
                                    child: Text(
                                      'Lupa kata sandi?',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                                  .animate(delay: 210.ms)
                                  .fadeIn(duration: 360.ms),
                              const SizedBox(height: 18),

                              // Animated Error Banner (shakeX on error)
                              if (widget.errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                  decoration: BoxDecoration(
                                    color: p.danger.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: p.danger.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline_rounded, size: 18, color: p.danger),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          widget.errorMessage!,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: p.danger,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                    .animate()
                                    .fadeIn(duration: 200.ms)
                                    .shakeX(hz: 4, amount: 4, duration: 300.ms),
                                const SizedBox(height: 16),
                              ],

                              // Primary Login Button
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: showOverlay ? null : widget.onLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    disabledBackgroundColor: primaryColor.withValues(alpha: 0.7),
                                    foregroundColor: Colors.white,
                                    disabledForegroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Masuk',
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              )
                                  .animate(delay: 250.ms)
                                  .fadeIn(duration: 400.ms)
                                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                              const SizedBox(height: 22),

                              // Divider: "Atau lanjutkan dengan"
                              Row(
                                children: [
                                  Expanded(child: Divider(color: p.line, height: 1)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'Atau lanjutkan dengan',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: p.textTertiary,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: p.line, height: 1)),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Google Outlined Rounded Button
                              SizedBox(
                                height: 50,
                                child: OutlinedButton(
                                  onPressed: showOverlay ? null : widget.onGoogleLogin,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: p.surface,
                                    side: BorderSide(color: p.line, width: 1.2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const GoogleLogo(size: 19),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Masuk dengan Google',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: p.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              if (widget.branding.showRegister) ...[
                                const SizedBox(height: 24),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      'Belum punya akun toko? ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: p.textSecondary,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: showOverlay ? null : widget.onRegister,
                                      child: Text(
                                        'Daftar Toko Baru',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Full-Screen Frosted-Glass Loading / Success Overlay (Skyward style)
          VeloraLoginOverlay(
            visible: showOverlay,
            isSuccess: widget.isLoginSuccess,
            accentColor: primaryColor,
            title: widget.isLoginSuccess
                ? 'Berhasil masuk!'
                : (widget.isGoogleLoading ? 'Menghubungkan Google...' : 'Sedang masuk...'),
            subtitle: widget.isLoginSuccess
                ? 'Membuka ruang kerja ${config.appName}'
                : 'Menyiapkan sesi kasir & outlet Anda',
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader({
    required BuildContext context,
    required AppPalette p,
    required Color primaryColor,
    required bool isDark,
    required double heroHeight,
    required String appName,
  }) {
    final topColor = isDark
        ? Color.lerp(p.canvas, primaryColor, 0.22)!
        : Color.lerp(primaryColor, const Color(0xFF0F172A), 0.35)!;
    final bottomColor = isDark
        ? Color.lerp(p.canvas, primaryColor, 0.08)!
        : primaryColor;

    return Container(
      height: heroHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [topColor, bottomColor],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle animated sweeping brand arc & layered horizon silhouettes
          AnimatedBuilder(
            animation: _arcCtrl,
            builder: (_, _) => CustomPaint(
              painter: _VeloraHeroBackdropPainter(
                progress: _arcCtrl.value,
                accentColor: Colors.white,
              ),
            ),
          ),

          // Centered Velora Logo & Wordmark
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const VeloraLogo(
                    size: 74,
                    borderRadius: 22,
                    withGlow: true,
                  )
                      .animate()
                      .fadeIn(duration: 450.ms)
                      .scale(
                        begin: const Offset(0.84, 0.84),
                        end: const Offset(1, 1),
                        duration: 520.ms,
                        curve: Curves.easeOutBack,
                      ),
                  const SizedBox(height: 14),
                  Text(
                    appName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  )
                      .animate(delay: 100.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.16, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.branding.icon, size: 13, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          widget.branding.badge,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate(delay: 160.ms)
                      .fadeIn(duration: 380.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedField({
    required AppPalette p,
    required Color primaryColor,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
    Widget? suffixIcon,
  }) {
    final isFocused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isFocused ? p.surface : p.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFocused ? primaryColor : Colors.transparent,
          width: 1.6,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: p.textPrimary,
        ),
        decoration: InputDecoration(
          filled: false,
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: p.textTertiary,
          ),
          prefixIcon: Icon(
            prefixIcon,
            size: 20,
            color: isFocused ? primaryColor : p.textTertiary,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _VeloraHeroBackdropPainter extends CustomPainter {
  const _VeloraHeroBackdropPainter({
    required this.progress,
    required this.accentColor,
  });

  final double progress;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Soft layered horizon curves at the bottom of the hero
    final wavePaint1 = Paint()
      ..color = accentColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    final path1 = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(size.width * 0.28, size.height * 0.56, size.width * 0.6, size.height * 0.70)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.80, size.width, size.height * 0.64)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path1, wavePaint1);

    final wavePaint2 = Paint()
      ..color = accentColor.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    final path2 = Path()
      ..moveTo(0, size.height * 0.84)
      ..quadraticBezierTo(size.width * 0.36, size.height * 0.70, size.width * 0.72, size.height * 0.82)
      ..quadraticBezierTo(size.width * 0.90, size.height * 0.88, size.width, size.height * 0.76)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path2, wavePaint2);

    // 2. Subtle sweeping orbital arc with moving sparkle
    final arcCenter = Offset(size.width * 0.5, size.height * 0.46);
    final arcRadius = math.min(size.width, size.height) * 0.42;
    final arcPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawArc(
      Rect.fromCircle(center: arcCenter, radius: arcRadius),
      -math.pi * 0.82,
      math.pi * 0.64,
      false,
      arcPaint,
    );

    final sparkAngle = -math.pi * 0.82 + (math.pi * 0.64 * ((math.sin(progress * 2 * math.pi) + 1) / 2));
    final sx = arcCenter.dx + arcRadius * math.cos(sparkAngle);
    final sy = arcCenter.dy + arcRadius * math.sin(sparkAngle);
    canvas.drawCircle(
      Offset(sx, sy),
      3.0,
      Paint()..color = accentColor.withValues(alpha: 0.75),
    );
    canvas.drawCircle(
      Offset(sx, sy),
      8.0,
      Paint()..color = accentColor.withValues(alpha: 0.20),
    );
  }

  @override
  bool shouldRepaint(covariant _VeloraHeroBackdropPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
