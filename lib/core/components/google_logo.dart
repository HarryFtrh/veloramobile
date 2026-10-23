import 'package:flutter/material.dart';

class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 20});

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
    final stroke = w * 0.22;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: center, radius: radius - stroke / 2);

    // Red (Top: ~225° to 315°)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.4, 1.6, false, paint);

    // Yellow (Bottom Left: ~135° to 225°)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.35, 1.55, false, paint);

    // Green (Bottom Right: ~45° to 135°)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.78, 1.57, false, paint);

    // Blue (Right arc: ~ -45° to 45°)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.78, 1.56, false, paint);

    // Blue horizontal crossbar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.45, h * 0.5 - stroke * 0.45, w * 0.55, stroke * 0.9),
        Radius.circular(stroke * 0.15),
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
