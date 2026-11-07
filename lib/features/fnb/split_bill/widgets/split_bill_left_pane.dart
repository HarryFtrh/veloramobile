import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../../billing.dart';

class SplitBillLeftPane extends StatelessWidget {
  const SplitBillLeftPane({
    super.key,
    required this.isSplitBill,
    required this.onToggleSplitBill,
    required this.splitMode,
    required this.onSelectSplitMode,
    required this.paxCount,
    required this.onPaxCountChanged,
    required this.paxToPay,
    required this.onPaxToPayChanged,
    required this.totalBillAmount,
    required this.selectedItemsTotal,
    required this.billItems,
    required this.onItemCheckToggled,
    required this.onItemCheckChanged,
    required this.onItemPayQtyChanged,
    required this.onSelectAllItems,
    required this.onDeselectAllItems,
    required this.billingSettings,
  });

  final bool isSplitBill;
  final ValueChanged<bool> onToggleSplitBill;
  final String splitMode;
  final ValueChanged<String> onSelectSplitMode;
  final int paxCount;
  final ValueChanged<int> onPaxCountChanged;
  final int paxToPay;
  final ValueChanged<int> onPaxToPayChanged;
  final int totalBillAmount;
  final int selectedItemsTotal;
  final List<Map<String, dynamic>> billItems;
  final ValueChanged<int> onItemCheckToggled;
  final void Function(int index, bool value) onItemCheckChanged;
  final void Function(int index, int newQty) onItemPayQtyChanged;
  final VoidCallback onSelectAllItems;
  final VoidCallback onDeselectAllItems;
  final BillingSettings? billingSettings;

