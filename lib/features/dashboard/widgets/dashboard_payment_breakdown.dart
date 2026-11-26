import 'package:material_ui/material_ui.dart';

import '../../../core/design/tokens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/velora_analytics_widgets.dart';
import '../dashboard_service.dart';

/// Rincian Penerimaan Kasir berdasarkan Metode Pembayaran
class DashboardPaymentBreakdownCard extends StatelessWidget {
  final DashboardSummary summary;

  const DashboardPaymentBreakdownCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final cash = summary.cashTotal;
    final qris = summary.qrisTotal;
    final debit = summary.debitTotal;
    final transfer = summary.transferTotal;
    final other = summary.otherTotal;
    final total = cash + qris + debit + transfer + other;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_rounded, size: 18, color: p.textPrimary),
              const SizedBox(width: 8),
              Text(
                'Metode Pembayaran Masuk',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
              ),
              const Spacer(),
              VeloraRollingCounter(
                value: total > 0 ? total : summary.revenue,
                formatter: (v) => 'Total: ${CurrencyFormatter.format(v)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: p.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Multi-Segment Proportion Bar with synced percentage legend
          if (total > 0) ...[
            VeloraSegmentedBar(
              height: 10,
              segments: [
                VeloraSegmentItem(
                  label: 'Tunai',
                  value: cash.toDouble(),
                  color: const Color(0xFF10B981),
                ),
                VeloraSegmentItem(
                  label: 'QRIS',
                  value: qris.toDouble(),
                  color: const Color(0xFF6366F1),
                ),
                VeloraSegmentItem(
                  label: 'Kartu',
                  value: debit.toDouble(),
                  color: const Color(0xFFF59E0B),
                ),
                VeloraSegmentItem(
                  label: 'Transfer',
                  value: transfer.toDouble(),
                  color: const Color(0xFF0EA5E9),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // 4 Channels Grid
          Row(
            children: [
              Expanded(
                child: _PaymentItem(
                  label: 'Tunai',
                  amount: cash,
                  color: const Color(0xFF10B981),
                  icon: Icons.money_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PaymentItem(
                  label: 'QRIS',
                  amount: qris,
                  color: const Color(0xFF6366F1),
                  icon: Icons.qr_code_2_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PaymentItem(
                  label: 'Kartu/EDC',
                  amount: debit,
                  color: const Color(0xFFF59E0B),
                  icon: Icons.credit_card_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PaymentItem(
                  label: 'Transfer',
                  amount: transfer,
                  color: const Color(0xFF0EA5E9),
                  icon: Icons.account_balance_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _PaymentItem({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: p.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              CurrencyFormatter.format(amount),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: p.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
