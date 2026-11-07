import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/design/tokens.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../auth/auth_service.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../customer_service.dart';

/// Modal bottom sheet for viewing debt details, settling with payment method, or writing off
class CustomerDebtSheet extends StatefulWidget {
  final Debt debt;

  const CustomerDebtSheet({
    super.key,
    required this.debt,
  });

  @override
  State<CustomerDebtSheet> createState() => _CustomerDebtSheetState();
}

class _CustomerDebtSheetState extends State<CustomerDebtSheet> {
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
