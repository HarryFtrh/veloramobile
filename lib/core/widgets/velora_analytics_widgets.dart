import 'package:material_ui/material_ui.dart';

import '../design/tokens.dart';

/// Smoothly animates a numeric KPI value (e.g. Rupiah revenue) from 0 or its
/// previous value using a fast easing curve.
class VeloraRollingCounter extends StatelessWidget {
  const VeloraRollingCounter({
    super.key,
    required this.value,
    required this.formatter,
    this.style,
    this.duration = const Duration(milliseconds: 650),
    this.maxLines = 1,
  });

  final num value;
  final String Function(num value) formatter;
  final TextStyle? style;
  final Duration duration;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, animatedVal, _) => Text(
        formatter(animatedVal.round()),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}

class VeloraSegmentItem {
  const VeloraSegmentItem({
    required this.label,
    required this.value,
    required this.color,
    this.valueText,
  });

  final String label;
  final double value;
  final Color color;
  final String? valueText;
}

/// Multi-segment proportional category/payment breakdown bar with synced
/// legend pills, inspired by modern fintech spend-analytics cards.
class VeloraSegmentedBar extends StatelessWidget {
  const VeloraSegmentedBar({
    super.key,
    required this.segments,
    this.height = 10,
  });

  final List<VeloraSegmentItem> segments;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final positive = segments.where((s) => s.value > 0).toList(growable: false);
    final total = positive.fold<double>(0, (sum, s) => sum + s.value);

    if (positive.isEmpty || total <= 0) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: p.surfaceMuted,
          borderRadius: BorderRadius.circular(height),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                for (var i = 0; i < positive.length; i++) ...[
                  Expanded(
                    flex: (positive[i].value / total * 1000).round().clamp(1, 1000),
                    child: Container(color: positive[i].color),
                  ),
                  if (i < positive.length - 1) const SizedBox(width: 2.5),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            for (final seg in positive)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: seg.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${seg.label} ${(seg.value / total * 100).round()}%',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: p.textSecondary,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
