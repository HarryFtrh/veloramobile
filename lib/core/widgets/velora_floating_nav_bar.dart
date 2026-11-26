import 'dart:ui';

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

/// Reusable Floating Pill Frosted-Glass Bottom Navigation Bar shared across all
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
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = Theme.of(context).colorScheme.primary;
    final inactiveColor = p.textSecondary;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.10),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: activeColor.withValues(alpha: isDark ? 0.08 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: p.surface.withValues(alpha: isDark ? 0.88 : 0.94),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: p.line.withValues(alpha: 0.9),
                    width: 1.1,
                  ),
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _buildItem(
                          item: items[i],
                          isSelected: i == currentIndex,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                          dangerColor: p.danger,
                          onTap: () {
                            if (i != currentIndex) AudioHelper.tapFeedback();
                            onTap(i);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem({
    required VeloraFloatingNavItem item,
    required bool isSelected,
    required Color activeColor,
    required Color inactiveColor,
    required Color dangerColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      isSelected ? item.selectedIcon : item.icon,
                      size: 21,
                      color: isSelected ? activeColor : inactiveColor,
                    ),
                  ),
                  if (item.badgeCount > 0)
                    Positioned(
                      right: -8,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        decoration: BoxDecoration(
                          color: dangerColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.badgeCount > 99 ? '99+' : '${item.badgeCount}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: useMonoLabels ? 'JetBrains Mono' : null,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
