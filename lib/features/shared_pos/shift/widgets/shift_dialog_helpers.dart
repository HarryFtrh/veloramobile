import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';

/// Helper widgets for shift modals (summary rows and quick cash chips).
Widget buildSummaryRow(
  String label,
  String value, {
  BuildContext? context,
  bool isBold = false,
  Color? textColor,
  double? valueFontSize,
}) {
  final p = context?.palette ?? AppPalette.clinical;
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Flexible(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isBold ? p.textPrimary : p.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      const SizedBox(width: 8),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          style: TextStyle(
            fontSize: valueFontSize ?? (isBold ? 14 : 12),
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: textColor ?? p.textPrimary,
          ),
        ),
      ),
    ],
  );
}

Widget buildQuickCashChip(String label, VoidCallback onTap, {BuildContext? context, bool isDanger = false}) {
  final p = context?.palette ?? AppPalette.clinical;
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDanger ? p.danger.withValues(alpha: 0.1) : p.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDanger ? p.danger.withValues(alpha: 0.3) : p.line,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDanger ? p.danger : p.textPrimary,
        ),
      ),
    ),
  );
}
