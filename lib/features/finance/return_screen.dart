import 'package:flutter/material.dart';
import '../../core/design/components.dart';
import '../../core/design/tokens.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/currency_formatter.dart';
import 'finance_service.dart';

class ReturnScreen extends StatefulWidget {
  const ReturnScreen({super.key});

  @override
  State<ReturnScreen> createState() => _ReturnScreenState();
}

class _ReturnScreenState extends State<ReturnScreen> {
  final _invoice = TextEditingController();
  final _notes = TextEditingController();

  ReturnableOrder? _order;
  final Map<int, double> _qty = {};
  bool _searching = false;
  bool _submitting = false;
  bool _notFound = false;
  String? _error;

  @override
  void dispose() {
    _invoice.dispose();
    _notes.dispose();
    super.dispose();
  }

  double get _refundEstimate {
    final order = _order;
    if (order == null) return 0;
    return order.items.fold(
      0.0,
      (sum, i) => sum + i.unitPrice * (_qty[i.id] ?? 0),
    );
  }

  bool get _hasSelection => _qty.values.any((q) => q > 0);

  Future<void> _search() async {
    final number = _invoice.text.trim();
    if (number.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _searching = true;
      _error = null;
      _notFound = false;
      _order = null;
      _qty.clear();
    });
    try {
      final order = await FinanceService.instance.findOrder(number);
      if (!mounted) return;
      setState(() {
        _order = order;
        _notFound = order == null;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiException.from(e).message;
        _searching = false;
      });
    }
  }

  void _change(ReturnItem item, double delta) {
    final next = ((_qty[item.id] ?? 0) + delta).clamp(0, item.quantity).toDouble();
    setState(() => _qty[item.id] = next);
  }

  Future<void> _submit() async {
    final order = _order!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.assignment_return_outlined, color: Theme.of(ctx).colorScheme.primary, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Proses Retur?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        content: Text(
          'Invoice ${order.invoiceNo}\n'
          'Perkiraan pengembalian: ${CurrencyFormatter.format(_refundEstimate)}\n'
          'Stok akan dikembalikan dan tindakan ini tidak dapat dibatalkan.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Proses Retur'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await FinanceService.instance.submitReturn(
        invoiceNo: order.invoiceNo,
        quantities: _qty,
        notes: _notes.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Retur ${order.invoiceNo} berhasil diproses')),
      );
      setState(() {
        _order = null;
        _qty.clear();
        _submitting = false;
        _invoice.clear();
        _notes.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiException.from(e).message;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final order = _order;

    return Scaffold(
      appBar: AppBar(title: const Text('Retur penjualan')),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          TextField(
            controller: _invoice,
            enabled: !_submitting,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: 'Nomor invoice',
              prefixIcon: const Icon(Icons.receipt_long_outlined),
              suffixIcon: IconButton(
                tooltip: 'Cari',
                onPressed: _searching || _submitting ? null : _search,
                icon: const Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: Gap.lg),
          if (_searching)
            const Padding(
              padding: EdgeInsets.all(Gap.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_notFound)
            const EmptyState(
              icon: Icons.search_off,
              title: 'Invoice tidak ditemukan',
              message: 'Periksa kembali nomor invoice yang dimasukkan.',
            ),
          if (order != null) ..._orderSection(context, order),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: Gap.md),
              child: Text(_error!, style: TextStyle(color: p.danger)),
            ),
        ],
      ),
    );
  }

  List<Widget> _orderSection(BuildContext context, ReturnableOrder order) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return [
      AppCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.invoiceNo,
                      style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                  Text('Total ${CurrencyFormatter.format(order.grandTotal)}',
                      style: text.bodySmall?.copyWith(color: p.textSecondary)),
                ],
              ),
            ),
            if (order.status.isNotEmpty) StatusChip(label: order.status),
          ],
        ),
      ),
      const SizedBox(height: Gap.lg),
      const SectionHeader(title: 'Pilih item yang diretur'),
      if (order.items.isEmpty)
        const EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Transaksi tanpa item',
        ),
      for (final item in order.items) ...[
        _ItemRow(
          item: item,
          quantity: _qty[item.id] ?? 0,
          enabled: !_submitting,
          onChange: (d) => _change(item, d),
        ),
        const SizedBox(height: Gap.sm),
      ],
      const SizedBox(height: Gap.md),
      TextField(
        controller: _notes,
        enabled: !_submitting,
        maxLines: 2,
        decoration: const InputDecoration(labelText: 'Alasan retur (opsional)'),
      ),
      const SizedBox(height: Gap.lg),
      Row(
        children: [
          Expanded(
            child: Text('Perkiraan pengembalian',
                style: text.bodyMedium?.copyWith(color: p.textSecondary)),
          ),
          Text(CurrencyFormatter.format(_refundEstimate),
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
      const SizedBox(height: Gap.md),
      ElevatedButton(
        onPressed: _hasSelection && !_submitting ? _submit : null,
        child: _submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Proses retur'),
      ),
    ];
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.quantity,
    required this.enabled,
    required this.onChange,
  });

  final ReturnItem item;
  final double quantity;
  final bool enabled;
  final ValueChanged<double> onChange;

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final unit = item.unitName.isEmpty ? '' : ' ${item.unitName}';

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  '${CurrencyFormatter.format(item.unitPrice)} · dibeli ${_fmt(item.quantity)}$unit',
                  style: text.bodySmall?.copyWith(color: p.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Kurangi',
            onPressed: enabled && quantity > 0 ? () => onChange(-1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 32,
            child: Text(_fmt(quantity),
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          IconButton(
            tooltip: 'Tambah',
            onPressed: enabled && quantity < item.quantity ? () => onChange(1) : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}
