import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/design/components.dart';
import '../../core/design/paged_list.dart';
import '../../core/design/tokens.dart';
import '../../core/network/api_exception.dart';
import '../../core/state/paged_cubit.dart';
import '../../core/utils/currency_formatter.dart';
import '../auth/auth_service.dart';
import '../auth/cubit/auth_cubit.dart';
import '../auth/cubit/auth_state.dart';
import 'customer_service.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pelanggan'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Anggota'), Tab(text: 'Hutang')],
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: const TabBarView(children: [_MembersTab(), _DebtsTab()]),
          ),
        ),
      ),
    );
  }
}

// ── Anggota ────────────────────────────────────────────────────────────────

class _MembersTab extends StatefulWidget {
  const _MembersTab();

  @override
  State<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<_MembersTab>
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider.value(
      value: _cubit,
      child: Column(
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
              itemBuilder: (context, m) => _MemberTile(member: m),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final LoyaltyMember member;

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
                Text(member.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                if (member.phone.isNotEmpty)
                  Text(member.phone,
                      style: text.bodySmall?.copyWith(color: p.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(CurrencyFormatter.format(member.totalSpend),
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
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

// ── Hutang ─────────────────────────────────────────────────────────────────

class _DebtsTab extends StatefulWidget {
  const _DebtsTab();

  @override
  State<_DebtsTab> createState() => _DebtsTabState();
}

class _DebtsTabState extends State<_DebtsTab>
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
        child: _DebtSheet(debt: debt),
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
              onSelectionChanged: (s) => _setStatus(s.first),
            ),
          ),
          Expanded(
            child: PagedListView<Debt>(
              emptyIcon: Icons.receipt_long_outlined,
              emptyTitle: _status == DebtStatus.unpaid
                  ? 'Tidak ada hutang berjalan'
                  : 'Belum ada hutang lunas',
              itemBuilder: (context, d) => _DebtTile(debt: d, onTap: () => _open(d)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtTile extends StatelessWidget {
  const _DebtTile({required this.debt, required this.onTap});

  final Debt debt;
  final VoidCallback onTap;

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
                Text(debt.customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                if (due != null)
                  Text('Jatuh tempo ${_dateFmt.format(due)}',
                      style: text.bodySmall?.copyWith(
                        color: debt.isOverdue ? p.danger : p.textSecondary,
                      )),
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

/// Aksi pada satu hutang: lunasi (pilih metode bayar) atau hapus buku.
class _DebtSheet extends StatefulWidget {
  const _DebtSheet({required this.debt});

  final Debt debt;

  @override
  State<_DebtSheet> createState() => _DebtSheetState();
}

class _DebtSheetState extends State<_DebtSheet> {
  SettleMethod _method = SettleMethod.cash;
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = ApiException.from(e).message;
        });
      }
    }
  }

  Future<void> _confirmWriteOff() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.warning_amber_rounded, color: Theme.of(ctx).colorScheme.error, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Hapus Buku Hutang?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        content: Text(
          'Sisa ${CurrencyFormatter.format(widget.debt.balance)} dari '
          '${widget.debt.customerName} akan dianggap tidak tertagih. '
          'Tindakan ini tidak bisa dibatalkan.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus Buku'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _run(() => CustomerService.instance.writeOff(widget.debt.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final debt = widget.debt;
    final settled = debt.status == DebtStatus.paid;
    final authState = context.read<AuthCubit>().state;
    final canWriteOff = authState is Authenticated && authState.user.can(AppPermission.writeOffDebt);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          Gap.lg,
          0,
          Gap.lg,
          Gap.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(debt.customerName,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            if (debt.phone.isNotEmpty)
              Text(debt.phone, style: text.bodyMedium?.copyWith(color: p.textSecondary)),
            const SizedBox(height: Gap.lg),
            _line(context, 'Total hutang', CurrencyFormatter.format(debt.amount)),
            _line(context, 'Sisa', CurrencyFormatter.format(debt.balance), bold: true),
            if (!settled) ...[
              const SizedBox(height: Gap.lg),
              Text('Metode pembayaran',
                  style: text.labelLarge?.copyWith(color: p.textSecondary)),
              const SizedBox(height: Gap.sm),
              Wrap(
                spacing: Gap.sm,
                children: [
                  for (final m in SettleMethod.values)
                    ChoiceChip(
                      label: Text(m.label),
                      selected: _method == m,
                      onSelected: _busy ? null : (_) => setState(() => _method = m),
                    ),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: Gap.md),
              Text(_error!, style: TextStyle(color: p.danger)),
            ],
            if (!settled) ...[
              const SizedBox(height: Gap.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() => CustomerService.instance.settle(debt.id, _method)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Lunasi'),
                ),
              ),
              if (canWriteOff) ...[
                const SizedBox(height: Gap.sm),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _busy ? null : _confirmWriteOff,
                    style: TextButton.styleFrom(foregroundColor: p.danger),
                    child: const Text('Hapus buku'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value, {bool bold = false}) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: text.bodyMedium?.copyWith(color: context.palette.textSecondary)),
          ),
          Text(value,
              style: text.bodyMedium?.copyWith(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              )),
        ],
      ),
    );
  }
}
