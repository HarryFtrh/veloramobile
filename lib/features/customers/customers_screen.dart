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

/// Customers screen with tabs for Loyalty Members and Accounts Receivable (Debts).
/// Adaptif terhadap tablet: Menyembunyikan double-AppBar saat di dalam AppShell.
class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 600;
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final theme = Theme.of(context);
    final p = context.palette;
    final primary = theme.colorScheme.primary;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: p.canvas,
        appBar: (!isWide || canPop)
            ? AppBar(
                backgroundColor: p.surface,
                elevation: 0,
                scrolledUnderElevation: 0,
                foregroundColor: p.textPrimary,
                iconTheme: IconThemeData(color: p.textPrimary),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.people_alt_rounded, color: primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Manajemen Pelanggan',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: p.textPrimary),
                        ),
                        Text(
                          'Loyalitas Anggota & Buku Hutang',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: p.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                bottom: TabBar(
                  indicatorColor: primary,
                  indicatorWeight: 3,
                  labelColor: primary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  unselectedLabelColor: p.textSecondary,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.card_membership_rounded, size: 18),
                      text: 'Anggota Loyalitas',
                    ),
                    Tab(
                      icon: Icon(Icons.receipt_long_rounded, size: 18),
                      text: 'Buku Hutang',
                    ),
                  ],
                ),
              )
            : null,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Column(
              children: [
                if (isWide && !canPop) ...[
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.line),
                    ),
                    child: TabBar(
                      indicatorColor: primary,
                      indicatorWeight: 3,
                      labelColor: primary,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                      unselectedLabelColor: p.textSecondary,
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.card_membership_rounded, size: 18),
                          text: 'Anggota Loyalitas (Member)',
                        ),
                        Tab(
                          icon: Icon(Icons.receipt_long_rounded, size: 18),
                          text: 'Buku Hutang & Kasbon',
                        ),
                      ],
                    ),
                  ),
                ],
                const Expanded(
                  child: TabBarView(
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
    );
  }
}
