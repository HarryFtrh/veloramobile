import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/design/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../customer_service.dart';

/// Card tile for customer debt item
class CustomerDebtTile extends StatelessWidget {
  final Debt debt;
  final VoidCallback onTap;

  const CustomerDebtTile({
    super.key,
    required this.debt,
    required this.onTap,
  });

  static final _dateFmt = DateFormat('d MMM yyyy', 'id_ID');

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final due = debt.dueDate;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (due != null)
                  Text(
                    'Jatuh tempo ${_dateFmt.format(due)}',
                    style: text.bodySmall?.copyWith(
                      color: debt.isOverdue ? p.danger : p.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(
                  debt.status == DebtStatus.paid ? debt.amount : debt.balance,
                ),
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: Gap.xs),
              if (debt.status == DebtStatus.paid)
                const StatusChip(label: 'Lunas', tone: StatusTone.success)
              else if (debt.isOverdue)
                const StatusChip(label: 'Terlambat', tone: StatusTone.danger)
              else
                const StatusChip(label: 'Belum lunas', tone: StatusTone.warning),
            ],
          ),
        ],
      ),
    );
  }
}
