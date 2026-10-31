import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class VeloraLogo extends StatelessWidget {
  final double size;
  final Color? color;
  final bool withGlow;
  final bool useHeroImage;
  final double borderRadius;

  const VeloraLogo({
    super.key,
    this.size = 48,
    this.color,
    this.withGlow = false,
    this.useHeroImage = true,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (useHeroImage) {
      final imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          'assets/images/velora-hero.jpeg',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );

      if (!withGlow) {
        return imageWidget;
      }

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
              blurRadius: size * 0.3,
              spreadRadius: 2,
            ),
          ],
        ),
        child: imageWidget,
      );
    }

    final logoWidget = SvgPicture.asset(
      'assets/images/velora_logo.svg',
      width: size,
      height: size,
      colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
    );

    if (!withGlow) {
      return logoWidget;
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (color ?? const Color(0xFF14B8A6)).withValues(alpha: 0.35),
            blurRadius: size * 0.4,
            spreadRadius: 2,
          ),
        ],
      ),
      child: logoWidget,
    );
  }
}

class GoogleLogo extends StatelessWidget {
  final double size;
  const GoogleLogo({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;
    final strokeWidth = w * 0.22;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Blue arc (bottom right to right)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.785, 1.57, false, paint);

    // Green arc (bottom)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.785, 1.57, false, paint);

    // Yellow arc (left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.356, 1.57, false, paint);

    // Red arc (top)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.927, 1.57, false, paint);

    // Blue horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final barRect = Rect.fromLTWH(w * 0.45, (h - strokeWidth) / 2, w * 0.55, strokeWidth);
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
