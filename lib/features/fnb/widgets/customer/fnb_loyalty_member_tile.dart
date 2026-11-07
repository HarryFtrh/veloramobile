import 'package:flutter/material.dart';
import '../../../../core/design/tokens.dart';
import '../../../customers/customer_service.dart';

/// Card tile for a loyalty member in customer picker sheet
class FnbLoyaltyMemberTile extends StatelessWidget {
  final LoyaltyMember member;
  final bool isSelected;
  final VoidCallback onSelect;

  const FnbLoyaltyMemberTile({
    super.key,
    required this.member,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onSelect,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFEF3C7) : p.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? const Color(0xFFD97706) : p.line,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFFEF3C7),
                child: Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : 'M',
                  style: const TextStyle(
                    color: Color(0xFFB45309),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 12, color: p.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          member.phone.isNotEmpty ? member.phone : '-',
                          style: TextStyle(fontSize: 11, color: p.textSecondary),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${member.points} Poin',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle_rounded, color: Color(0xFFD97706), size: 22)
              else
                Icon(Icons.add_circle_outline_rounded, color: p.textSecondary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
