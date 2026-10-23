import 'package:flutter/material.dart';
import '../../core/design/components.dart';
import '../../core/design/tokens.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/safe_json.dart';
import 'billing.dart';
import 'fnb_customer_picker_sheet.dart';
import 'fnb_register_controller.dart';

class FnbCartBar extends StatelessWidget {
  const FnbCartBar({super.key, required this.ctrl, required this.onOpen});
  final RegisterController ctrl;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final total = ctrl.bill?.total ?? ctrl.subtotal;
        return SafeArea(
          top: false,
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Gap.md, 4, Gap.md, 6),
            child: Material(
              color: scheme.primary,
              elevation: 6,
              shadowColor: scheme.primary.withValues(alpha: 0.35),
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onOpen,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.shopping_bag_outlined, color: scheme.onPrimary, size: 18),
                      ),
                      const SizedBox(width: Gap.sm),
                      Text('${ctrl.itemCount} Item',
                          style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                      const Spacer(),
                      Text(CurrencyFormatter.format(total),
                          style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(width: Gap.xs),
                      Icon(Icons.keyboard_arrow_up, color: scheme.onPrimary),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EditNoteDialog extends StatefulWidget {
  const _EditNoteDialog({required this.initialNote, required this.itemName});
  final String? initialNote;
  final String itemName;

  @override
  State<_EditNoteDialog> createState() => _EditNoteDialogState();
}

class _EditNoteDialogState extends State<_EditNoteDialog> {
  late final TextEditingController _c;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.palette.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.sticky_note_2_outlined, color: context.palette.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Catatan ${widget.itemName}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: TextField(
          controller: _c,
          autofocus: true,
          maxLength: 120,
          decoration: InputDecoration(
            hintText: 'Mis. Less ice, no sugar, dipisah',
            filled: true,
            fillColor: context.palette.surfaceMuted,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.palette.line)),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(context, _c.text), child: const Text('Simpan Catatan')),
      ],
    );
  }
}



class FnbOrderPanel extends StatelessWidget {
  const FnbOrderPanel({
    super.key,
    required this.ctrl,
    required this.onPickTable,
    required this.onKitchen,
    required this.onPay,
    this.onHold,
    this.onOpenBills,
    this.onSplitBill,
    this.isModal = false,
  });

  final RegisterController ctrl;
  final VoidCallback onPickTable;
  final VoidCallback onKitchen;
  final VoidCallback onPay;
  final VoidCallback? onHold;
  final VoidCallback? onOpenBills;
  final VoidCallback? onSplitBill;
  final bool isModal;

