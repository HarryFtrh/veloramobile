import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// High-craft studio 3D artwork showcase with smooth interactive finger-tilt
/// perspective, glossy light sheen, and gentle breathing depth motion.
class VeloraReal3DHero extends StatefulWidget {
  const VeloraReal3DHero({
    super.key,
    required this.primaryColor,
    this.paused = false,
  });

  final Color primaryColor;
  final bool paused;

  @override
  State<VeloraReal3DHero> createState() => _VeloraReal3DHeroState();
}

class _VeloraReal3DHeroState extends State<VeloraReal3DHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    if (!widget.paused) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(covariant VeloraReal3DHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paused && _ctrl.isAnimating) {
      _ctrl.stop();
    } else if (!widget.paused && !_ctrl.isAnimating) {
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => _dragging = true,
        onPanUpdate: (details) {
          setState(() {
            _tiltY = (_tiltY + details.delta.dx * 0.0022).clamp(-0.14, 0.14);
            _tiltX = (_tiltX - details.delta.dy * 0.0022).clamp(-0.10, 0.10);
          });
        },
        onPanEnd: (_) => _dragging = false,
        onPanCancel: () => _dragging = false,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) {
            if (!_dragging) {
              _tiltX *= 0.92;
              _tiltY *= 0.92;
            }
            final t = _ctrl.value * 2 * math.pi;
            final dx = math.sin(t) * 6.0 - (_tiltY * 42.0);
            final dy = math.cos(t) * 3.5 + (_tiltX * 36.0);
            final scale = 1.08 + (math.sin(t) * 0.022);
            final rx = (math.cos(t) * 0.025) + _tiltX;
            final ry = (math.sin(t) * 0.038) + _tiltY;

            final matrix = Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(ry)
              ..rotateX(rx);

            return Stack(
              fit: StackFit.expand,
              children: [
                Transform.translate(
                  offset: Offset(dx, dy),
                  child: Transform.scale(
                    scale: scale,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: matrix,
                      child: child,
                    ),
                  ),
                ),
                // Dynamic subtle studio specular sheen reacting to 3D tilt
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(
                          (math.sin(t) * 0.45) - (_tiltY * 3.2),
                          -0.35 + (_tiltX * 2.4),
                        ),
                        radius: 1.05,
                        colors: [
                          Colors.white.withValues(alpha: 0.14),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          child: Image.asset(
            'assets/images/velora_login_hero.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }
}
