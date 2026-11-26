import 'package:material_ui/material_ui.dart';
import 'package:shimmer/shimmer.dart';
import 'tokens.dart';

export '../components/velora_logo.dart';
export '../widgets/velora_loading.dart';
export 'app_confirm_dialog.dart';
export '../utils/app_regex.dart';
export '../utils/app_toast.dart';
export '../utils/date_time_formatter.dart';
export '../widgets/app_qr_view.dart';

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
          VeloraOrbitLoader.inline(
            size: 18,
            color: fgColor,
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
    if (items.isEmpty) return const SizedBox.shrink();

    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safeIndex = currentIndex.clamp(0, items.length - 1);
    final alignX = items.length <= 1
        ? 0.0
        : -1.0 + (2.0 * safeIndex / (items.length - 1));

    return RepaintBoundary(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 28, right: 28),
          child: Container(
            height: 60,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: Corner.full,
              border: Border.all(
                color: p.line.withValues(alpha: isDark ? 0.75 : 0.9),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.36 : 0.09),
                  blurRadius: 18,
                  spreadRadius: -2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                AnimatedAlign(
                  alignment: Alignment(alignX, 0),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  child: FractionallySizedBox(
                    widthFactor: 1 / items.length,
                    heightFactor: 1,
                    child: Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: p.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: List.generate(items.length, (index) {
                    final isSelected = index == safeIndex;
                    final item = items[index];
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onTap(index),
                        child: Center(
                          child: AnimatedScale(
                            scale: isSelected ? 1.06 : 0.96,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            child: Icon(
                              isSelected
                                  ? (item.activeIcon ?? item.icon)
                                  : item.icon,
                              color: isSelected ? Colors.white : p.textSecondary,
                              size: 23,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
