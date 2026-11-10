// features/fnb/split_bill/cubit/payment_split_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../kitchen/kitchen_service.dart';
import '../../../shared_pos/pos_checkout_service.dart';
import '../../../shared_pos/qris_payment_service.dart';
import '../../../shared_pos/receipt_printer_service.dart';
import '../../billing.dart';
import '../../fnb_register_service.dart';
import '../../../tables/table_service.dart';
import 'payment_split_state.dart';

class PaymentSplitCubit extends Cubit<PaymentSplitState> {
  PaymentSplitCubit({
    List<RegisterLine>? lines,
    BillBreakdown? bill,
    String? tableId,
    ActiveTableOrder? activeOrder,
    int totalAmount = 0,
    bool initialSplitBill = false,
  }) : super(PaymentSplitState(isSplitBill: initialSplitBill)) {
    ready = initData(
      lines: lines,
      bill: bill,
      tableId: tableId,
      activeOrder: activeOrder,
      totalAmount: totalAmount,
    );
  }

  late final Future<void> ready;

  Future<void> initData({
    List<RegisterLine>? lines,
    BillBreakdown? bill,
    String? tableId,
    ActiveTableOrder? activeOrder,
    int totalAmount = 0,
  }) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final billing = await BillingSettings.fetch();
      List<Map<String, dynamic>> items = [];

      if (lines != null && lines.isNotEmpty) {
        items = lines.map((l) {
          final effectiveProdId =
              l.productId.isNotEmpty ? l.productId : l.name;
          return {
            'product_id': effectiveProdId,
            'productId': effectiveProdId,
            'name': l.name,
            'qty': l.quantity,
            'payQty': l.quantity,
            'notes': l.note ??
                (l.options.isNotEmpty
                    ? l.options.map((o) => o.name).join(', ')
                    : null),
            'price': l.unitPrice.toInt(),
            'checked': true,
            'line': l,
          };
        }).toList();
      } else {
        final effectiveOrder = activeOrder ??
            (tableId != null
                ? await TableService.instance.getActiveOrder(tableId)
                : null);
        if (effectiveOrder != null && effectiveOrder.items.isNotEmpty) {
          items = effectiveOrder.items.map((it) {
            final effectiveProdId =
                it.productId.isNotEmpty ? it.productId : it.id;
            return {
              'id': it.id,
              'product_id': effectiveProdId,
              'productId': effectiveProdId,
              'name': it.name,
              'qty': it.quantity,
              'payQty': it.quantity,
              'notes': it.notes,
              'price': it.price.toInt(),
              'checked': true,
              'line': RegisterLine(
                productId: effectiveProdId,
                name: it.name,
                price: it.price,
                quantity: it.quantity,
                note: it.notes,
                orderItemId: it.id,
              ),
            };
          }).toList();
        }
      }

      final newState = state.copyWith(
        billItems: items,
        activeBill: bill,
        billingSettings: billing,
        loading: false,
      );

