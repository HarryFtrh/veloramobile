import 'package:flutter/material.dart';
import 'tokens.dart';

/// Grafik garis sederhana untuk tren harian. Tanpa dependency eksternal.
class TrendChart extends StatelessWidget {
  const TrendChart({super.key, required this.values, this.height = 140});

  final List<double> values;
  final double height;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final p = context.palette;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _TrendPainter(values: values, line: accent, grid: p.line),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({required this.values, required this.line, required this.grid});

  final List<double> values;
  final Color line;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    if (values.length < 2) return;

    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = maxV <= 0 ? 1.0 : maxV;
    const inset = 4.0;
    final h = size.height - inset * 2;

    Offset pointAt(int i) => Offset(
          size.width * i / (values.length - 1),
          inset + h * (1 - values[i] / range),
        );

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(pointAt(i).dx, pointAt(i).dy);
    }

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = line.withValues(alpha: 0.08));

    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.values != values || old.line != line || old.grid != grid;
}
