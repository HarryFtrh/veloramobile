import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/components.dart';
import '../../../core/design/tokens.dart';

/// Full-screen frosted-glass loading & success overlay inspired by modern flight-app
/// login transitions: Gaussian backdrop blur + clockwise-orbiting Velora dot-arc spinner.
class VeloraLoginOverlay extends StatefulWidget {
  const VeloraLoginOverlay({
    super.key,
    required this.visible,
    required this.isSuccess,
    required this.accentColor,
    required this.title,
    required this.subtitle,
  });

  final bool visible;
  final bool isSuccess;
  final Color accentColor;
  final String title;
  final String subtitle;

  @override
  State<VeloraLoginOverlay> createState() => _VeloraLoginOverlayState();
}

class _VeloraLoginOverlayState extends State<VeloraLoginOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbitCtrl;

  @override
  void initState() {
    super.initState();
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.visible && !widget.isSuccess) {
      _orbitCtrl.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant VeloraLoginOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !widget.isSuccess) {
      if (!_orbitCtrl.isAnimating) _orbitCtrl.repeat();
    } else {
      if (_orbitCtrl.isAnimating) _orbitCtrl.stop();
    }
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      ignoring: !widget.visible,
      child: AnimatedOpacity(
        opacity: widget.visible ? 1 : 0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        child: widget.visible
            ? Stack(
                fit: StackFit.expand,
                children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      color: (isDark ? p.canvas : Colors.white).withValues(alpha: isDark ? 0.72 : 0.74),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeOutBack,
                            child: widget.isSuccess
                                ? Container(
                                    key: const ValueKey('overlay_success'),
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: p.success.withValues(alpha: 0.16),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: p.success.withValues(alpha: 0.45),
                                        width: 1.8,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.check_rounded,
                                      color: p.success,
                                      size: 38,
                                    ),
                                  )
                                    .animate()
                                    .scale(
                                      begin: const Offset(0.7, 0.7),
                                      end: const Offset(1, 1),
                                      duration: 320.ms,
                                      curve: Curves.easeOutBack,
                                    )
                                : SizedBox(
                                    key: const ValueKey('overlay_orbit'),
                                    width: 96,
                                    height: 96,
                                    child: AnimatedBuilder(
                                      animation: _orbitCtrl,
                                      builder: (_, child) {
                                        final angle = _orbitCtrl.value * 2 * math.pi;
                                        return Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            CustomPaint(
                                              size: const Size(96, 96),
                                              painter: _OrbitDotArcPainter(
                                                angle: angle,
                                                color: widget.accentColor,
                                              ),
                                            ),
                                            child!,
                                          ],
                                        );
                                      },
                                      child: const VeloraLogo(
                                        size: 40,
                                        borderRadius: 12,
                                        withGlow: false,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: p.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: p.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _OrbitDotArcPainter extends CustomPainter {
  const _OrbitDotArcPainter({
    required this.angle,
    required this.color,
  });

  final double angle;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 8;
    const dotCount = 8;

    // Draw subtle orbit guide ring
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, radius, ringPaint);

    // Draw trailing graduating dots behind the leading spark
    for (var i = 0; i < dotCount; i++) {
      final t = i / (dotCount - 1); // 0 = head, 1 = tail
      final dotAngle = angle - (i * 0.34);
      final dx = center.dx + radius * math.cos(dotAngle);
      final dy = center.dy + radius * math.sin(dotAngle);
      final dotRadius = 4.6 * (1 - t * 0.65);
      final opacity = (1 - t * 0.82).clamp(0.12, 1.0);

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(dx, dy), dotRadius, paint);
    }

    // Soft glow on the leading dot
    final headX = center.dx + radius * math.cos(angle);
    final headY = center.dy + radius * math.sin(angle);
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(headX, headY), 9, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _OrbitDotArcPainter oldDelegate) =>
      oldDelegate.angle != angle || oldDelegate.color != color;
}
