import 'package:flutter/material.dart';
import '../utils/audio_helper.dart';

class VirtualNumpad extends StatelessWidget {
  final num totalAmount;
  final num currentPaid;
  final ValueChanged<num> onPaidChanged;

  const VirtualNumpad({
    super.key,
    required this.totalAmount,
    required this.currentPaid,
    required this.onPaidChanged,
  });

  void _onDigit(String digit) {
    AudioHelper.tapFeedback();
    final currentStr = currentPaid.toInt().toString();
    final newStr = (currentPaid == 0) ? digit : '$currentStr$digit';
    onPaidChanged(num.tryParse(newStr) ?? 0);
  }

  void _onClear() {
    AudioHelper.actionFeedback();
    onPaidChanged(0);
  }

  void _onBackspace() {
    AudioHelper.tapFeedback();
    final str = currentPaid.toInt().toString();
    if (str.length <= 1) {
      onPaidChanged(0);
    } else {
      onPaidChanged(num.tryParse(str.substring(0, str.length - 1)) ?? 0);
    }
  }

  void _addQuickCash(num add) {
    AudioHelper.actionFeedback();
    onPaidChanged(currentPaid + add);
  }

  void _setExact() {
    AudioHelper.actionFeedback();
    onPaidChanged(totalAmount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Quick Denominations Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              _QuickCashChip(
                label: 'Uang Pas',
                highlight: true,
                onTap: _setExact,
                color: primary,
              ),
              _QuickCashChip(
                label: '+10.000',
                onTap: () => _addQuickCash(10000),
              ),
              _QuickCashChip(
                label: '+20.000',
                onTap: () => _addQuickCash(20000),
              ),
              _QuickCashChip(
                label: '+50.000',
                onTap: () => _addQuickCash(50000),
              ),
              _QuickCashChip(
                label: '+100.000',
                onTap: () => _addQuickCash(100000),
              ),
            ],
          ),
        ),

        // Keypad Grid
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.8,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            _NumpadButton(text: '1', onTap: () => _onDigit('1')),
            _NumpadButton(text: '2', onTap: () => _onDigit('2')),
            _NumpadButton(text: '3', onTap: () => _onDigit('3')),
            _NumpadButton(text: '4', onTap: () => _onDigit('4')),
            _NumpadButton(text: '5', onTap: () => _onDigit('5')),
            _NumpadButton(text: '6', onTap: () => _onDigit('6')),
            _NumpadButton(text: '7', onTap: () => _onDigit('7')),
            _NumpadButton(text: '8', onTap: () => _onDigit('8')),
            _NumpadButton(text: '9', onTap: () => _onDigit('9')),
            _NumpadButton(
              text: 'C',
              color: Colors.red.shade400,
              onTap: _onClear,
            ),
            _NumpadButton(text: '0', onTap: () => _onDigit('0')),
            _NumpadButton(
              icon: Icons.backspace_outlined,
              onTap: _onBackspace,
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickCashChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool highlight;
  final Color? color;

  const _QuickCashChip({
    required this.label,
    required this.onTap,
    this.highlight = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(
          label,
          style: TextStyle(
            color: highlight ? Colors.white : null,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        backgroundColor: highlight ? (color ?? Colors.blue) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onPressed: onTap,
      ),
    );
  }
}

class _NumpadButton extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final Color? color;
  final VoidCallback onTap;

  const _NumpadButton({
    this.text,
    this.icon,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF222631) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Center(
          child: text != null
              ? Text(
                  text!,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color ?? (isDark ? Colors.white : const Color(0xFF1E293B)),
                  ),
                )
              : Icon(
                  icon,
                  size: 24,
                  color: color ?? (isDark ? Colors.white70 : const Color(0xFF64748B)),
                ),
        ),
      ),
    );
  }
}
