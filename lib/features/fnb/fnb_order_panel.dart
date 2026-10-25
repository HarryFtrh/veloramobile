import 'package:flutter/material.dart';

import '../../core/design/tokens.dart';
import '../../core/utils/safe_json.dart';
import 'fnb_customer_picker_sheet.dart';
import 'fnb_register_controller.dart';
import 'order_panel/widgets/fnb_cart_bar.dart';
import 'order_panel/widgets/order_header_bar.dart';
import 'order_panel/widgets/order_line_item.dart';
import 'order_panel/widgets/order_summary_footer.dart';

export 'order_panel/widgets/fnb_cart_bar.dart';
export 'order_panel/widgets/order_line_item.dart' show QtyButton, EditNoteDialog, OrderLineItem;
export 'order_panel/widgets/order_summary_footer.dart' show SummaryRow, OrderSummaryFooter;
export 'order_panel/widgets/promo_voucher_sheet.dart' show PromoAndVoucherSheet;

/// Cashier side order panel for reviewing items, managing discounts/promotions,
/// selecting order type & customer, and initiating payment.
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
      builder: (ctx) => EditNoteDialog(initialNote: l.note, itemName: l.name),
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
            // Order Panel Title Row
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
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: WarmPalette.secondary,
                        ),
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
                      child: const Text(
                        'Reset',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: WarmPalette.danger),
                      ),
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

            // Existing Kitchen Ticket Notice
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

            // Order Type & Customer Ribbon
            OrderHeaderBar(
              ctrl: ctrl,
              onPickTable: onPickTable,
              onEditCustomer: () => _editCustomer(context),
              horizontalPadding: horizontalPadding,
            ),
            const SizedBox(height: Gap.xs),

            // Order Lines List or Empty State
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
                            Text(
                              'Belum ada pesanan',
                              style: text.bodyMedium?.copyWith(color: p.textSecondary, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: Gap.xs),
                            Text(
                              'Pilih menu di sebelah kiri untuk menambah',
                              style: text.bodySmall?.copyWith(color: p.textTertiary, fontSize: 11),
                            ),
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
                        return OrderLineItem(
                          line: l,
                          onRemove: () => ctrl.remove(l),
                          onIncrement: () => ctrl.increment(l),
                          onDecrement: () => ctrl.decrement(l),
                          onEditNote: () => _editNote(context, l),
                        );
                      },
                    ),
            ),

            // Summary & Checkout Actions Footer
            OrderSummaryFooter(
              ctrl: ctrl,
              canSubmit: canSubmit,
              dineInNeedsTable: dineInNeedsTable,
              horizontalPadding: horizontalPadding,
              onHold: onHold,
              onKitchen: onKitchen,
              onSplitBill: onSplitBill,
              onPay: onPay,
              onPickTable: onPickTable,
            ),
          ],
        );
      },
    );
  }
}
