import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';

/// Sweetness and ice level customization options for beverage items
class CustomerProductBeverageOptions extends StatelessWidget {
  final String selectedSweetness;
  final String selectedIce;
  final ValueChanged<String> onSweetnessChanged;
  final ValueChanged<String> onIceChanged;

  const CustomerProductBeverageOptions({
    super.key,
    required this.selectedSweetness,
    required this.selectedIce,
    required this.onSweetnessChanged,
    required this.onIceChanged,
  });

  Widget _buildIceChip(BuildContext context, String label, IconData icon) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isSel = selectedIce == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => onIceChanged(label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSel ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSel ? Colors.transparent : p.line,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSel ? Colors.white : p.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSel ? Colors.white : p.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sweetness Level
        Text(
          'Level Gula / Sweetness',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: p.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            'Normal (100%)',
            'Less Sugar (50%)',
            'No Sugar (0%)',
          ].map((opt) {
            final isSel = selectedSweetness == opt;
            return ChoiceChip(
              label: Text(opt),
              selected: isSel,
              onSelected: (_) => onSweetnessChanged(opt),
              selectedColor: primaryColor,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSel ? Colors.white : p.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              shape: const StadiumBorder(),
              side: BorderSide(
                color: isSel ? Colors.transparent : p.line,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Ice Level
        Text(
          'Level Es / Suhu',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: p.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildIceChip(context, 'Normal Ice', Icons.ac_unit_rounded),
            const SizedBox(width: 8),
            _buildIceChip(context, 'Less Ice', Icons.mode_fan_off_rounded),
            const SizedBox(width: 8),
            _buildIceChip(context, 'Warm / Hot', Icons.coffee_rounded),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
