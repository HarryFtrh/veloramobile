// features/fnb/fnb_payment_split_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/design/tokens.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/safe_json.dart';
import '../shared_pos/sales_history_drawer.dart';
import '../tables/table_service.dart';
import 'billing.dart';
import 'fnb_register_service.dart';
import 'split_bill/cubit/payment_split_cubit.dart';
import 'split_bill/cubit/payment_split_state.dart';
import 'split_bill/widgets/split_bill_left_pane.dart';
import 'split_bill/widgets/split_bill_payment_pane.dart';
import 'split_bill/widgets/split_bill_success_dialog.dart';

export 'split_bill/cubit/payment_split_cubit.dart';
export 'split_bill/cubit/payment_split_state.dart';

class FnbPaymentSplitScreen extends StatefulWidget {
  const FnbPaymentSplitScreen({
    super.key,
    this.orderId,
    this.tableId,
    this.tableNumber = 'Meja Kasir',
    this.guestCount = 1,
    this.waiterName,
    this.customerName,
    this.totalAmount = 0,
    this.lines,
    this.bill,
    this.activeOrder,
    this.shiftId,
    this.onPaymentComplete,
    this.tableName,
  });

  final String? orderId;
  final String? tableId;
  final String tableNumber;
  final int guestCount;
  final String? waiterName;
  final String? customerName;
  final int totalAmount;
  final List<RegisterLine>? lines;
  final BillBreakdown? bill;
  final ActiveTableOrder? activeOrder;
  final int? shiftId;
  final VoidCallback? onPaymentComplete;
  final String? tableName;

  @override
  State<FnbPaymentSplitScreen> createState() => _FnbPaymentSplitScreenState();
}

