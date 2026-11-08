import 'package:flutter/material.dart';
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
    final primary = theme.colorScheme.primary;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: (!isWide || canPop)
            ? AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 0,
                foregroundColor: const Color(0xFF0F172A),
                iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
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
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Manajemen Pelanggan',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Loyalitas Anggota & Buku Hutang',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: Color(0xFF64748B)),
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
                  unselectedLabelColor: const Color(0xFF64748B),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TabBar(
                      indicatorColor: primary,
                      indicatorWeight: 3,
                      labelColor: primary,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                      unselectedLabelColor: const Color(0xFF64748B),
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
