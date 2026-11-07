import 'package:flutter/material.dart';
import '../../../../core/design/tokens.dart';
import '../../modifiers.dart';
import 'fnb_modifier_card_tile.dart';

/// Group header with requirement badge and responsive grid/column of modifier options
class FnbModifierGroupSection extends StatelessWidget {
  final ModifierGroup group;
  final Set<String> selectedOptionIds;
  final void Function(ModifierOption) onToggle;

  const FnbModifierGroupSection({
    super.key,
    required this.group,
    required this.selectedOptionIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final selectedCount = selectedOptionIds.length;
    final isSatisfied = selectedCount >= group.requiredCount;
    final isRequired = group.requiredCount > 0;

    String badgeText;
    if (isRequired) {
      badgeText = group.isSingleChoice ? 'Wajib · Pilih 1' : 'Wajib · Min ${group.requiredCount}';
    } else {
      badgeText = group.isSingleChoice ? 'Opsional · Pilih 1' : 'Opsional · Maks ${group.maxSelect}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                group.name,
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: p.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: isRequired && !isSatisfied
                    ? p.danger.withValues(alpha: 0.1)
                    : p.surfaceMuted,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isRequired && !isSatisfied
                      ? p.danger.withValues(alpha: 0.4)
                      : p.line,
                ),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isRequired && !isSatisfied ? p.danger : p.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Modern Card-Tiles
        LayoutBuilder(
          builder: (context, constraints) {
            // Jika lebar mencukupi (misal > 380), tampilkan 2 kolom tile, jika kecil 1 kolom
            final useTwoCols = constraints.maxWidth >= 380;
            if (useTwoCols) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final o in group.options)
                    SizedBox(
                      width: (constraints.maxWidth - 8) / 2,
                      child: FnbModifierCardTile(
                        group: group,
                        option: o,
                        isSelected: selectedOptionIds.contains(o.id),
                        onToggle: () => onToggle(o),
                      ),
                    ),
                ],
              );
            }

            return Column(
              children: [
                for (int oi = 0; oi < group.options.length; oi++) ...[
                  FnbModifierCardTile(
                    group: group,
                    option: group.options[oi],
                    isSelected: selectedOptionIds.contains(group.options[oi].id),
                    onToggle: () => onToggle(group.options[oi]),
                  ),
                  if (oi < group.options.length - 1) const SizedBox(height: 6),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
