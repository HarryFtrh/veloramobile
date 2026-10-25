import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../fnb_register_controller.dart';
import 'promo_voucher_sheet.dart';

/// Single row item in the financial breakdown summary.
class SummaryRow extends StatelessWidget {
  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.showInfo = false,
  });

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
                    style: text.bodyMedium?.copyWith(
                      color: context.palette.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showInfo) ...[
                  const SizedBox(width: 4),
                  Tooltip(
                    message: 'Pajak Daerah Restoran (PB1)',
                    child: Icon(
                      Icons.help_outline_rounded,
                      size: 13,
                      color: context.palette.textTertiary,
                    ),
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

/// Bottom summary footer of the FnB order panel: discounts, taxes, grand total,
/// hold/save button, and checkout payment button.
class OrderSummaryFooter extends StatelessWidget {
  const OrderSummaryFooter({
    super.key,
    required this.ctrl,
    required this.canSubmit,
    required this.dineInNeedsTable,
    required this.horizontalPadding,
    this.onHold,
    required this.onKitchen,
    this.onSplitBill,
    required this.onPay,
    required this.onPickTable,
  });

  final RegisterController ctrl;
  final bool canSubmit;
  final bool dineInNeedsTable;
  final double horizontalPadding;
  final VoidCallback? onHold;
  final VoidCallback onKitchen;
  final VoidCallback? onSplitBill;
  final VoidCallback onPay;
  final VoidCallback onPickTable;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isMobile = context.isMobile;
    final bill = ctrl.bill;

    return Container(
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
                      child: PromoAndVoucherSheet(ctrl: ctrl),
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
          // Secondary actions: [Simpan ke Meja / Hold Antrean] + [Split Bill]
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
    );
  }
}
