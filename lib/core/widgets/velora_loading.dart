import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';

import '../components/velora_logo.dart';
import '../design/tokens.dart';

/// Signature Velora clockwise-orbiting dot-arc loader with optional center
/// [VeloraLogo] emblem. Wrapped in [RepaintBoundary] for 60fps performance.
///
/// Use:
/// - `const VeloraOrbitLoader()` or `VeloraOrbitLoader.page(label: 'Memuat...')`
///   for page, tab, or modal loading states.
/// - `const VeloraOrbitLoader.inline(size: 18, color: Colors.white)`
///   for buttons, badges, and pagination footers.
class VeloraOrbitLoader extends StatefulWidget {
  const VeloraOrbitLoader({
    super.key,
    this.size = 84,
    this.color,
    this.showLogo = true,
    this.label,
    this.subtitle,
  });

  /// Compact orbiting dots without the center logo (ideal for buttons & list footers).
  const VeloraOrbitLoader.inline({
    super.key,
    this.size = 20,
    this.color,
  })  : showLogo = false,
        label = null,
        subtitle = null;

  /// Centered full-area page/modal loading state with the Velora emblem.
  static Widget page({
    Key? key,
    double size = 84,
    Color? color,
    String? label,
    String? subtitle,
  }) {
    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: VeloraOrbitLoader(
          size: size,
          color: color,
          showLogo: true,
          label: label,
          subtitle: subtitle,
        ),
      ),
    );
  }

  final double size;
  final Color? color;
  final bool showLogo;
  final String? label;
  final String? subtitle;

  @override
  State<VeloraOrbitLoader> createState() => _VeloraOrbitLoaderState();
}

class _VeloraOrbitLoaderState extends State<VeloraOrbitLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final accent = widget.color ?? Theme.of(context).colorScheme.primary;
    final renderLogo = widget.showLogo && widget.size >= 44;
    final logoSize = (widget.size * 0.42).clamp(20.0, 44.0);

    final spinner = RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) {
            final angle = _ctrl.value * 2 * math.pi;
            return Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size.square(widget.size),
                  painter: _VeloraOrbitArcPainter(
                    angle: angle,
                    color: accent,
                    compact: !renderLogo,
                  ),
                ),
                ?child,
              ],
            );
          },
          child: renderLogo
              ? VeloraLogo(
                  size: logoSize,
                  borderRadius: (logoSize * 0.3).clamp(6.0, 14.0),
                  withGlow: false,
                )
              : null,
        ),
      ),
    );

    if (widget.label == null && widget.subtitle == null) {
      return spinner;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        spinner,
        if (widget.label != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.label!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ],
        if (widget.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: p.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Full-screen frosted-glass loading & success overlay featuring the Velora
/// clockwise-orbiting dot-arc spinner. Reusable for login, checkout, sync, or
/// any blocking async operation.
class VeloraLoadingOverlay extends StatelessWidget {
  const VeloraLoadingOverlay({
    super.key,
    required this.visible,
    this.isSuccess = false,
    this.accentColor,
    required this.title,
    this.subtitle = '',
  });

  final bool visible;
  final bool isSuccess;
  final Color? accentColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? Theme.of(context).colorScheme.primary;

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        child: visible
            ? Stack(
                fit: StackFit.expand,
                children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      color: (isDark ? p.canvas : Colors.white)
                          .withValues(alpha: isDark ? 0.78 : 0.80),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            switchInCurve: Curves.easeOutBack,
                            child: isSuccess
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
                                : VeloraOrbitLoader(
                                    key: const ValueKey('overlay_orbit'),
                                    size: 96,
                                    color: color,
                                  ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: p.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: p.textSecondary,
                              ),
                            ),
                          ],
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

class _VeloraOrbitArcPainter extends CustomPainter {
  const _VeloraOrbitArcPainter({
    required this.angle,
    required this.color,
    required this.compact,
  });

  final double angle;
  final Color color;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final inset = compact ? (size.width * 0.14).clamp(2.2, 5.0) : 8.0;
    final radius = (size.width / 2) - inset;
    final dotCount = compact ? 6 : 8;
    final maxDotRadius = compact
        ? (size.width * 0.11).clamp(1.6, 3.4)
        : (size.width * 0.048).clamp(3.0, 4.8);

    // Subtle orbit guide ring
    final ringPaint = Paint()
      ..color = color.withValues(alpha: compact ? 0.16 : 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 1.0 : 1.4;
    canvas.drawCircle(center, radius, ringPaint);

    // Trailing graduating dots behind the leading spark
    for (var i = 0; i < dotCount; i++) {
      final t = i / (dotCount - 1);
      final dotAngle = angle - (i * (compact ? 0.44 : 0.34));
      final dx = center.dx + radius * math.cos(dotAngle);
      final dy = center.dy + radius * math.sin(dotAngle);
      final dotRadius = maxDotRadius * (1 - t * 0.65);
      final opacity = (1 - t * 0.82).clamp(0.14, 1.0);

      canvas.drawCircle(
        Offset(dx, dy),
        dotRadius,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.fill,
      );
    }

    // Soft glow on the leading dot (full-size mode)
    if (!compact) {
      final headX = center.dx + radius * math.cos(angle);
      final headY = center.dy + radius * math.sin(angle);
      canvas.drawCircle(
        Offset(headX, headY),
        maxDotRadius * 1.9,
        Paint()
          ..color = color.withValues(alpha: 0.26)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VeloraOrbitArcPainter oldDelegate) =>
      oldDelegate.angle != angle ||
      oldDelegate.color != color ||
      oldDelegate.compact != compact;
}