  Widget _buildPriceRow(BuildContext context, String label, String value) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: p.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isWide = MediaQuery.of(context).size.width >= 860;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle Bayar Penuh vs Split Bill
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: p.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onToggleSplitBill(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      color: !isSplitBill
                          ? primaryColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 16,
                          color: !isSplitBill
                              ? Colors.white
                              : p.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              isWide ? 'Bayar Penuh (Single Pay)' : 'Bayar Penuh',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: !isSplitBill
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: !isSplitBill
                                    ? Colors.white
                                    : p.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onToggleSplitBill(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSplitBill
                          ? p.secondary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.call_split_rounded,
                          size: 16,
                          color: isSplitBill
                              ? Colors.white
                              : p.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              isWide ? 'Bagi Tagihan (Split Bill)' : 'Split Bill',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSplitBill
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: isSplitBill
                                    ? Colors.white
                                    : p.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (isSplitBill) ...[
          // Sub-toggle Split Mode: Per Item vs Bagi Rata
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onSelectSplitMode('item'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: splitMode == 'item' ? p.surfaceMuted : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.checklist_rounded, size: 14, color: splitMode == 'item' ? primaryColor : p.textSecondary),
                          const SizedBox(width: 5),
                          Text(
                            'Pilih Per Item',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: splitMode == 'item' ? FontWeight.w800 : FontWeight.w600,
                              color: splitMode == 'item' ? primaryColor : p.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onSelectSplitMode('equal'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: splitMode == 'equal' ? p.surfaceMuted : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pie_chart_rounded, size: 14, color: splitMode == 'equal' ? p.secondary : p.textSecondary),
                          const SizedBox(width: 5),
                          Text(
                            'Bagi Rata (Pax)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: splitMode == 'equal' ? FontWeight.w800 : FontWeight.w600,
                              color: splitMode == 'equal' ? p.secondary : p.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Bill Content Container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSplitBill && splitMode == 'equal') ...[
                // Equal Split Control Card
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Jumlah Orang (Pax)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: paxCount > 2
                              ? () => onPaxCountChanged(paxCount - 1)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('$paxCount Orang', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                        ),
                        IconButton(
                          onPressed: paxCount < 20
                              ? () => onPaxCountChanged(paxCount + 1)
                              : null,
                          icon: Icon(Icons.add_circle_outline_rounded, size: 20, color: primaryColor),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Seluruh Tagihan', style: TextStyle(fontSize: 12, color: p.textSecondary)),
                          Text(
                            'Rp ${totalBillAmount.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Bagian per 1 Orang', style: TextStyle(fontSize: 12, color: p.textSecondary)),
                          Text(
                            'Rp ${(totalBillAmount / (paxCount > 0 ? paxCount : 1)).ceil().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: p.secondary),
                          ),
                        ],
                      ),
                      Divider(height: 16, color: p.line),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Bayar Berapa Orang Sekarang?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: paxToPay > 1
                                    ? () => onPaxToPayChanged(paxToPay - 1)
                                    : null,
                                icon: const Icon(Icons.remove, size: 16),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text('$paxToPay', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              ),
                              IconButton(
                                onPressed: paxToPay < paxCount
                                    ? () => onPaxToPayChanged(paxToPay + 1)
                                    : null,
                                icon: const Icon(Icons.add, size: 16),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ] else ...[
                // Item List Header with Quick Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Item Dipesan (${billItems.length})',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: p.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSplitBill) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: onSelectAllItems,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text('Pilih Semua', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                          Text('•', style: TextStyle(color: p.line)),
                          TextButton(
                            onPressed: onDeselectAllItems,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text('Lepas Semua', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.textSecondary)),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        'Dapur: Siap Dibayar',
                        style: TextStyle(
                          fontSize: 11,
                          color: p.tertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                for (int i = 0; i < billItems.length; i++) ...[
                  Builder(
                    builder: (context) {
                      final item = billItems[i];
                      final isChecked = item['checked'] == true;
                      final totalQty = (item['qty'] as num?)?.toInt() ?? 1;
                      final payQty = (item['payQty'] as num?)?.toInt() ?? totalQty;
                      final notes = item['notes']?.toString() ?? '';
                      final itemPrice = (item['price'] as num?) ?? 0;
                      final effectiveCount = isSplitBill ? payQty : totalQty;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isSplitBill && isChecked
                              ? primaryColor.withValues(alpha: 0.04)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: isSplitBill
                              ? () => onItemCheckToggled(i)
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isSplitBill)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Checkbox(
                                      value: isChecked,
                                      activeColor: primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      onChanged: (v) => onItemCheckChanged(i, v ?? false),
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8, top: 4),
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      size: 18,
                                      color: p.tertiary,
                                    ),
                                  ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${totalQty}x ${item['name'] ?? 'Item'}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: isSplitBill && !isChecked
                                              ? p.textSecondary
                                              : p.textPrimary,
                                        ),
                                      ),
                                      if (notes.isNotEmpty)
                                        Text(
                                          notes,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: p.textSecondary,
                                          ),
                                        ),
                                      if (isSplitBill && isChecked && totalQty > 1) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('Bayar: ', style: TextStyle(fontSize: 10.5, color: p.textSecondary)),
                                            InkWell(
                                              onTap: payQty > 1
                                                  ? () => onItemPayQtyChanged(i, payQty - 1)
                                                  : null,
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: p.surfaceMuted,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Icon(Icons.remove, size: 14, color: payQty > 1 ? p.textPrimary : p.textSecondary),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 6),
                                              child: Text('$payQty', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                                            ),
                                            InkWell(
                                              onTap: payQty < totalQty
                                                  ? () => onItemPayQtyChanged(i, payQty + 1)
                                                  : null,
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: p.surfaceMuted,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Icon(Icons.add, size: 14, color: payQty < totalQty ? p.textPrimary : p.textSecondary),
                                              ),
                                            ),
                                            Text(' dari $totalQty porsi', style: TextStyle(fontSize: 10.5, color: p.textSecondary)),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Text(
                                  'Rp ${(itemPrice * effectiveCount).round().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: isSplitBill && !isChecked
                                        ? p.textSecondary
                                        : p.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],

              Divider(color: p.line),
              const SizedBox(height: 6),
              _buildPriceRow(
                context,
                'Subtotal Item',
                'Rp ${selectedItemsTotal.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
              ),
              _buildPriceRow(
                context,
                'PB1 Pajak Resto & Servis',
                billingSettings == null
                    ? 'Termasuk'
                    : (billingSettings!.pb1Enabled
                          ? '${(billingSettings!.pb1Rate > 1 ? billingSettings!.pb1Rate : billingSettings!.pb1Rate * 100).round()}%'
                          : 'Non-aktif'),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Total Yang Harus Dibayar',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: p.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'Rp ${selectedItemsTotal.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
