import 'package:flutter/material.dart';
import '../../../core/design/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../customer_service.dart';

/// Card tile for a loyalty member in the customer list
class CustomerMemberTile extends StatelessWidget {
  final LoyaltyMember member;

  const CustomerMemberTile({
    super.key,
    required this.member,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: p.surfaceMuted,
            foregroundColor: p.textSecondary,
            child: Text(member.name.isEmpty ? '?' : member.name[0].toUpperCase()),
          ),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (member.phone.isNotEmpty)
                  Text(
                    member.phone,
                    style: text.bodySmall?.copyWith(color: p.textSecondary),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(member.totalSpend),
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: Gap.xs),
              StatusChip(
                label: '${member.points} poin',
                tone: member.points > 0 ? StatusTone.info : StatusTone.neutral,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
