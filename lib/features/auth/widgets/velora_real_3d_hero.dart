import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../core/design/tokens.dart';

/// True real-time 3D interactive hero stage rendered with 3D vertices,
/// rotation matrices, perspective projection, painter's Z-depth sorting,
/// and directional Lambert shading.
///
/// Users can drag with their finger to orbit and tilt the 3D POS terminal
/// and floating contactless card in real 3D space.
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

  // Interactive user orbit offsets (radians)
  double _userYaw = 0.0;
  double _userPitch = 0.0;
  double _velYaw = 0.0;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    if (!widget.paused) {
      _ctrl.repeat();
    }
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
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) {
          _dragging = true;
          _velYaw = 0;
        },
        onPanUpdate: (details) {
          setState(() {
            _userYaw += details.delta.dx * 0.012;
            _userPitch = (_userPitch + details.delta.dy * 0.008).clamp(-0.48, 0.48);
          });
        },
        onPanEnd: (details) {
          _dragging = false;
          _velYaw = (details.velocity.pixelsPerSecond.dx * 0.00004).clamp(-0.04, 0.04);
        },
        onPanCancel: () => _dragging = false,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, _) {
            if (!_dragging) {
              if (_velYaw.abs() > 0.0002) {
                _userYaw += _velYaw;
                _velYaw *= 0.94;
              }
              // Gently ease pitch back toward neutral showcase angle
              _userPitch *= 0.985;
            }

            final t = _ctrl.value * 2 * math.pi;
            final autoYaw = math.sin(t) * 0.36;
            final autoPitch = -0.18 + math.cos(t * 2) * 0.05;
            final bobY = math.sin(t * 2) * 0.08;

            return CustomPaint(
              painter: _Velora3DScenePainter(
                time: t,
                yaw: autoYaw + _userYaw,
                pitch: autoPitch + _userPitch,
                bobY: bobY,
                primaryColor: widget.primaryColor,
                isDark: isDark,
                canvasColor: p.canvas,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _Vec3 {
  const _Vec3(this.x, this.y, this.z);
  final double x;
  final double y;
  final double z;

  _Vec3 operator +(_Vec3 o) => _Vec3(x + o.x, y + o.y, z + o.z);
  _Vec3 operator -(_Vec3 o) => _Vec3(x - o.x, y - o.y, z - o.z);
  _Vec3 operator *(double s) => _Vec3(x * s, y * s, z * s);

  double dot(_Vec3 o) => x * o.x + y * o.y + z * o.z;

  _Vec3 cross(_Vec3 o) => _Vec3(
        y * o.z - z * o.y,
        z * o.x - x * o.z,
        x * o.y - y * o.x,
      );

  _Vec3 normalized() {
    final len = math.sqrt(x * x + y * y + z * z);
    if (len < 1e-6) return const _Vec3(0, 0, 1);
    return _Vec3(x / len, y / len, z / len);
  }

  _Vec3 rotateX(double a) {
    final c = math.cos(a);
    final s = math.sin(a);
    return _Vec3(x, y * c - z * s, y * s + z * c);
  }

  _Vec3 rotateY(double a) {
    final c = math.cos(a);
    final s = math.sin(a);
    return _Vec3(x * c + z * s, y, -x * s + z * c);
  }

  _Vec3 rotateZ(double a) {
    final c = math.cos(a);
    final s = math.sin(a);
    return _Vec3(x * c - y * s, x * s + y * c, z);
  }
}

class _Face3D {
  const _Face3D({
    required this.points,
    required this.depth,
    required this.fillColor,
    this.strokeColor,
    this.isScreenFace = false,
    this.isCardFront = false,
    this.isReceiptFace = false,
  });

  final List<Offset> points;
  final double depth;
  final Color fillColor;
  final Color? strokeColor;
  final bool isScreenFace;
  final bool isCardFront;
  final bool isReceiptFace;
}

class _Velora3DScenePainter extends CustomPainter {
  const _Velora3DScenePainter({
    required this.time,
    required this.yaw,
    required this.pitch,
    required this.bobY,
    required this.primaryColor,
    required this.isDark,
    required this.canvasColor,
  });

  final double time;
  final double yaw;
  final double pitch;
  final double bobY;
  final Color primaryColor;
  final bool isDark;
  final Color canvasColor;

  static const _lightDir = _Vec3(-0.45, -0.72, -0.52);
  static const _teal = Color(0xFF14B8A6);
  static const _gold = Color(0xFFF59E0B);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.56;
    final scale = math.min(size.width, size.height) * 0.44;
    const cameraDist = 5.4;

    // 1. Studio atmospheric gradient backdrop
    final bgTop = isDark
        ? Color.lerp(const Color(0xFF101218), primaryColor, 0.16)!
        : Color.lerp(const Color(0xFFF5F3EF), primaryColor, 0.08)!;
    final bgBottom = isDark
        ? Color.lerp(const Color(0xFF181A22), primaryColor, 0.08)!
        : Color.lerp(const Color(0xFFEBE6DF), primaryColor, 0.04)!;

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgTop, bgBottom],
        ).createShader(Offset.zero & size),
    );

    // Soft studio radial halo behind the 3D terminal
    canvas.drawCircle(
      Offset(cx, cy - 6),
      scale * 1.45,
      Paint()
        ..shader = RadialGradient(
          colors: [
            primaryColor.withValues(alpha: isDark ? 0.24 : 0.14),
            _teal.withValues(alpha: isDark ? 0.10 : 0.06),
            Colors.transparent,
          ],
          stops: const [0.0, 0.52, 1.0],
        ).createShader(
          Rect.fromCircle(center: Offset(cx, cy - 6), radius: scale * 1.45),
        ),
    );

    // Subtle 3D perspective floor arcs & soft contact shadow
    final shadowScale = 1.0 - (bobY * 0.7);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + scale * 0.64),
        width: scale * 1.35 * shadowScale,
        height: scale * 0.30 * shadowScale,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: isDark ? 0.42 : 0.11)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // Helper: project world 3D point -> 2D screen Offset
    Offset project(_Vec3 v) {
      final f = cameraDist / (cameraDist + v.z);
      return Offset(cx + v.x * scale * f, cy + v.y * scale * f);
    }

    _Vec3 toWorld(_Vec3 local) {
      return local.rotateY(yaw).rotateX(pitch) + _Vec3(0, bobY, 0);
    }

    final faces = <_Face3D>[];
    final lightNorm = _lightDir.normalized();

    void addBox({
      required _Vec3 center,
      required _Vec3 halfSize,
      required Color baseColor,
      double localTiltX = 0,
      double localRotY = 0,
      double localRotZ = 0,
      Color? frontColor,
      bool frontIsScreen = false,
      bool frontIsCard = false,
      bool frontIsReceipt = false,
    }) {
      final hx = halfSize.x;
      final hy = halfSize.y;
      final hz = halfSize.z;

      final rawVerts = [
        _Vec3(-hx, -hy, -hz), // 0: front-top-left
        _Vec3(hx, -hy, -hz),  // 1: front-top-right
        _Vec3(hx, hy, -hz),   // 2: front-bottom-right
        _Vec3(-hx, hy, -hz),  // 3: front-bottom-left
        _Vec3(-hx, -hy, hz),  // 4: back-top-left
        _Vec3(hx, -hy, hz),   // 5: back-top-right
        _Vec3(hx, hy, hz),    // 6: back-bottom-right
        _Vec3(-hx, hy, hz),   // 7: back-bottom-left
      ];

      final worldVerts = rawVerts.map((v) {
        var r = v;
        if (localTiltX != 0) r = r.rotateX(localTiltX);
        if (localRotY != 0) r = r.rotateY(localRotY);
        if (localRotZ != 0) r = r.rotateZ(localRotZ);
        return toWorld(r + center);
      }).toList();

      // 6 faces (clockwise winding when viewed from outside)
      const faceIndices = [
        [0, 1, 2, 3], // front (-z)
        [5, 4, 7, 6], // back (+z)
        [4, 0, 3, 7], // left (-x)
        [1, 5, 6, 2], // right (+x)
        [4, 5, 1, 0], // top (-y)
        [3, 2, 6, 7], // bottom (+y)
      ];

      for (var fi = 0; fi < faceIndices.length; fi++) {
        final idx = faceIndices[fi];
        final v0 = worldVerts[idx[0]];
        final v1 = worldVerts[idx[1]];
        final v2 = worldVerts[idx[2]];
        final v3 = worldVerts[idx[3]];

        final edge1 = v1 - v0;
        final edge2 = v2 - v0;
        final normal = edge1.cross(edge2).normalized();

        // Backface culling (camera sits at (0, 0, -cameraDist) looking toward +z)
        final viewDir = _Vec3(
          (v0.x + v2.x) * 0.5,
          (v0.y + v2.y) * 0.5,
          (v0.z + v2.z) * 0.5 + cameraDist,
        ).normalized();
        if (normal.dot(viewDir) >= 0.02) continue;

        final diffuse = (-normal.dot(lightNorm)).clamp(0.0, 1.0);
        final shade = 0.64 + diffuse * 0.42;

        final c = (fi == 0 && frontColor != null) ? frontColor : baseColor;
        final shaded = _shadeColor(c, shade);
        final avgZ = (v0.z + v1.z + v2.z + v3.z) * 0.25;

        faces.add(
          _Face3D(
            points: [project(v0), project(v1), project(v2), project(v3)],
            depth: avgZ,
            fillColor: shaded,
            strokeColor: Colors.white.withValues(alpha: isDark ? 0.10 : 0.28),
            isScreenFace: fi == 0 && frontIsScreen,
            isCardFront: fi == 0 && frontIsCard,
            isReceiptFace: fi == 0 && frontIsReceipt,
          ),
        );
      }
    }

    void addOctahedron({
      required _Vec3 center,
      required double radius,
      required Color color,
      required double spin,
    }) {
      final raw = [
        _Vec3(0, -radius, 0),
        _Vec3(radius, 0, 0),
        _Vec3(0, 0, -radius),
        _Vec3(-radius, 0, 0),
        _Vec3(0, 0, radius),
        _Vec3(0, radius, 0),
      ];
      final wv = raw
          .map((v) => toWorld(v.rotateY(spin).rotateX(spin * 0.6) + center))
          .toList();

      const tris = [
        [0, 1, 2],
        [0, 2, 3],
        [0, 3, 4],
        [0, 4, 1],
        [5, 2, 1],
        [5, 3, 2],
        [5, 4, 3],
        [5, 1, 4],
      ];

      for (final tIdx in tris) {
        final v0 = wv[tIdx[0]];
        final v1 = wv[tIdx[1]];
        final v2 = wv[tIdx[2]];
        final normal = (v1 - v0).cross(v2 - v0).normalized();
        final viewDir = _Vec3(
          (v0.x + v1.x + v2.x) / 3,
          (v0.y + v1.y + v2.y) / 3,
          (v0.z + v1.z + v2.z) / 3 + cameraDist,
        ).normalized();
        if (normal.dot(viewDir) >= 0.02) continue;

        final diffuse = (-normal.dot(lightNorm)).clamp(0.0, 1.0);
        final shaded = _shadeColor(color, 0.62 + diffuse * 0.50);
        faces.add(
          _Face3D(
            points: [project(v0), project(v1), project(v2)],
            depth: (v0.z + v1.z + v2.z) / 3,
            fillColor: shaded,
            strokeColor: Colors.white.withValues(alpha: 0.24),
          ),
        );
      }
    }

    // --- 2. Build 3D Velora POS Terminal ---
    final bodyColor = isDark ? const Color(0xFF282B36) : const Color(0xFF1F2430);
    final standColor = isDark ? const Color(0xFF363A48) : const Color(0xFFD5D9E2);
    final screenColor = isDark ? const Color(0xFF141822) : const Color(0xFFFFFFFF);

    // Base stand plate
    addBox(
      center: const _Vec3(0, 0.44, 0.08),
      halfSize: const _Vec3(0.46, 0.06, 0.34),
      baseColor: standColor,
    );

    // Neck pillar
    addBox(
      center: const _Vec3(0, 0.25, 0.14),
      halfSize: const _Vec3(0.14, 0.18, 0.12),
      baseColor: standColor,
      localTiltX: 0.18,
    );

    // Main 3D POS Display Body (tilted ergonomically)
    addBox(
      center: const _Vec3(0, -0.04, 0.0),
      halfSize: const _Vec3(0.66, 0.42, 0.075),
      baseColor: bodyColor,
      frontColor: screenColor,
      localTiltX: -0.22,
      frontIsScreen: true,
    );

    // Mini 3D Thermal Receipt emerging from top-right of terminal
    addBox(
      center: const _Vec3(0.32, -0.52, 0.06),
      halfSize: const _Vec3(0.18, 0.16, 0.012),
      baseColor: const Color(0xFFFAFAFA),
      frontColor: const Color(0xFFFFFFFF),
      localTiltX: -0.15,
      localRotZ: 0.06,
      frontIsReceipt: true,
    );

    // --- 3. Orbiting 3D Contactless Payment Card ---
    final orbitAngle = time;
    final cardX = math.cos(orbitAngle) * 1.08;
    final cardZ = math.sin(orbitAngle) * 0.72;
    final cardY = -0.06 + math.sin(orbitAngle * 2) * 0.10;

    addBox(
      center: _Vec3(cardX, cardY, cardZ),
      halfSize: const _Vec3(0.30, 0.19, 0.018),
      baseColor: Color.lerp(primaryColor, Colors.black, 0.18)!,
      frontColor: primaryColor,
      localRotY: -orbitAngle + 0.4,
      localRotZ: -0.14,
      frontIsCard: true,
    );

    // --- 4. Orbiting 3D Faceted Gems (Brand Teal & Accent) ---
    addOctahedron(
      center: _Vec3(
        math.cos(time + 2.4) * 1.16,
        -0.38 + math.sin(time * 2) * 0.08,
        math.sin(time + 2.4) * 0.65,
      ),
      radius: 0.12,
      color: _teal,
      spin: time * 1.6,
    );
    addOctahedron(
      center: _Vec3(
        math.cos(time + 4.5) * 0.96,
        0.24 + math.cos(time * 2) * 0.07,
        math.sin(time + 4.5) * 0.62,
      ),
      radius: 0.09,
      color: _gold,
      spin: -time * 1.8,
    );

    // --- 5. Painter's Algorithm Depth Sort (back-to-front) ---
    faces.sort((a, b) => b.depth.compareTo(a.depth));

    for (final face in faces) {
      final path = Path()..addPolygon(face.points, true);
      canvas.drawPath(path, Paint()..color = face.fillColor);

      if (face.strokeColor != null) {
        canvas.drawPath(
          path,
          Paint()
            ..color = face.strokeColor!
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.85
            ..strokeJoin = StrokeJoin.round,
        );
      }

      // Draw crisp UI details projected onto the 3D front screen face
      if (face.isScreenFace && face.points.length == 4) {
        _paintScreenDetails(canvas, face.points);
      } else if (face.isCardFront && face.points.length == 4) {
        _paintCardDetails(canvas, face.points);
      } else if (face.isReceiptFace && face.points.length == 4) {
        _paintReceiptDetails(canvas, face.points);
      }
    }
  }

  /// Bilinear interpolation on a 3D projected quad (u, v in 0..1)
  Offset _quadPoint(List<Offset> q, double u, double v) {
    final top = Offset.lerp(q[0], q[1], u)!;
    final bottom = Offset.lerp(q[3], q[2], u)!;
    return Offset.lerp(top, bottom, v)!;
  }

  void _drawQuadRect(
    Canvas canvas,
    List<Offset> q,
    double u0,
    double v0,
    double u1,
    double v1,
    Color color,
  ) {
    final p = Path()
      ..moveTo(_quadPoint(q, u0, v0).dx, _quadPoint(q, u0, v0).dy)
      ..lineTo(_quadPoint(q, u1, v0).dx, _quadPoint(q, u1, v0).dy)
      ..lineTo(_quadPoint(q, u1, v1).dx, _quadPoint(q, u1, v1).dy)
      ..lineTo(_quadPoint(q, u0, v1).dx, _quadPoint(q, u0, v1).dy)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  void _paintScreenDetails(Canvas canvas, List<Offset> q) {
    // Inner dark bezel + UI header bar
    _drawQuadRect(canvas, q, 0.06, 0.09, 0.94, 0.24, primaryColor.withValues(alpha: 0.90));
    // Left catalog tiles (2x2 grid)
    final tileColor = isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE9ECEF);
    _drawQuadRect(canvas, q, 0.08, 0.30, 0.34, 0.56, tileColor);
    _drawQuadRect(canvas, q, 0.38, 0.30, 0.64, 0.56, _teal.withValues(alpha: 0.24));
    _drawQuadRect(canvas, q, 0.08, 0.62, 0.34, 0.88, primaryColor.withValues(alpha: 0.18));
    _drawQuadRect(canvas, q, 0.38, 0.62, 0.64, 0.88, tileColor);
    // Right cart summary panel + pay button
    _drawQuadRect(canvas, q, 0.69, 0.30, 0.92, 0.68, tileColor);
    _drawQuadRect(canvas, q, 0.69, 0.74, 0.92, 0.88, _teal);
  }

  void _paintCardDetails(Canvas canvas, List<Offset> q) {
    // Gold EMV chip
    _drawQuadRect(canvas, q, 0.14, 0.36, 0.34, 0.60, _gold.withValues(alpha: 0.92));
    // Card number lines
    _drawQuadRect(canvas, q, 0.14, 0.72, 0.78, 0.81, Colors.white.withValues(alpha: 0.70));
  }

  void _paintReceiptDetails(Canvas canvas, List<Offset> q) {
    final ink = Colors.black.withValues(alpha: 0.20);
    _drawQuadRect(canvas, q, 0.18, 0.22, 0.82, 0.30, ink);
    _drawQuadRect(canvas, q, 0.18, 0.42, 0.68, 0.49, ink);
    _drawQuadRect(canvas, q, 0.18, 0.60, 0.76, 0.67, ink);
    _drawQuadRect(canvas, q, 0.18, 0.78, 0.55, 0.86, _teal.withValues(alpha: 0.65));
  }

  Color _shadeColor(Color c, double factor) {
    final r = (c.r * 255.0 * factor).clamp(0.0, 255.0).round();
    final g = (c.g * 255.0 * factor).clamp(0.0, 255.0).round();
    final b = (c.b * 255.0 * factor).clamp(0.0, 255.0).round();
    return Color.fromARGB((c.a * 255.0).round(), r, g, b);
  }

  @override
  bool shouldRepaint(covariant _Velora3DScenePainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.yaw != yaw ||
      oldDelegate.pitch != pitch ||
      oldDelegate.bobY != bobY ||
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.isDark != isDark;
}
