import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';

import '../design/tokens.dart';

/// Animated skeuomorphic thermal printer slot with glowing green status LED,
/// sliding receipt paper with a serrated zig-zag bottom edge, and an animated
/// circular "LUNAS" stamp bounce.
class VeloraThermalReceiptCard extends StatelessWidget {
  const VeloraThermalReceiptCard({
    super.key,
    required this.child,
    this.stampText = 'LUNAS',
    this.showStamp = true,
  });

  final Widget child;
  final String stampText;
  final bool showStamp;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slotBg = isDark ? const Color(0xFF0F0D0C) : const Color(0xFF1E293B);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Metallic Printer Slot Bar with Glowing Green LED
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: slotBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.75),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fade(begin: 0.55, end: 1.0, duration: 900.ms),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'PRINT',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),

        // 2. Sliding Receipt Paper with Serrated Zig-Zag Bottom + "LUNAS" Stamp
        Transform.translate(
          offset: const Offset(0, -10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ClipRect(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipPath(
                    clipper: _SerratedReceiptClipper(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 18, 14, 24),
                      decoration: BoxDecoration(
                        color: p.surface,
                        border: Border(
                          left: BorderSide(color: p.line),
                          right: BorderSide(color: p.line),
                        ),
                      ),
                      child: child,
                    ),
                  ),

                  // Animated circular "LUNAS" rubber stamp
                  if (showStamp)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Transform.rotate(
                        angle: -0.22,
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: p.success.withValues(alpha: 0.10),
                            border: Border.all(
                              color: p.success.withValues(alpha: 0.78),
                              width: 2.2,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: p.success.withValues(alpha: 0.45),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  stampText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                    color: p.success,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                          .animate(delay: 360.ms)
                          .fadeIn(duration: 180.ms)
                          .scale(
                            begin: const Offset(1.75, 1.75),
                            end: const Offset(1.0, 1.0),
                            duration: 340.ms,
                            curve: Curves.elasticOut,
                          ),
                    ),
                ],
              )
                  .animate()
                  .slideY(
                    begin: -0.32,
                    end: 0,
                    duration: 520.ms,
                    curve: Curves.easeOutCubic,
                  )
                  .fadeIn(duration: 300.ms),
            ),
          ),
        ),
      ],
    );
  }
}

class _SerratedReceiptClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const toothWidth = 10.0;
    const toothHeight = 6.0;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - toothHeight);

    var x = size.width;
    var up = true;
    while (x > 0) {
      final nextX = (x - toothWidth / 2).clamp(0.0, size.width);
      path.lineTo(nextX, up ? size.height : size.height - toothHeight);
      x = nextX;
      up = !up;
    }

    path
      ..lineTo(0, size.height - toothHeight)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
