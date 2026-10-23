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