      final total = newState.calculateTotalBill(totalAmount);
      final effectiveCash =
          newState.cashReceived > 0 ? newState.cashReceived : total;
      emit(newState.copyWith(
        cashReceived: effectiveCash,
        numpadBuffer: effectiveCash > 0 ? effectiveCash.toString() : '',
      ));
    } catch (_) {
      emit(state.copyWith(loading: false));
    }
  }

  void setSplitBill(bool value, int fallbackTotal) {
    emit(state.copyWith(isSplitBill: value));
    _updatePresetForCurrentSelection(fallbackTotal);
  }

  void setSplitMode(String mode, int fallbackTotal) {
    emit(state.copyWith(splitMode: mode));
    _updatePresetForCurrentSelection(fallbackTotal);
  }

  void setPaxCount(int count, int fallbackTotal) {
    final safePax = count < 2 ? 2 : (count > 20 ? 20 : count);
    final safeToPay = state.paxToPay > safePax ? safePax : state.paxToPay;
    emit(state.copyWith(paxCount: safePax, paxToPay: safeToPay));
    _updatePresetForCurrentSelection(fallbackTotal);
  }

  void setPaxToPay(int count, int fallbackTotal) {
    final safeToPay = count < 1
        ? 1
        : (count > state.paxCount ? state.paxCount : count);
    emit(state.copyWith(paxToPay: safeToPay));
    _updatePresetForCurrentSelection(fallbackTotal);
  }

  void selectMethod(String method) {
    emit(state.copyWith(selectedMethod: method));
  }

  void onNumpadDigit(String digit) {
    if (state.numpadBuffer.length >= 12) return;
    String newBuffer = state.numpadBuffer == '0' ? digit : state.numpadBuffer + digit;
    final amount = int.tryParse(newBuffer) ?? 0;
    emit(state.copyWith(numpadBuffer: newBuffer, cashReceived: amount));
  }

  void onNumpadClear() {
    emit(state.copyWith(numpadBuffer: '0', cashReceived: 0));
  }

  void onNumpadBackspace() {
    String newBuffer = state.numpadBuffer.length > 1
        ? state.numpadBuffer.substring(0, state.numpadBuffer.length - 1)
        : '0';
    final amount = int.tryParse(newBuffer) ?? 0;
    emit(state.copyWith(numpadBuffer: newBuffer, cashReceived: amount));
  }

  void setPreset(int amount) {
    emit(state.copyWith(cashReceived: amount, numpadBuffer: amount.toString()));
  }

  void updateCashReceived(int amount) => setPreset(amount);

  void toggleItemChecked(int index, bool val, int fallbackTotal) {
    if (index < 0 || index >= state.billItems.length) return;
    final updated = List<Map<String, dynamic>>.from(state.billItems);
    updated[index] = Map<String, dynamic>.from(updated[index])..['checked'] = val;
    emit(state.copyWith(billItems: updated));
    _updatePresetForCurrentSelection(fallbackTotal);
  }

  void updateItemPayQty(int index, int qty, int fallbackTotal) {
    if (index < 0 || index >= state.billItems.length) return;
    final updated = List<Map<String, dynamic>>.from(state.billItems);
    updated[index] = Map<String, dynamic>.from(updated[index])..['payQty'] = qty;
    emit(state.copyWith(billItems: updated));
    _updatePresetForCurrentSelection(fallbackTotal);
  }

  void _updatePresetForCurrentSelection(int fallbackTotal) {
    final selectedTotal = state.calculateSelectedItemsTotal(fallbackTotal);
    emit(state.copyWith(
      cashReceived: selectedTotal,
      numpadBuffer: selectedTotal > 0 ? selectedTotal.toString() : '',
    ));
  }

  Future<void> loadDynamicQris({
    required int amount,
    String? orderId,
    String tableName = 'Meja Kasir',
  }) async {
    if (state.generatingQris || state.submitting) return;
    emit(state.copyWith(generatingQris: true, clearError: true));
    try {
      final invoice = await QrisPaymentService.instance.generateDynamicQris(
        amount: amount,
        orderId: orderId,
        tableNumber: tableName,
      );
      emit(state.copyWith(qrisInvoice: invoice, generatingQris: false));
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(
        generatingQris: false,
        error: msg.isNotEmpty ? msg : 'Gagal membuat tagihan QRIS',
      ));
    }
  }

  Future<bool> verifyQrisStatus({
    required int fallbackTotal,
    String? orderId,
    String? tableId,
    String? customerName,
    int? shiftId,
    List<RegisterLine>? linesFallback,
    String tableName = 'Meja Kasir',
  }) async {
    if (state.checkingQrisStatus || state.submitting) return false;
    final inv = state.qrisInvoice;
    if (inv == null) {
      return await checkout(
        fallbackTotal: fallbackTotal,
        orderId: orderId,
        tableId: tableId,
        customerName: customerName,
        shiftId: shiftId,
        linesFallback: linesFallback,
        tableName: tableName,
      );
    }

    emit(state.copyWith(checkingQrisStatus: true, clearError: true));
    try {
      final status =
          await QrisPaymentService.instance.checkStatus(inv.transactionId);
      emit(state.copyWith(checkingQrisStatus: false));
      if (status == QrisPaymentStatus.paid) {
        return await checkout(
          fallbackTotal: fallbackTotal,
          orderId: orderId,
          tableId: tableId,
          customerName: customerName,
          shiftId: shiftId,
          linesFallback: linesFallback,
          tableName: tableName,
        );
      } else {
        emit(state.copyWith(
          error: status == QrisPaymentStatus.expired
              ? 'Tagihan QRIS telah kedaluwarsa'
              : 'Pembayaran QRIS belum terdeteksi',
        ));
        return false;
      }
    } catch (e) {
      final errMsg = ApiException.from(e).message;
      emit(state.copyWith(
        checkingQrisStatus: false,
        error: 'Gagal memeriksa status QRIS: $errMsg',
      ));
      return false;
    }
  }

  Future<bool> checkout({
    required int fallbackTotal,
    String? orderId,
    String? tableId,
    String? customerName,
    int? shiftId,
    List<RegisterLine>? linesFallback,
    String tableName = 'Meja Kasir',
  }) async {
    if (state.submitting) return false;
    emit(state.copyWith(submitting: true, clearError: true));

    await ready;

    String invoiceNumber = orderId ??
        '#POS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final selectedLines = <RegisterLine>[];
    for (final item in state.billItems) {
      if (!state.isSplitBill ||
          state.splitMode == 'equal' ||
          item['checked'] == true) {
        final totalQty = (item['qty'] as num?)?.toInt() ?? 1;
        final payQty = state.isSplitBill && state.splitMode == 'item'
            ? ((item['payQty'] as num?)?.toInt() ?? totalQty)
            : totalQty;

        final fullLine = item['line'];
        if (fullLine is RegisterLine) {
          selectedLines.add(
            RegisterLine(
              productId: fullLine.productId,
              name: fullLine.name,
              price: fullLine.price,
              quantity: payQty,
              note: fullLine.note,
              options: fullLine.options,
              orderItemId: fullLine.orderItemId,
            ),
          );
        } else {
          final prodId = (item['product_id'] ??
                  item['productId'] ??
                  item['id'] ??
                  'item-${item['name']}')
              .toString();
          selectedLines.add(
            RegisterLine(
              productId: prodId,
              name: item['name']?.toString() ?? 'Item',
              price: (item['price'] as num?) ?? 0,
              quantity: payQty,
              note: item['notes']?.toString(),
            ),
          );
        }
      }
    }

    if (selectedLines.isEmpty && linesFallback != null && linesFallback.isNotEmpty) {
      selectedLines.addAll(linesFallback);
    }

    try {
      final billingSettings = state.billingSettings ?? await BillingSettings.fetch();
      final calculatedBill = BillCalculator.calculate(
        billingSettings,
        subtotal: selectedLines.fold<num>(0, (s, l) => s + l.subtotal),
      );

      final outcome = await FnbRegisterService.instance.checkout(
        lines: selectedLines,
        bill: calculatedBill,
        method: state.selectedMethod,
        paid: state.selectedMethod == 'cash'
            ? state.cashReceived.toDouble()
            : (state.isSplitBill
                ? calculatedBill.total
                : state.calculateTotalBill(fallbackTotal).toDouble()),
        orderId: orderId,
        tableId: tableId,
        customerName: customerName,
        shiftId: shiftId?.toString(),
      );

      if (!state.isSplitBill && orderId != null && orderId.isNotEmpty) {
        KitchenService.instance.markOrderPaid(orderId);
      }

      if (outcome.invoice.isNotEmpty) {
        invoiceNumber = outcome.invoice;
      }

      await ReceiptPrinterService.instance.openCashDrawer();

      final storeName = SessionStorage.instance.getLocationName() ??
          SessionStorage.instance.getTenantName() ??
          'Velora Coffee';
      final cashier = SessionStorage.instance.getUserName() ?? 'Kasir';
      final effectiveItems = selectedLines.isNotEmpty
          ? selectedLines
          : (linesFallback ?? []);
      final effectiveTotal = state.calculateSelectedItemsTotal(fallbackTotal);

      final receiptData = ReceiptData(
        storeName: storeName,
        storeAddress: SessionStorage.instance.getStoreAddress() ?? '',
        storePhone: SessionStorage.instance.getStorePhone() ?? '',
        orderNumber: invoiceNumber,
        tableName: tableName,
        customerName: customerName,
        cashierName: cashier,
        total: effectiveTotal.toDouble(),
        received: state.selectedMethod == 'cash'
            ? state.cashReceived.toDouble()
            : effectiveTotal.toDouble(),
        change: state.calculateChangeAmount(fallbackTotal).toDouble(),
        paymentMethod: state.selectedMethod.toUpperCase(),
        timestamp: DateTime.now(),
        storeLogo: SessionStorage.instance.getStoreLogo(),
        showLogo: SessionStorage.instance.isPrinterShowLogo(),
        items: effectiveItems
            .map(
              (l) => PosCartItem(
                productId: l.productId,
                name: l.options.isNotEmpty
                    ? '${l.name} (${l.options.map((o) => o.name).join(", ")})'
                    : l.name,
                price: l.unitPrice,
                quantity: l.quantity,
                note: l.note,
              ),
            )
            .toList(),
      );

      emit(state.copyWith(
        submitting: false,
        checkoutSuccess: true,
        successReceipt: receiptData,
        successChange: state.calculateChangeAmount(fallbackTotal),
      ));
      return true;
    } catch (e) {
      final errorMsg = ApiException.from(e).message;
      emit(state.copyWith(
        submitting: false,
        error: 'Pembayaran gagal: $errorMsg',
      ));
      return false;
    }
  }

  void resetCheckoutSuccess() {
    emit(state.copyWith(checkoutSuccess: false));
  }

  /// Continue split for item-mode: mark remaining items checked and reset invoice.
  void continueItemSplit(List<Map<String, dynamic>> remainingItems) {
    for (final it in remainingItems) {
      it['checked'] = true;
    }
    emit(state.copyWith(
      billItems: remainingItems,
      activeBill: null,
      qrisInvoice: null,
    ));
  }

  /// Continue split for pax-mode: decrement pax count and reset invoice.
  void continuePaxSplit() {
    final newPax = (state.paxCount - state.paxToPay).clamp(1, 20);
    emit(state.copyWith(
      paxCount: newPax,
      paxToPay: 1,
      qrisInvoice: null,
    ));
  }
}
