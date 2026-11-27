import 'package:material_ui/material_ui.dart';

import '../../core/design/tokens.dart';
import 'widgets/customer_debts_tab.dart';
import 'widgets/customer_members_tab.dart';

export 'widgets/customer_add_dialog.dart';
export 'widgets/customer_debt_sheet.dart';
export 'widgets/customer_debt_tile.dart';
export 'widgets/customer_debts_tab.dart';
export 'widgets/customer_member_tile.dart';
export 'widgets/customer_members_tab.dart';

/// Customers screen with modern pill-segmented tabs for Loyalty Members
/// and Accounts Receivable (Debts).
class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 600;
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final p = context.palette;
    final primary = theme.colorScheme.primary;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: p.canvas,
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                children: [
                  if (!isWide || canPop)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(
                        children: [
                          if (canPop) ...[
                            Material(
                              color: p.surface,
                              shape: CircleBorder(
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : p.line.withValues(alpha: 0.55),
                                ),
                              ),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => Navigator.of(context).pop(),
                                child: SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    Icons.chevron_left_rounded,
                                    size: 22,
                                    color: p.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pelanggan',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: p.textPrimary,
                                    letterSpacing: -0.6,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Anggota loyalitas & buku hutang',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: p.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Modern Pill-Segmented TabBar
                  Container(
                    margin: EdgeInsets.fromLTRB(16, isWide && !canPop ? 14 : 0, 16, 10),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : p.line.withValues(alpha: 0.65),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
                          blurRadius: 12,
                          spreadRadius: -3,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TabBar(
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      splashBorderRadius: BorderRadius.circular(999),
                      indicator: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: p.textSecondary,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        letterSpacing: -0.1,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                      tabs: const [
                        Tab(
                          height: 38,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.card_membership_rounded, size: 16),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Member Loyalitas',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Tab(
                          height: 38,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_rounded, size: 16),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Buku Hutang',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Expanded(
                    child: TabBarView(
                      physics: BouncingScrollPhysics(),
                      children: [
                        CustomerMembersTab(),
                        CustomerDebtsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
