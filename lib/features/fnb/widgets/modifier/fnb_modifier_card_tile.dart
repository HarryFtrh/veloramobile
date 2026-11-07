import 'package:flutter/material.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../modifiers.dart';

/// Single interactive modifier option tile with radio/check indicator and price pill
class FnbModifierCardTile extends StatelessWidget {
  final ModifierGroup group;
  final ModifierOption option;
  final bool isSelected;
  final VoidCallback onToggle;

  const FnbModifierCardTile({
    super.key,
    required this.group,
    required this.option,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final hasPrice = option.price > 0;

    return Material(
      color: isSelected ? primaryColor.withValues(alpha: 0.07) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? primaryColor : p.line,
          width: isSelected ? 1.6 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              // Selection Indicator (Radio circle for single, checkbox for multi)
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: group.isSingleChoice ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: group.isSingleChoice ? null : BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected ? primaryColor : p.textTertiary,
                    width: isSelected ? 2 : 1.4,
                  ),
                  color: isSelected
                      ? (group.isSingleChoice ? Colors.transparent : primaryColor)
                      : Colors.transparent,
                ),
                child: isSelected
                    ? (group.isSingleChoice
                        ? Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.check_rounded,
                            size: 13,
                            color: Colors.white,
                          ))
                    : null,
              ),
              const SizedBox(width: 8),

              // Option Name
              Expanded(
                child: Text(
                  option.name,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? primaryColor : p.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Price badge if any
              if (hasPrice) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor.withValues(alpha: 0.15)
                        : p.surfaceMuted,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '+${CurrencyFormatter.format(option.price)}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? primaryColor : p.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