class _FnbPaymentSplitScreenState extends State<FnbPaymentSplitScreen> {
  late final PaymentSplitCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = PaymentSplitCubit(
      lines: widget.lines,
      bill: widget.bill,
      tableId: widget.tableId,
      totalAmount: widget.totalAmount,
    );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSplitState state) {
    final receiptData = state.successReceipt;
    if (receiptData == null) return;

    SalesHistoryDrawer.addRecord(
      CompletedSaleRecord(
        invoiceNumber: receiptData.orderNumber,
        time: receiptData.timestamp,
        total: receiptData.total.round(),
        paymentMethod: receiptData.paymentMethod,
        tableOrCustomer: widget.tableNumber,
        items: List.from(receiptData.items),
      ),
    );

    // Calculate remaining items if this is split bill
    final remainingItems = <Map<String, dynamic>>[];
    if (state.isSplitBill && state.splitMode == 'item') {
      for (final item in state.billItems) {
        final isChecked = item['checked'] == true;
        if (!isChecked) {
          remainingItems.add(item);
        } else {
          final totalQty = (item['qty'] as num?)?.toInt() ?? 1;
          final paidQty = (item['payQty'] as num?)?.toInt() ?? totalQty;
          if (paidQty < totalQty) {
            final leftQty = totalQty - paidQty;
            final updatedItem = Map<String, dynamic>.from(item);
            updatedItem['qty'] = leftQty;
            updatedItem['payQty'] = leftQty;
            updatedItem['checked'] = true;
            remainingItems.add(updatedItem);
          }
        }
      }
    }

    final bool hasRemainingSplit = state.isSplitBill &&
        ((state.splitMode == 'item' && remainingItems.isNotEmpty) ||
            (state.splitMode == 'equal' && state.paxToPay < state.paxCount));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SplitBillSuccessDialog(
        hasRemainingSplit: hasRemainingSplit,
        invoiceNumber: receiptData.orderNumber,
        selectedMethod: state.selectedMethod,
        selectedItemsTotal: state.calculateSelectedItemsTotal(widget.totalAmount),
        changeAmount: state.successChange,
        splitMode: state.splitMode,
        remainingItemsCount: remainingItems.length,
        paxToPay: state.paxToPay,
        paxCount: state.paxCount,
        receiptData: receiptData,
        onContinueSplit: () {
          _cubit.resetCheckoutSuccess();
          if (state.splitMode == 'item') {
            _cubit.continueItemSplit(remainingItems);
          } else {
            _cubit.continuePaxSplit();
          }
        },
        onDone: () {
          if (widget.onPaymentComplete != null) {
            widget.onPaymentComplete!();
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 860;
    final displayName = widget.tableName ?? widget.tableNumber;

    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<PaymentSplitCubit, PaymentSplitState>(
        listenWhen: (prev, curr) =>
            curr.checkoutSuccess && !prev.checkoutSuccess ||
            curr.error != null && curr.error != prev.error,
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: WarmPalette.danger,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          if (state.checkoutSuccess) {
            _handlePaymentSuccess(state);
          }
        },
        builder: (context, state) {
          final totalBillAmount = state.calculateTotalBill(widget.totalAmount);
          final selectedItemsTotal =
              state.calculateSelectedItemsTotal(widget.totalAmount);
          final isPaymentSufficient =
              state.isPaymentSufficient(widget.totalAmount);
          final changeAmount =
              state.calculateChangeAmount(widget.totalAmount);

          final leftPane = SplitBillLeftPane(
            isSplitBill: state.isSplitBill,
            onToggleSplitBill: (val) =>
                _cubit.setSplitBill(val, widget.totalAmount),
            splitMode: state.splitMode,
            onSelectSplitMode: (mode) =>
                _cubit.setSplitMode(mode, widget.totalAmount),
            paxCount: state.paxCount,
            onPaxCountChanged: (count) =>
                _cubit.setPaxCount(count, widget.totalAmount),
            paxToPay: state.paxToPay,
            onPaxToPayChanged: (toPay) =>
                _cubit.setPaxToPay(toPay, widget.totalAmount),
            totalBillAmount: totalBillAmount,
            selectedItemsTotal: selectedItemsTotal,
            billItems: state.billItems,
            onItemCheckToggled: (i) => _cubit.toggleItemChecked(
                i, !(state.billItems[i]['checked'] == true), widget.totalAmount),
            onItemCheckChanged: (i, v) =>
                _cubit.toggleItemChecked(i, v, widget.totalAmount),
            onItemPayQtyChanged: (i, q) =>
                _cubit.updateItemPayQty(i, q, widget.totalAmount),
            onSelectAllItems: () {
              for (int i = 0; i < state.billItems.length; i++) {
                _cubit.toggleItemChecked(i, true, widget.totalAmount);
              }
            },
            onDeselectAllItems: () {
              for (int i = 0; i < state.billItems.length; i++) {
                _cubit.toggleItemChecked(i, false, widget.totalAmount);
              }
            },
            billingSettings: state.billingSettings,
          );

          final rightPane = SplitBillPaymentPane(
            selectedMethod: state.selectedMethod,
            onSelectMethod: (method) {
              _cubit.selectMethod(method);
              if (method == 'qris' &&
                  state.qrisInvoice == null &&
                  !state.generatingQris) {
                _cubit.loadDynamicQris(
                  amount: selectedItemsTotal,
                  orderId: widget.orderId,
                  tableName: displayName,
                );
              }
            },
            selectedItemsTotal: selectedItemsTotal,
            cashReceived: state.cashReceived,
            onSelectPreset: (preset) => _cubit.setPreset(preset),
            isPaymentSufficient: isPaymentSufficient,
            changeAmount: changeAmount,
            submitting: state.submitting,
            onFinishPayment: () {
              if (state.selectedMethod == 'qris') {
                _cubit.verifyQrisStatus(
                  fallbackTotal: widget.totalAmount,
                  orderId: widget.orderId,
                  tableId: widget.tableId,
                  customerName: widget.customerName,
                  shiftId: widget.shiftId,
                  linesFallback: widget.lines,
                  tableName: displayName,
                );
              } else {
                _cubit.checkout(
                  fallbackTotal: widget.totalAmount,
                  orderId: widget.orderId,
                  tableId: widget.tableId,
                  customerName: widget.customerName,
                  shiftId: widget.shiftId,
                  linesFallback: widget.lines,
                  tableName: displayName,
                );
              }
            },
            qrisInvoice: state.qrisInvoice,
            generatingQris: state.generatingQris,
            checkingQrisStatus: state.checkingQrisStatus,
            onVerifyQrisStatus: () => _cubit.verifyQrisStatus(
              fallbackTotal: widget.totalAmount,
              orderId: widget.orderId,
              tableId: widget.tableId,
              customerName: widget.customerName,
              shiftId: widget.shiftId,
              linesFallback: widget.lines,
              tableName: displayName,
            ),
            onNumpadDigit: (d) => _cubit.onNumpadDigit(d),
            onNumpadClear: () => _cubit.onNumpadClear(),
            onNumpadBackspace: () => _cubit.onNumpadBackspace(),
          );

          return Scaffold(
            backgroundColor: WarmPalette.canvas,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: WarmPalette.textPrimary,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: WarmPalette.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.payments_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.orderId != null
                              ? 'Pesanan ${widget.orderId}'
                              : 'Pembayaran ${sanitizeDisplayName(displayName)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: WarmPalette.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${sanitizeDisplayName(displayName)} • Kasir: ${widget.waiterName ?? SessionStorage.instance.getUserName() ?? "Kasir"}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: WarmPalette.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: isWide
                  ? [
                      Container(
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: WarmPalette.surfaceMuted,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'TOTAL TAGIHAN SAAT INI',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: WarmPalette.textSecondary,
                              ),
                            ),
                            Text(
                              'Rp ${totalBillAmount.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: WarmPalette.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                  : null,
            ),
            body: state.loading
                ? const Center(
                    child: CircularProgressIndicator(color: WarmPalette.primary),
                  )
                : isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: leftPane,
                            ),
                          ),
                          const VerticalDivider(
                              width: 1, color: WarmPalette.line),
                          Expanded(
                            flex: 6,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: rightPane,
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            leftPane,
                            const SizedBox(height: 20),
                            rightPane,
                          ],
                        ),
                      ),
          );
        },
      ),
    );
  }
}
