import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';

/// Helper widgets for shift modals (summary rows and quick cash chips).
Widget buildSummaryRow(
  String label,
  String value, {
  bool isBold = false,
  Color? textColor,
  double? valueFontSize,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Flexible(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isBold ? WarmPalette.textPrimary : WarmPalette.textSecondary,
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
            color: textColor ?? WarmPalette.textPrimary,
          ),
        ),
      ),
    ],
  );
}

Widget buildQuickCashChip(String label, VoidCallback onTap, {bool isDanger = false}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDanger ? WarmPalette.danger.withValues(alpha: 0.1) : WarmPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDanger ? WarmPalette.danger.withValues(alpha: 0.3) : WarmPalette.line,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDanger ? WarmPalette.danger : WarmPalette.textPrimary,
        ),
      ),
    ),
  );
}
