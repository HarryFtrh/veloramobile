import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'tokens.dart';

/// Kartu datar dengan border 1px. Dipakai sebagai pembungkus konten utama.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Gap.lg),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: Corner.medium,
        side: BorderSide(color: p.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Satu angka ringkasan: label kecil di atas, nilai besar di bawah.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.captionColor,
  });

  final String label;
  final String value;
  final String? caption;
  final Color? captionColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: text.bodySmall?.copyWith(color: p.textSecondary)),
          const SizedBox(height: Gap.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (caption != null) ...[
            const SizedBox(height: Gap.xs),
            Text(
              caption!,
              style: text.bodySmall?.copyWith(color: captionColor ?? p.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: p.textTertiary),
            const SizedBox(height: Gap.md),
            Text(title,
                textAlign: TextAlign.center,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            if (message != null) ...[
              const SizedBox(height: Gap.xs),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: p.textSecondary)),
            ],
            if (action != null) ...[const SizedBox(height: Gap.lg), action!],
          ],
        ),
      ),
    );
  }
}

/// Tampilan gagal-muat dengan tombol coba lagi. Pengganti `catch (_) {}`.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'Gagal memuat data',
      message: message,
      action: SizedBox(
        width: 160,
        child: OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 6, this.itemHeight = 68});

  final int count;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Shimmer.fromColors(
      baseColor: p.surfaceMuted,
      highlightColor: p.surface,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(Gap.lg),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(height: Gap.sm),
        itemBuilder: (_, _) => Container(
          height: itemHeight,
          decoration: BoxDecoration(
            color: p.surfaceMuted,
            borderRadius: Corner.medium,
          ),
        ),
      ),
    );
  }
}

enum StatusTone { success, warning, danger, info, neutral }

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.tone = StatusTone.neutral});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = switch (tone) {
      StatusTone.success => p.success,
      StatusTone.warning => p.warning,
      StatusTone.danger => p.danger,
      StatusTone.info => p.info,
      StatusTone.neutral => p.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: Corner.small,
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// 4 Varian Tombol Desain Referensi "Warm Roasted Modernity":
/// - primary: Espresso solid (#7A431D), teks putih
/// - secondary: Surface Muted (#F3EDE2), teks #70655E
/// - inverted: Dark solid (#1E1510), teks putih
/// - outlined: Transparan dengan border 1px #E8DDD1, teks #1E1510
enum AppButtonVariant { primary, secondary, inverted, outlined }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 48,
    this.shape,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? icon;
  final bool isLoading;
  final double? width;
  final double height;
  final OutlinedBorder? shape;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final borderRadius = shape ?? const StadiumBorder();

    Color bgColor;
    Color fgColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        bgColor = p.primary;
        fgColor = Colors.white;
        break;
      case AppButtonVariant.secondary:
        bgColor = p.surfaceMuted;
        fgColor = p.textSecondary;
        break;
      case AppButtonVariant.inverted:
        bgColor = p.textPrimary;
        fgColor = Colors.white;
        break;
      case AppButtonVariant.outlined:
        bgColor = Colors.transparent;
        fgColor = p.textPrimary;
        borderSide = BorderSide(color: p.line, width: 1);
        break;
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          )
        else ...[
          if (icon != null) ...[
            icon!,
            const SizedBox(width: Gap.sm),
          ],
          Text(
            label,
            style: TextStyle(
              color: fgColor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: bgColor,
        shape: borderSide != BorderSide.none
            ? (borderRadius is StadiumBorder
                ? StadiumBorder(side: borderSide)
                : RoundedRectangleBorder(
                    borderRadius: Corner.full,
                    side: borderSide,
                  ))
            : borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}

/// Search Input Bar bentuk rounded capsule sesuai gambar referensi.
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Search',
    this.onChanged,
    this.onClear,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final Widget? prefixIcon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: p.surfaceMuted,
        borderRadius: Corner.full,
        border: Border.all(color: p.line, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Gap.md),
      child: Row(
        children: [
          prefixIcon ??
              Icon(
                Icons.search_rounded,
                size: 20,
                color: p.textSecondary,
              ),
          const SizedBox(width: Gap.sm),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(
                fontSize: 14,
                color: p.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: p.textTertiary,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged?.call('');
                onClear?.call();
              },
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: p.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

/// Circular Action Badges (4 lingkaran di kanan bawah gambar referensi).
class CircularActionBadge extends StatelessWidget {
  const CircularActionBadge({
    super.key,
    required this.icon,
    required this.color,
    this.onTap,
    this.size = 40,
    this.iconSize = 20,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget badge = Material(
      color: color,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: iconSize, color: Colors.white),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: badge);
    }
    return badge;
  }
}

/// Floating Pill Navigation Bar (Navigasi melayang bentuk kapsul lonjong di tengah bawah).
class FloatingPillNavItem {
  const FloatingPillNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;
}

class FloatingPillNavBar extends StatelessWidget {
  const FloatingPillNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<FloatingPillNavItem> items;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 32, right: 32),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: Corner.full,
            border: Border.all(color: p.line, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = index == currentIndex;
              final item = items[index];

              if (isSelected) {
                return GestureDetector(
                  onTap: () => onTap(index),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: p.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.activeIcon ?? item.icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                );
              }

              return InkWell(
                onTap: () => onTap(index),
                borderRadius: Corner.full,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Icon(
                    item.icon,
                    color: p.textSecondary,
                    size: 24,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// 3 Garis Metric / Progress Horizontal sesuai gambar referensi:
/// Garis 1: Espresso (#7A431D)
/// Garis 2: Ochre (#D9822B)
/// Garis 3: Sage (#4D6B53)
class MetricHorizontalBars extends StatelessWidget {
  const MetricHorizontalBars({
    super.key,
    this.val1 = 0.85,
    this.val2 = 0.60,
    this.val3 = 0.40,
    this.height = 8,
  });

  final double val1;
  final double val2;
  final double val3;
  final double height;

  Widget _buildBar(Color color, double progress) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: Corner.full,
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: Corner.full,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBar(p.primary, val1),
        const SizedBox(height: Gap.xs),
        _buildBar(p.secondary, val2),
        const SizedBox(height: Gap.xs),
        _buildBar(p.tertiary, val3),
      ],
    );
  }
}
