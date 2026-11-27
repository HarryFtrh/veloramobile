import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/config/app_config.dart';
import '../../../core/design/components.dart';
import '../../../core/design/tokens.dart';
import 'login_branding.dart';
import 'velora_login_overlay.dart';
import 'velora_real_3d_hero.dart';

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
    this.showGoogleLogin = true,
    this.showForgotPassword = true,
    this.maintenanceMode = false,
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
  final bool showGoogleLogin;
  final bool showForgotPassword;
  final bool maintenanceMode;

  @override
  State<VeloraAnimatedLoginView> createState() => _VeloraAnimatedLoginViewState();
}

class _VeloraAnimatedLoginViewState extends State<VeloraAnimatedLoginView> {
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final config = AppConfig.instance;
    final screenSize = MediaQuery.sizeOf(context);
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    // Hanya pakai split 2 kolom saat tablet/desktop LANDSCAPE agar ilustrasi tidak terpotong tipis vertikal
    final isLandscapeSplit = screenWidth >= 840 && screenWidth > screenHeight;
    final isWide = isLandscapeSplit;
    final isTallPortrait = !isWide && screenHeight >= 900;
    final heroHeight = isTallPortrait
        ? (screenHeight * 0.40).clamp(280.0, 460.0)
        : (screenHeight * 0.34).clamp(220.0, 310.0);
    final showOverlay = widget.isLoading || widget.isGoogleLoading || widget.isLoginSuccess;

    final formColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Heading: "Welcome back"
        Text(
          'Welcome back',
          textAlign: isWide ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            fontSize: isWide ? 30 : 26,
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
          widget.greetingText,
          textAlign: isWide ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: primaryColor,
            height: 1.3,
          ),
        )
            .animate(delay: 60.ms)
            .fadeIn(duration: 360.ms)
            .slideY(begin: 0.14, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 3),
        Text(
          widget.branding.subtitle,
          textAlign: isWide ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: p.textSecondary,
            height: 1.35,
          ),
        )
            .animate(delay: 90.ms)
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
            if (widget.showForgotPassword)
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

        // Maintenance Mode Banner from HQ (`GET /v1/auth/settings`)
        if (widget.maintenanceMode) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: p.warning.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.warning.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Icon(Icons.engineering_rounded, size: 18, color: p.warning),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sistem sedang dalam pemeliharaan berkala. Coba masuk kembali beberapa saat lagi.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

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
            onPressed: (showOverlay || widget.maintenanceMode) ? null : widget.onLogin,
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

        if (widget.showGoogleLogin) ...[
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
              onPressed: (showOverlay || widget.maintenanceMode) ? null : widget.onGoogleLogin,
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
        ],

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
    );

    return Scaffold(
      backgroundColor: p.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (isWide)
            // Tablet / Desktop: Balanced 2-Column Split-Screen Layout
            SafeArea(
              child: Row(
                children: [
                  Expanded(
                    flex: 52,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 10, 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: _buildHeroHeader(
                          context: context,
                          p: p,
                          primaryColor: primaryColor,
                          isDark: isDark,
                          heroHeight: double.infinity,
                          appName: config.appName,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 48,
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: formColumn,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            // Mobile Phone: Top Studio Hero + Overlapping Rounded Sheet
            SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenHeight),
                child: Column(
                  children: [
                    _buildHeroHeader(
                      context: context,
                      p: p,
                      primaryColor: primaryColor,
                      isDark: isDark,
                      heroHeight: heroHeight,
                      appName: config.appName,
                    ),
                    Transform.translate(
                      offset: const Offset(0, -28),
                      child: Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          minHeight: (screenHeight - heroHeight + 28).clamp(0.0, double.infinity),
                        ),
                        alignment: isTallPortrait ? Alignment.center : Alignment.topCenter,
                        decoration: BoxDecoration(
                          color: p.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
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
                          isTallPortrait ? 24 : 30,
                          26,
                          MediaQuery.paddingOf(context).bottom + 24,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: formColumn,
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
    return SizedBox(
      height: heroHeight,
      width: double.infinity,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Real-time interactive 3D Velora POS Terminal & Orbiting Card stage
            VeloraReal3DHero(
              primaryColor: primaryColor,
              paused: widget.isLoading || widget.isGoogleLoading || widget.isLoginSuccess,
            ),

            // 2. Subtle atmospheric tint in Dark Mode & soft bottom blend into sheet
            if (isDark)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      p.canvas.withValues(alpha: 0.30),
                      p.canvas.withValues(alpha: 0.56),
                    ],
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.04),
                    ],
                  ),
                ),
              ),

            // 3. Clean floating Velora Brand Pill in the top negative space (no duplicate badge)
            SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: (isDark ? p.surface : Colors.white).withValues(alpha: isDark ? 0.86 : 0.90),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: (isDark ? p.line : Colors.white).withValues(alpha: 0.9),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const VeloraLogo(
                          size: 24,
                          withGlow: false,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          appName,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: p.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 420.ms)
                      .slideY(begin: -0.18, end: 0, curve: Curves.easeOutCubic),
                ),
              ),
            ),
          ],
        ),
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
    return ListenableBuilder(
      listenable: focusNode,
      builder: (_, _) {
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
      },
    );
  }
}
