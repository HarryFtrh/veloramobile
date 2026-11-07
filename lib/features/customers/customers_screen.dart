import 'package:flutter/material.dart';
import 'widgets/customer_debts_tab.dart';
import 'widgets/customer_members_tab.dart';

export 'widgets/customer_add_dialog.dart';
export 'widgets/customer_debt_sheet.dart';
export 'widgets/customer_debt_tile.dart';
export 'widgets/customer_debts_tab.dart';
export 'widgets/customer_member_tile.dart';
export 'widgets/customer_members_tab.dart';

/// Customers screen with tabs for Loyalty Members and Accounts Receivable (Debts)
class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
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
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  Text(
                    'Loyalitas Anggota & Buku Hutang',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
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
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: TabBarView(
              children: const [
                CustomerMembersTab(),
                CustomerDebtsTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
