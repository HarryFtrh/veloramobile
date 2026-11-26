import 'package:material_ui/material_ui.dart';

import '../design/tokens.dart';
import '../utils/audio_helper.dart';

class VeloraFloatingNavItem {
  const VeloraFloatingNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.badgeCount = 0,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int badgeCount;
}

/// Reusable Floating Pill Bottom Navigation Bar with a smooth 60fps sliding
/// active indicator, concentric radii, and zero-jank rendering across all
/// Velora business verticals (F&B, Retail, Pharmacy, Marketplace, Sales).
class VeloraFloatingNavBar extends StatelessWidget {
  const VeloraFloatingNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.useMonoLabels = false,
  });

  final List<VeloraFloatingNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool useMonoLabels;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = Theme.of(context).colorScheme.primary;
    final inactiveColor = p.textSecondary;
    final safeIndex = currentIndex.clamp(0, items.length - 1);
    final alignX = items.length <= 1
        ? 0.0
        : -1.0 + (2.0 * safeIndex / (items.length - 1));

    const double outerRadius = 31;
    const double innerPadding = 5;
    const double pillRadius = outerRadius - innerPadding; // Concentric: 26

    return RepaintBoundary(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Container(
            height: 62,
            padding: const EdgeInsets.all(innerPadding),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(outerRadius),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : p.line.withValues(alpha: 0.65),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.08),
                  blurRadius: 24,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Smoothly gliding active pill indicator (easeOutQuint spring-like deceleration)
                AnimatedAlign(
                  alignment: Alignment(alignX, 0),
                  duration: const Duration(milliseconds: 340),
                  curve: Curves.easeOutQuint,
                  child: FractionallySizedBox(
                    widthFactor: 1 / items.length,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: activeColor.withValues(
                          alpha: isDark ? 0.24 : 0.13,
                        ),
                        borderRadius: BorderRadius.circular(pillRadius),
                        border: Border.all(
                          color: activeColor.withValues(
                            alpha: isDark ? 0.30 : 0.15,
                          ),
                          width: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),

                // Foreground interactive tab buttons
                Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _NavTabButton(
                          item: items[i],
                          isSelected: i == safeIndex,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                          dangerColor: p.danger,
                          useMonoLabels: useMonoLabels,
                          onTap: () {
                            if (i != safeIndex) {
                              AudioHelper.tapFeedback();
                              onTap(i);
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTabButton extends StatefulWidget {
  const _NavTabButton({
    required this.item,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.dangerColor,
    required this.useMonoLabels,
    required this.onTap,
  });

  final VeloraFloatingNavItem item;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final Color dangerColor;
  final bool useMonoLabels;
  final VoidCallback onTap;

  @override
  State<_NavTabButton> createState() => _NavTabButtonState();
}

class _NavTabButtonState extends State<_NavTabButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final fgColor = isSelected ? widget.activeColor : widget.inactiveColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.06 : 0.96,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      isSelected ? widget.item.selectedIcon : widget.item.icon,
                      size: 21,
                      color: fgColor,
                    ),
                  ),
                  if (widget.item.badgeCount > 0)
                    Positioned(
                      right: -9,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: BoxDecoration(
                          color: widget.dangerColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.item.badgeCount > 99
                              ? '99+'
                              : '${widget.item.badgeCount}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    fontFamily: widget.useMonoLabels ? 'JetBrains Mono' : null,
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: fgColor,
                    letterSpacing: -0.15,
                    height: 1.15,
                  ),
                  child: Text(
                    widget.item.label,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
