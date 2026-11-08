import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../dashboard_cubit.dart';

/// Selector Rentang Waktu dengan Desain Segmented Pills Modern
class DashboardRangePicker extends StatelessWidget {
  final DashboardRange selected;
  final ValueChanged<DashboardRange> onChanged;

  const DashboardRangePicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: p.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.line),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (final r in DashboardRange.values)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(r),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected == r ? p.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: selected == r
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _iconForRange(r),
                        size: 14,
                        color: selected == r ? primaryColor : p.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        r.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected == r ? FontWeight.w800 : FontWeight.w600,
                          color: selected == r ? p.textPrimary : p.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static IconData _iconForRange(DashboardRange r) => switch (r) {
        DashboardRange.today => Icons.today_rounded,
        DashboardRange.week => Icons.date_range_rounded,
        DashboardRange.month => Icons.calendar_month_rounded,
      };
}
