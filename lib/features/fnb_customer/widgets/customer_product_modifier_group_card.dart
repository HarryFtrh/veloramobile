import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../fnb/modifiers.dart';

/// Group card with option checkboxes for customer detail sheet
class CustomerProductModifierGroupCard extends StatelessWidget {
  final ModifierGroup group;
  final Set<String> selectedToppings;
  final void Function(ModifierOption) onToggleOption;

  const CustomerProductModifierGroupCard({
    super.key,
    required this.group,
    required this.selectedToppings,
    required this.onToggleOption,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              group.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: p.surfaceMuted,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                group.isRequired
                    ? 'Wajib (${group.maxSelect} maks)'
                    : 'Opsional (maks ${group.maxSelect})',
                style: TextStyle(
                  fontSize: 11,
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...group.options.map((opt) {
          final isChecked = selectedToppings.contains(opt.name);
          return InkWell(
            onTap: () => onToggleOption(opt),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isChecked ? primaryColor : p.line,
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: isChecked,
                    activeColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (_) => onToggleOption(opt),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      opt.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: p.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    opt.price > 0
                        ? '+Rp ${opt.price.round().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}'
                        : 'Gratis',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: opt.price > 0
                          ? p.secondary
                          : p.tertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}
