import 'dart:math' as math;

import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';

import '../config/app_config.dart';
import '../design/tokens.dart';
import 'velora_logo.dart';

/// Clean atmospheric Velora brand splash screen with gently floating 3D
/// VeloraLogo emblem and smooth orbiting dot loader.
class SplashScreen extends StatefulWidget {
  final String? message;

  const SplashScreen({super.key, this.message});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.instance;
    final p = context.palette;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final topColor = isDark
        ? Color.lerp(p.canvas, primary, 0.20)!
        : const Color(0xFF0B1B36);
    final bottomColor = isDark
        ? p.canvas
        : Color.lerp(const Color(0xFF0B1B36), primary, 0.28)!;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [topColor, bottomColor],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 3D floating & gently tilting Velora emblem
                  AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, child) {
                      final wave = math.sin(_ctrl.value * 2 * math.pi);
                      final wave2 = math.cos(_ctrl.value * 2 * math.pi);
                      final matrix = Matrix4.identity()
                        ..setEntry(3, 2, 0.0018)
                        ..rotateY(wave * 0.12)
                        ..rotateX(wave2 * 0.07);
                      return Transform.translate(
                        offset: Offset(0, wave * -5),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: matrix,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 96,
                      height: 96,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.30),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const VeloraLogo(
                        size: 64,
                        withGlow: false,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 420.ms)
                      .scale(
                        begin: const Offset(0.84, 0.84),
                        end: const Offset(1, 1),
                        duration: 480.ms,
                        curve: Curves.easeOutBack,
                      ),
                  const SizedBox(height: 22),
                  Text(
                    config.appName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  )
                      .animate(delay: 100.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.16, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 6),
                  Text(
                    'Kelola bisnis lebih cepat, cerdas & terintegrasi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                      .animate(delay: 180.ms)
                      .fadeIn(duration: 400.ms),
                  const SizedBox(height: 44),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: AnimatedBuilder(
                      animation: _ctrl,
                      builder: (_, _) => CustomPaint(
                        painter: _SplashOrbitLoaderPainter(
                          angle: _ctrl.value * 2 * math.pi,
                        ),
                      ),
                    ),
                  ),
                  if (widget.message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      widget.message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashOrbitLoaderPainter extends CustomPainter {
  const _SplashOrbitLoaderPainter({required this.angle});

  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4;
    const dots = 6;

    for (var i = 0; i < dots; i++) {
      final t = i / (dots - 1);
      final a = angle - (i * 0.45);
      final dx = center.dx + radius * math.cos(a);
      final dy = center.dy + radius * math.sin(a);
      canvas.drawCircle(
        Offset(dx, dy),
        3.2 * (1 - t * 0.6),
        Paint()..color = Colors.white.withValues(alpha: (1 - t * 0.8).clamp(0.15, 0.95)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SplashOrbitLoaderPainter oldDelegate) =>
      oldDelegate.angle != angle;
}
