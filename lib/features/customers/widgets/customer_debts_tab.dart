import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/design/paged_list.dart';
import '../../../core/design/tokens.dart';
import '../../../core/state/paged_cubit.dart';
import '../customer_service.dart';
import 'customer_debt_sheet.dart';
import 'customer_debt_tile.dart';

/// Debts tab view with status segments (unpaid/paid) and modal settlement sheet
class CustomerDebtsTab extends StatefulWidget {
  const CustomerDebtsTab({super.key});

  @override
  State<CustomerDebtsTab> createState() => _CustomerDebtsTabState();
}

class _CustomerDebtsTabState extends State<CustomerDebtsTab>
    with AutomaticKeepAliveClientMixin {
  late final PagedCubit<Debt> _cubit;
  DebtStatus _status = DebtStatus.unpaid;

  @override
  bool get wantKeepAlive => true;

  PageFetcher<Debt> _fetcher(DebtStatus status) =>
      (page) => CustomerService.instance.debts(status: status, page: page);

  @override
  void initState() {
    super.initState();
    _cubit = PagedCubit(_fetcher(_status))..reload();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _setStatus(DebtStatus status) {
    if (status == _status) return;
    setState(() => _status = status);
    _cubit.reload(_fetcher(status));
  }

  Future<void> _open(Debt debt) async {
    final isMobile = context.isMobile;
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 540,
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85,
        ),
        child: CustomerDebtSheet(debt: debt),
      ),
    );
    if (changed == true) _cubit.reload();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider.value(
      value: _cubit,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, 0),
            child: SegmentedButton<DebtStatus>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: DebtStatus.unpaid, label: Text('Belum lunas')),
                ButtonSegment(value: DebtStatus.paid, label: Text('Lunas')),
              ],
              selected: {_status},
              onSelectionChanged: (s) {
                if (s.isNotEmpty) _setStatus(s.first);
              },
            ),
          ),
          Expanded(
            child: PagedListView<Debt>(
              emptyIcon: Icons.receipt_long_outlined,
              emptyTitle: _status == DebtStatus.unpaid
                  ? 'Tidak ada hutang berjalan'
                  : 'Belum ada hutang lunas',
              itemBuilder: (context, d) => CustomerDebtTile(debt: d, onTap: () => _open(d)),
            ),
          ),
        ],
      ),
    );
  }
}