  Future<void> _editNote(BuildContext context, RegisterLine l) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _EditNoteDialog(initialNote: l.note, itemName: l.name),
    );
    if (result != null) ctrl.setNote(l, result);
  }

  Future<void> _editCustomer(BuildContext context) async {
    final result = await FnbCustomerPickerSheet.show(
      context,
      currentName: ctrl.customerName,
      currentTier: ctrl.memberTier,
      currentDiscount: ctrl.memberDiscountPercent,
    );
    if (result != null) {
      if (result.isGeneralCustomer) {
        ctrl.setMember('', tier: null, discountPercent: 0);
      } else {
        ctrl.setMember(
          result.name,
          tier: result.tier,
          discountPercent: result.discountPercent,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        final p = context.palette;
        final text = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;
        final bill = ctrl.bill;
        final canSubmit = ctrl.lines.isNotEmpty && !ctrl.busy;
        final dineInNeedsTable = ctrl.orderType == OrderType.dineIn && ctrl.table == null;
        final isMobile = context.isMobile;
        final horizontalPadding = isMobile ? 12.0 : 16.0;

        return Column(
          children: [
            if (isModal) ...[
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: WarmPalette.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                isModal ? 2 : Gap.md,
                isModal ? 4 : horizontalPadding,
                Gap.xs,
              ),
              child: Row(
                children: [
                  Text(
                    'Pesanan Aktif',
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: isMobile ? 17 : 20,
                    ),
                  ),
                  if (ctrl.activeOrderId != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: WarmPalette.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#${ctrl.activeOrderId}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: WarmPalette.secondary),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (onSplitBill != null && ctrl.lines.isNotEmpty)
                    IconButton(
                      tooltip: 'Split Bill',
                      icon: const Icon(Icons.call_split_rounded, size: 19, color: WarmPalette.primary),
                      onPressed: onSplitBill,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  if (ctrl.lines.isNotEmpty)
                    TextButton(
                      onPressed: ctrl.reset,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      child: const Text('Reset', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: WarmPalette.danger)),
                    ),
                  if (isModal)
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: p.textSecondary, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Tutup',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                ],
              ),
            ),
            if (ctrl.existingOrderId != null)
              Padding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, Gap.xs),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.xs + 2),
                  decoration: BoxDecoration(
                    color: p.surfaceMuted,
                    borderRadius: Corner.medium,
                    border: Border.all(color: p.warning),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.soup_kitchen_rounded, size: 16, color: p.warning),
                      const SizedBox(width: Gap.xs),
                      Expanded(
                        child: Text(
                          'Memuat Tiket #${ctrl.existingOrderId}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: p.primary,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: ctrl.reset,
                        child: Text(
                          'Batal',
                          style: TextStyle(fontSize: 11, color: p.danger, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<OrderType>(
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return WarmPalette.primary;
                      }
                      return Colors.white;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return WarmPalette.textPrimary;
                    }),
                    side: WidgetStateProperty.all(const BorderSide(color: WarmPalette.line)),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  segments: [
                    ButtonSegment(
                      value: OrderType.dineIn,
                      icon: const Icon(Icons.restaurant, size: 15),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          ctrl.table == null ? 'Dine-In' : 'Dine-In (${sanitizeDisplayName(ctrl.table!.name)})',
                          maxLines: 1,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const ButtonSegment(
                      value: OrderType.takeaway,
                      icon: Icon(Icons.shopping_bag_outlined, size: 15),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Takeaway', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const ButtonSegment(
                      value: OrderType.online,
                      icon: Icon(Icons.delivery_dining_rounded, size: 15),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Online', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                  selected: {ctrl.orderType},
                  onSelectionChanged: (s) {
                    final newType = s.first;
                    Future.microtask(() {
                      ctrl.setOrderType(newType);
                      if (newType == OrderType.dineIn && ctrl.table == null) {
                        onPickTable();
                      }
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: Gap.xs + 2),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: WarmPalette.line),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _editCustomer(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: ctrl.memberTier != null
                                    ? const Color(0xFFFEF3C7)
                                    : (ctrl.customerName.isNotEmpty
                                        ? const Color(0xFFE0E7FF)
                                        : WarmPalette.surfaceMuted),
                                child: Icon(
                                  ctrl.memberTier != null
                                      ? Icons.stars_rounded
                                      : (ctrl.customerName.isNotEmpty ? Icons.person_rounded : Icons.person_outline_rounded),
                                  size: 17,
                                  color: ctrl.memberTier != null
                                      ? const Color(0xFFD97706)
                                      : (ctrl.customerName.isNotEmpty ? const Color(0xFF4338CA) : WarmPalette.textSecondary),
                                ),
                              ),
                              const SizedBox(width: Gap.xs + 2),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      ctrl.customerName.isEmpty ? 'Pelanggan Umum' : sanitizeDisplayName(ctrl.customerName),
                                      style: text.bodyMedium?.copyWith(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: ctrl.customerName.isNotEmpty ? WarmPalette.textPrimary : WarmPalette.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (ctrl.memberTier != null)
                                      Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${ctrl.memberTier!.toUpperCase()} • ${ctrl.memberDiscountPercent.round()}% OFF',
                                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (ctrl.customerName.isNotEmpty) ...[
                                Tooltip(
                                  message: 'Kembali ke Pelanggan Umum',
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      ctrl.setMember('', tier: null, discountPercent: 0);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      margin: const EdgeInsets.only(right: 4),
                                      decoration: const BoxDecoration(
                                        color: WarmPalette.surfaceMuted,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close_rounded, size: 14, color: WarmPalette.textSecondary),
                                    ),
                                  ),
                                ),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: WarmPalette.surfaceMuted,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Ganti',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF6F3512),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (ctrl.orderType == OrderType.dineIn) ...[
                      const SizedBox(width: 4),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: onPickTable,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: ctrl.table == null
                                ? const Color(0xFFFEF3C7)
                                : WarmPalette.tertiary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: ctrl.table == null
                                  ? const Color(0xFFF59E0B)
                                  : WarmPalette.tertiary.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.table_restaurant_rounded,
                                size: 13,
                                color: ctrl.table == null
                                    ? const Color(0xFFB45309)
                                    : WarmPalette.tertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ctrl.table == null ? 'Pilih Meja' : ctrl.table!.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: ctrl.table == null
                                      ? const Color(0xFFB45309)
                                      : WarmPalette.tertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: Gap.xs),
            Expanded(
              child: ctrl.lines.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 42, color: p.textTertiary),
                            const SizedBox(height: Gap.sm),
                            Text('Belum ada pesanan', style: text.bodyMedium?.copyWith(color: p.textSecondary, fontWeight: FontWeight.w600)),
                            const SizedBox(height: Gap.xs),
                            Text('Pilih menu di sebelah kiri untuk menambah', style: text.bodySmall?.copyWith(color: p.textTertiary, fontSize: 11)),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: Gap.sm),
                      itemCount: ctrl.lines.length,
                      separatorBuilder: (_, _) => const SizedBox(height: Gap.sm),
                      itemBuilder: (_, i) {
                        final l = ctrl.lines[i];
                        return AppCard(
                          padding: const EdgeInsets.all(Gap.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      sanitizeDisplayName(l.name),
                                      style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => ctrl.remove(l),
                                    child: Padding(
                                      padding: const EdgeInsets.all(2),
                                      child: Icon(Icons.close, size: 18, color: p.textTertiary),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${CurrencyFormatter.format(l.unitPrice)} / item',
                                style: text.bodySmall?.copyWith(color: p.textSecondary, fontSize: 11),
                              ),
                              if (l.options.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(color: p.surfaceMuted, borderRadius: Corner.small),
                                  child: Column(
                                    children: [
                                      for (final o in l.options)
                                        Row(
                                          children: [
                                            Expanded(child: Text('• ${sanitizeDisplayName(o.name)}', style: text.bodySmall?.copyWith(fontSize: 11))),
                                            Text(CurrencyFormatter.format(o.price),
                                                style: text.bodySmall?.copyWith(color: p.textSecondary, fontSize: 11)),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _editNote(context, l),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Text(
                                          l.note == null ? '+ Tambah catatan barista' : '“${l.note}”',
                                          style: text.bodySmall?.copyWith(
                                            fontSize: 11,
                                            color: l.note == null ? scheme.secondary : WarmPalette.secondary,
                                            fontStyle: l.note == null ? FontStyle.normal : FontStyle.italic,
                                            fontWeight: l.note == null ? FontWeight.w500 : FontWeight.w700,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (l.note != null)
                                    InkWell(
                                      onTap: () => _editNote(context, l),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 4),
                                        child: Text('Ubah', style: TextStyle(fontSize: 10, color: WarmPalette.textSecondary, fontWeight: FontWeight.w700)),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  QtyButton(icon: Icons.remove, onTap: () => ctrl.decrement(l)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: Gap.sm + 2),
                                    child: Text('${l.quantity}', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 13)),
                                  ),
                                  QtyButton(icon: Icons.add, onTap: () => ctrl.increment(l)),
                                  const Spacer(),
                                  Text(
                                    CurrencyFormatter.format(l.subtotal),
                                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                Gap.xs + 2,
                horizontalPadding,
                Gap.sm + MediaQuery.paddingOf(context).bottom + MediaQuery.viewInsetsOf(context).bottom,
              ),
              decoration: BoxDecoration(
                color: p.surface,
                border: Border(top: BorderSide(color: p.line)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Voucher banner if applied, or button to apply
                  if (ctrl.activeVoucherCode != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: WarmPalette.tertiary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: WarmPalette.tertiary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 14, color: WarmPalette.tertiary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Voucher ${ctrl.activeVoucherCode!} Diterapkan',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: WarmPalette.tertiary),
                            ),
                          ),
                          InkWell(
                            onTap: ctrl.removeVoucher,
                            child: const Text('Hapus', style: TextStyle(fontSize: 11, color: WarmPalette.danger, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    )
                  else if (ctrl.lines.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            backgroundColor: context.palette.surface,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (ctx) => ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isMobile ? double.infinity : 540,
                                maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
                              ),
                              child: _PromoAndVoucherSheet(ctrl: ctrl),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.discount_outlined, size: 13, color: scheme.primary),
                            const SizedBox(width: 4),
                            Text('Diskon / Promosi Toko', style: TextStyle(fontSize: 11, color: scheme.primary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  SummaryRow(label: 'Subtotal (${ctrl.itemCount} item)', value: CurrencyFormatter.format(ctrl.subtotal)),
                  if (ctrl.memberDiscountAmount > 0)
                    SummaryRow(
                      label: 'Diskon Member (${ctrl.memberDiscountPercent.round()}%)',
                      value: '-${CurrencyFormatter.format(ctrl.memberDiscountAmount)}',
                    ),
                  if (ctrl.promoDiscountAmount > 0)
                    SummaryRow(
                      label: ctrl.activePromotion != null
                          ? 'Promo: ${ctrl.activePromotion!.name}'
                          : (ctrl.activeVoucherCode != null
                              ? 'Diskon (${ctrl.activeVoucherCode})'
                              : 'Diskon'),
                      value: '-${CurrencyFormatter.format(ctrl.promoDiscountAmount)}',
                    ),
                  if (bill != null && bill.serviceCharge > 0)
                    SummaryRow(label: 'Biaya Layanan', value: CurrencyFormatter.format(bill.serviceCharge)),
                  if (bill != null && bill.tax > 0)
                    SummaryRow(
                      label: ctrl.billing != null && ctrl.billing!.pb1Rate > 0
                          ? '${ctrl.billing!.taxName} (${(ctrl.billing!.pb1Rate > 1 ? ctrl.billing!.pb1Rate : ctrl.billing!.pb1Rate * 100).round()}%)'
                          : (ctrl.billing?.taxName ?? 'Pajak Resto'),
                      value: CurrencyFormatter.format(bill.tax),
                      showInfo: true,
                    ),
                  if (bill != null && bill.rounding != 0)
                    SummaryRow(label: 'Pembulatan Sistem', value: CurrencyFormatter.format(bill.rounding)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Tagihan',
                              style: text.bodyMedium?.copyWith(color: p.textPrimary, fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                            Text(
                              'Termasuk PB1 & Layanan',
                              style: TextStyle(color: p.textSecondary, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(bill?.total ?? ctrl.subtotal),
                        style: text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: WarmPalette.textPrimary,
                          fontSize: isMobile ? 18 : 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Row Aksi Sekunder: [Simpan / Hold Antrean atau Simpan ke Meja]
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: canSubmit && !ctrl.busy
                              ? (onHold ?? onKitchen)
                              : null,
                          icon: Icon(
                            ctrl.table != null ? Icons.table_restaurant_rounded : Icons.pause_presentation_rounded,
                            size: 15,
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              ctrl.table != null
                                  ? 'Simpan ke Meja ${ctrl.table!.name}'
                                  : 'Simpan / Hold Antrean',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: WarmPalette.primary,
                            side: const BorderSide(color: WarmPalette.line),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                          ),
                        ),
                      ),
                      if (onSplitBill != null && ctrl.lines.length > 1) ...[
                        const SizedBox(width: Gap.xs + 2),
                        OutlinedButton.icon(
                          onPressed: canSubmit && !ctrl.busy ? onSplitBill : null,
                          icon: const Icon(Icons.call_split_rounded, size: 15),
                          label: const Text('Split Bill', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: WarmPalette.textSecondary,
                            side: const BorderSide(color: WarmPalette.line),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Full-width Pay button for touchscreen
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton(
                      onPressed: canSubmit
                          ? () {
                              if (dineInNeedsTable) {
                                onPickTable();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Pilih meja terlebih dahulu untuk pesanan Dine-In')),
                                );
                              } else {
                                onPay();
                              }
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: WarmPalette.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.point_of_sale_rounded, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Bayar Sekarang',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          const Spacer(),
                          Text(
                            CurrencyFormatter.format(bill?.total ?? ctrl.subtotal),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'F12',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (dineInNeedsTable)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Pilih meja untuk pesanan Dine-In',
                        style: text.bodySmall?.copyWith(color: p.warning, fontWeight: FontWeight.w700, fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class QtyButton extends StatelessWidget {
  const QtyButton({super.key, required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: context.palette.line)),
          child: Icon(icon, size: 18),
        ),
      );
}

class SummaryRow extends StatelessWidget {
  const SummaryRow({super.key, required this.label, required this.value, this.showInfo = false});
  final String label;
  final String value;
  final bool showInfo;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: text.bodyMedium?.copyWith(color: context.palette.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showInfo) ...[
                  const SizedBox(width: 4),
                  Tooltip(
                    message: 'Pajak Daerah Restoran (PB1)',
                    child: Icon(Icons.help_outline_rounded, size: 13, color: context.palette.textTertiary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PromoAndVoucherSheet extends StatefulWidget {
  const _PromoAndVoucherSheet({required this.ctrl});
  final RegisterController ctrl;

  @override
  State<_PromoAndVoucherSheet> createState() => _PromoAndVoucherSheetState();
}

class _PromoAndVoucherSheetState extends State<_PromoAndVoucherSheet> {
  final _codeCtrl = TextEditingController();
  final _customAmountCtrl = TextEditingController();
  final _customPercentCtrl = TextEditingController();
  String? _errorMsg;
  bool _showCustom = false;
  bool _isVerifying = false;
  bool _isLoadingPromos = false;

  @override
  void initState() {
    super.initState();
    if ((widget.ctrl.billing?.activePromotions.isEmpty ?? true)) {
      _loadDiscounts();
    }
  }

  Future<void> _loadDiscounts() async {
    setState(() {
      _isLoadingPromos = true;
      _errorMsg = null;
    });
    try {
      await widget.ctrl.refreshDiscounts();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingPromos = false);
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _customAmountCtrl.dispose();
    _customPercentCtrl.dispose();
    super.dispose();
  }

  void _applyPromo(StorePromotion promo) {
    if (promo.minOrderAmount > 0 && widget.ctrl.subtotal < promo.minOrderAmount) {
      setState(() {
        _errorMsg = 'Minimal transaksi ${CurrencyFormatter.format(promo.minOrderAmount)} untuk promo "${promo.name}"';
      });
      return;
    }
    widget.ctrl.applyPromotion(promo);
    Navigator.pop(context);
  }

  Future<void> _applyCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _isVerifying = true;
      _errorMsg = null;
    });
    try {
      final applied = await widget.ctrl.applyVoucherCode(code);
      if (applied) {
        if (mounted) Navigator.pop(context);
      } else {
        setState(() {
          _errorMsg = 'Kode voucher "$code" tidak ditemukan atau sudah tidak aktif';
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = ApiException.from(e).message;
      });
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _applyCustomNominal() {
    final amt = double.tryParse(_customAmountCtrl.text.trim()) ?? 0.0;
    if (amt <= 0) return;
    widget.ctrl.applyVoucher('MANUAL', amt);
    Navigator.pop(context);
  }

  void _applyCustomPercent() {
    final pct = double.tryParse(_customPercentCtrl.text.trim()) ?? 0.0;
    if (pct <= 0) return;
    final maxPct = widget.ctrl.billing?.maxDiscountPercent ?? 100.0;
    if (pct > maxPct) {
      setState(() {
        _errorMsg = 'Maksimal diskon kasir adalah ${maxPct.round()}%';
      });
      return;
    }
    final amt = (widget.ctrl.subtotal * (pct / 100)).toDouble();
    widget.ctrl.applyVoucher('MANUAL ${pct.round()}%', amt);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final b = widget.ctrl.billing;
    final promos = b?.activePromotions ?? const [];
    final subtotal = widget.ctrl.subtotal;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Diskon & Promosi Toko', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 18)),
                ),
                IconButton(
                  icon: _isLoadingPromos
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Tarik ulang diskon & promosi',
                  onPressed: _isLoadingPromos ? null : _loadDiscounts,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_errorMsg != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: p.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: p.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, size: 16, color: p.danger),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMsg!, style: TextStyle(color: p.danger, fontSize: 12, fontWeight: FontWeight.w600))),
                  ],
                ),
              ),

            // Input kode promo opsional
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'Kode promo toko (opsional)',
                      prefixIcon: Icon(Icons.tag_rounded, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _applyCode(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isVerifying ? null : _applyCode,
                  child: _isVerifying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Gunakan'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (_isLoadingPromos && promos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(strokeWidth: 2),
                      SizedBox(height: 10),
                      Text('Menarik data diskon & promosi dari server...', style: TextStyle(fontSize: 12, color: WarmPalette.textSecondary)),
                    ],
                  ),
                ),
              ),

            // Daftar promosi dari sistem prefensi
            if (promos.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Promosi Aktif (${promos.length})',
                    style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: p.textSecondary),
                  ),
                  if (_isLoadingPromos)
                    const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.8)),
                ],
              ),
              const SizedBox(height: 8),
              for (final promo in promos) ...[
                Builder(
                  builder: (ctx) {
                    final eligible = promo.minOrderAmount <= 0 || subtotal >= promo.minOrderAmount;
                    final discountEst = promo.calculateDiscount(subtotal);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: eligible ? p.surface : p.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: eligible ? p.primary.withValues(alpha: 0.3) : p.line,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: eligible ? p.primary.withValues(alpha: 0.1) : p.line,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              promo.type == PromotionType.percentage ? Icons.percent_rounded : Icons.discount_outlined,
                              color: eligible ? p.primary : p.textTertiary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        promo.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: eligible ? p.textPrimary : p.textSecondary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: eligible ? WarmPalette.tertiary : p.line,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        promo.type == PromotionType.percentage
                                            ? '${promo.value.round()}% OFF'
                                            : CurrencyFormatter.format(promo.value),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: eligible ? Colors.white : p.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  promo.minOrderAmount > 0
                                      ? 'Min. transaksi ${CurrencyFormatter.format(promo.minOrderAmount)}${eligible ? " • Hemat ${CurrencyFormatter.format(discountEst)}" : " (Kurang ${CurrencyFormatter.format(promo.minOrderAmount - subtotal)})"}'
                                      : 'Tanpa min. transaksi • Hemat ${CurrencyFormatter.format(discountEst)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: eligible ? p.textSecondary : p.danger,
                                    fontWeight: eligible ? FontWeight.normal : FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonal(
                            onPressed: eligible ? () => _applyPromo(promo) : null,
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            child: const Text('Pakai', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ] else ...[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: p.line),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: p.textTertiary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tidak ada promosi toko aktif saat ini. Anda tetap dapat memasukkan kode voucher atau diskon manual.',
                        style: TextStyle(fontSize: 12, color: p.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Diskon Kustom Kasir
            if (b?.allowCustomDiscount == true) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => setState(() => _showCustom = !_showCustom),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(_showCustom ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 18, color: p.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Diskon Manual Kasir (Maks. ${(b?.maxDiscountPercent ?? 100).round()}%)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showCustom) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customAmountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Potongan (Rp)',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: _applyCustomNominal,
                      child: const Text('Terapkan Rp'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customPercentCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Potongan (%)',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: _applyCustomPercent,
                      child: const Text('Terapkan %'),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
