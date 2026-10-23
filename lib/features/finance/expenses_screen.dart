import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/design/components.dart';
import '../../core/design/paged_list.dart';
import '../../core/design/tokens.dart';
import '../../core/network/api_exception.dart';
import '../../core/state/paged_cubit.dart';
import '../../core/utils/currency_formatter.dart';
import 'finance_service.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  late final PagedCubit<Expense> _cubit;
  late DateTime _period;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _period = DateTime(now.year, now.month);
    _cubit = PagedCubit(_fetcher(_period))..reload();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  PageFetcher<Expense> _fetcher(DateTime period) => (page) =>
      FinanceService.instance.expenses(month: period.month, year: period.year, page: page);

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _period.year == now.year && _period.month == now.month;
  }

  void _shift(int months) {
    setState(() => _period = DateTime(_period.year, _period.month + months));
    _cubit.reload(_fetcher(_period));
  }

  Future<void> _openForm([Expense? expense]) async {
    final isMobile = context.isMobile;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 540,
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85,
        ),
        child: _ExpenseForm(expense: expense, defaultPeriod: _period),
      ),
    );
    if (saved == true) _cubit.reload();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final label = DateFormat('MMMM yyyy', 'id_ID').format(_period);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengeluaran')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: BlocProvider.value(
        value: _cubit,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Bulan sebelumnya',
                    onPressed: () => _shift(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Bulan berikutnya',
                    onPressed: _isCurrentMonth ? null : () => _shift(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
            Divider(color: p.line),
            Expanded(
              child: PagedListView<Expense>(
                emptyIcon: Icons.payments_outlined,
                emptyTitle: 'Belum ada pengeluaran',
                emptyMessage: 'Tidak ada catatan untuk $label.',
                itemBuilder: (context, e) => _ExpenseTile(
                  expense: e,
                  onTap: () => _openForm(e),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense, required this.onTap});

  final Expense expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final note = expense.description;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.category.label,
                    style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                if (note != null)
                  Text(note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: p.textSecondary)),
                if (expense.createdBy != null)
                  Text('oleh ${expense.createdBy}',
                      style: text.bodySmall?.copyWith(color: p.textTertiary)),
              ],
            ),
          ),
          const SizedBox(width: Gap.md),
          Text(CurrencyFormatter.format(expense.amount),
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ExpenseForm extends StatefulWidget {
  const _ExpenseForm({this.expense, required this.defaultPeriod});

  final Expense? expense;
  final DateTime defaultPeriod;

  @override
  State<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<_ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late ExpenseCategory _category;
  bool _busy = false;
  String? _error;

  bool get _editing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _category = e?.category ?? ExpenseCategory.lainnya;
    _amount = TextEditingController(
      text: e == null ? '' : e.amount.toStringAsFixed(0),
    );
    _note = TextEditingController(text: e?.description ?? '');
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amount.text);
    final month = widget.expense?.month ?? widget.defaultPeriod.month;
    final year = widget.expense?.year ?? widget.defaultPeriod.year;
    final service = FinanceService.instance;

    await _run(() => _editing
        ? service.updateExpense(
            widget.expense!.id,
            category: _category,
            amount: amount,
            month: month,
            year: year,
            description: _note.text,
          )
        : service.createExpense(
            category: _category,
            amount: amount,
            month: month,
            year: year,
            description: _note.text,
          ));
  }

  Future<void> _delete() async {
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
              child: Icon(Icons.delete_outline_rounded, color: Theme.of(ctx).colorScheme.error, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Hapus Pengeluaran?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        content: Text(
          '${widget.expense!.category.label} sebesar '
          '${CurrencyFormatter.format(widget.expense!.amount)} akan dihapus dari catatan keuangan.',
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
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _run(() => FinanceService.instance.deleteExpense(widget.expense!.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Gap.lg,
        0,
        Gap.lg,
        Gap.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_editing ? 'Ubah pengeluaran' : 'Pengeluaran baru',
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: Gap.lg),
              Wrap(
                spacing: Gap.sm,
                runSpacing: Gap.sm,
                children: [
                  for (final c in ExpenseCategory.values)
                    ChoiceChip(
                      label: Text(c.label),
                      selected: _category == c,
                      onSelected: _busy ? null : (_) => setState(() => _category = c),
                    ),
                ],
              ),
              const SizedBox(height: Gap.lg),
              TextFormField(
                controller: _amount,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Jumlah', prefixText: 'Rp '),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null) return 'Isi jumlah pengeluaran';
                  if (n <= 0) return 'Jumlah harus lebih dari 0';
                  return null;
                },
              ),
              const SizedBox(height: Gap.md),
              TextFormField(
                controller: _note,
                enabled: !_busy,
                maxLines: 2,
                maxLength: 1000,
                decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
              ),
              if (_error != null) ...[
                const SizedBox(height: Gap.sm),
                Text(_error!, style: TextStyle(color: p.danger)),
              ],
              const SizedBox(height: Gap.lg),
              ElevatedButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan'),
              ),
              if (_editing) ...[
                const SizedBox(height: Gap.sm),
                TextButton(
                  onPressed: _busy ? null : _delete,
                  style: TextButton.styleFrom(foregroundColor: p.danger),
                  child: const Text('Hapus'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
