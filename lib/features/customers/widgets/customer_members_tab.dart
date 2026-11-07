import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/design/components.dart';
import '../../../core/design/paged_list.dart';
import '../../../core/design/tokens.dart';
import '../../../core/state/paged_cubit.dart';
import '../../../core/utils/currency_formatter.dart';
import '../customer_service.dart';
import 'customer_add_dialog.dart';
import 'customer_member_tile.dart';

/// Loyalty members tab view with search, member metrics, and registration action
class CustomerMembersTab extends StatefulWidget {
  const CustomerMembersTab({super.key});

  @override
  State<CustomerMembersTab> createState() => _CustomerMembersTabState();
}

class _CustomerMembersTabState extends State<CustomerMembersTab>
    with AutomaticKeepAliveClientMixin {
  static const _searchDelay = Duration(milliseconds: 400);

  late final PagedCubit<LoyaltyMember> _cubit;
  Timer? _debounce;
  String _query = '';

  @override
  bool get wantKeepAlive => true;

  PageFetcher<LoyaltyMember> _fetcher(String query) =>
      (page) => CustomerService.instance.members(search: query, page: page);

  @override
  void initState() {
    super.initState();
    _cubit = PagedCubit(_fetcher(''))..reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cubit.close();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(_searchDelay, () {
      if (value.trim() == _query) return;
      _query = value.trim();
      _cubit.reload(_fetcher(_query));
    });
  }

  void _showAddCustomerDialog() {
    CustomerAddDialog.show(context, onSaved: () => _cubit.reload());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddCustomerDialog,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add_rounded, size: 20),
          label: const Text('Tambah Pelanggan', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, 0),
              child: TextField(
                onChanged: _onSearch,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Cari nama, telepon, atau email',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: PagedListView<LoyaltyMember>(
                emptyIcon: Icons.people_outline,
                emptyTitle: 'Belum ada anggota',
                emptyMessage: _query.isEmpty
                    ? 'Anggota loyalty akan muncul di sini.'
                    : 'Tidak ada hasil untuk "$_query".',
                header: (context, state) {
                  final stats = state.extra;
                  if (stats is! MemberStats) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: Gap.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: StatTile(
                            label: 'Total anggota',
                            value: NumberFormat.decimalPattern('id_ID')
                                .format(stats.totalMembers),
                            caption: '+${stats.newThisMonth} bulan ini',
                          ),
                        ),
                        const SizedBox(width: Gap.md),
                        Expanded(
                          child: StatTile(
                            label: 'Rata-rata belanja',
                            value: CurrencyFormatter.format(stats.avgSpend),
                            caption: '${stats.activeLoyalty} punya poin',
                          ),
                        ),
                      ],
                    ),
                  );
                },
                itemBuilder: (context, m) => CustomerMemberTile(member: m),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
