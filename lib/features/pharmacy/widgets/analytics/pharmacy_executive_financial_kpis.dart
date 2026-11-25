import 'package:material_ui/material_ui.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../pharmacy_colors.dart';

/// 4 Financial KPI metric cards for executive pharmacy dashboard
class PharmacyExecutiveFinancialKpis extends StatelessWidget {
  final num grossRevenue;
  final num cogs;
  final num grossProfit;
  final double grossMarginPct;
  final num operationalExpense;
  final num netProfit;

  const PharmacyExecutiveFinancialKpis({
    super.key,
    required this.grossRevenue,
    required this.cogs,
    required this.grossProfit,
    required this.grossMarginPct,
    required this.operationalExpense,
    required this.netProfit,
  });

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = PharmacyColors.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
              child: _buildFinancialCard(
                title: 'Omzet Kotor (Revenue)',
                value: CurrencyFormatter.format(grossRevenue),
                subtitle: grossRevenue > 0 ? 'Omzet terakumulasi' : 'Belum ada transaksi',
                accentColor: emeraldPrimary,
                icon: Icons.trending_up_rounded,
              ),
            ),
            SizedBox(
              width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
              child: _buildFinancialCard(
                title: 'HPP Obat (COGS)',
                value: CurrencyFormatter.format(cogs),
                subtitle: grossRevenue > 0 ? '${((cogs / grossRevenue) * 100).toStringAsFixed(1)}% dari omzet' : '0% dari omzet',
                accentColor: const Color(0xFF0D9488),
                icon: Icons.inventory_2_outlined,
              ),
            ),
            SizedBox(
              width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
              child: _buildFinancialCard(
                title: 'Margin Kotor (%)',
                value: '${grossMarginPct.toStringAsFixed(1)}%',
                subtitle: CurrencyFormatter.format(grossProfit),
                accentColor: const Color(0xFF0284C7),
                icon: Icons.pie_chart_outline_rounded,
              ),
            ),
            SizedBox(
              width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
              child: _buildFinancialCard(
                title: 'Laba Bersih (Net Profit)',
                value: CurrencyFormatter.format(netProfit),
                subtitle: 'Beban op. ${CurrencyFormatter.format(operationalExpense)}',
                accentColor: const Color(0xFF6366F1),
                icon: Icons.account_balance_rounded,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFinancialCard({
    required String title,
    required String value,
    required String subtitle,
    required Color accentColor,
    required IconData icon,
  }) {
    return Builder(
      builder: (context) {
        final p = context.palette;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: TextStyle(fontSize: 11, color: p.textSecondary)),
                  Icon(icon, color: accentColor, size: 18),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: accentColor),
              ),
            ],
          ),
        );
      },
    );
  }
}
