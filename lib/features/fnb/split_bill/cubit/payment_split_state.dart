// features/fnb/split_bill/cubit/payment_split_state.dart
import 'package:equatable/equatable.dart';

import '../../../shared_pos/qris_payment_service.dart';
import '../../../shared_pos/receipt_printer_service.dart';
import '../../billing.dart';

class PaymentSplitState extends Equatable {
  const PaymentSplitState({
    this.isSplitBill = false,
    this.splitMode = 'item',
    this.paxCount = 2,
    this.paxToPay = 1,
    this.selectedMethod = 'cash',
    this.cashReceived = 0,
    this.numpadBuffer = '0',
    this.loading = false,
    this.submitting = false,
    this.generatingQris = false,
    this.checkingQrisStatus = false,
    this.billItems = const [],
    this.billingSettings,
    this.activeBill,
    this.qrisInvoice,
    this.error,
    this.checkoutSuccess = false,
    this.successReceipt,
    this.successChange = 0,
  });

  final bool isSplitBill;
  final String splitMode;
  final int paxCount;
  final int paxToPay;
  final String selectedMethod;
  final int cashReceived;
  final String numpadBuffer;
  final bool loading;
  final bool submitting;
  final bool generatingQris;
  final bool checkingQrisStatus;
  final List<Map<String, dynamic>> billItems;
  final BillingSettings? billingSettings;
  final BillBreakdown? activeBill;
  final QrisInvoiceData? qrisInvoice;
  final String? error;
  final bool checkoutSuccess;
  final ReceiptData? successReceipt;
  final int successChange;

  int calculateTotalBill(int fallbackTotal) {
    if (activeBill != null) {
      return activeBill!.total.round().clamp(0, 999999999);
    }
    if (fallbackTotal > 0) return fallbackTotal;
    final sum = billItems.fold<num>(
      0,
      (acc, item) =>
          acc +
          (((item['price'] as num?) ?? 0) *
              ((item['qty'] as num?)?.toInt() ?? 1)),
    );
    if (billingSettings != null) {
      return BillCalculator.calculate(
        billingSettings!,
        subtotal: sum,
      ).total.round().clamp(0, 999999999);
    }
    return sum.round().clamp(0, 999999999);
  }

  int calculateSelectedItemsTotal(int fallbackTotal) {
    final totalBill = calculateTotalBill(fallbackTotal);
    if (!isSplitBill) return totalBill;
    if (splitMode == 'equal') {
      final safePax = paxCount > 0 ? paxCount : 1;
      final perPerson = (totalBill / safePax).ceil();
      return (paxToPay * perPerson).clamp(0, 999999999);
    }
    final itemsSum = billItems
        .where((i) => i['checked'] == true)
        .fold<num>(0, (sum, i) {
      final price = (i['price'] as num?) ?? 0;
      final count = (i['payQty'] as num?)?.toInt() ??
          ((i['qty'] as num?)?.toInt() ?? 1);
      return sum + (price * count);
    });

    if (billingSettings != null) {
      return BillCalculator.calculate(
        billingSettings!,
        subtotal: itemsSum,
      ).total.round().clamp(0, 999999999);
    }
    return itemsSum.round().clamp(0, 999999999);
  }

  int calculateChangeAmount(int fallbackTotal) {
    final selectedTotal = calculateSelectedItemsTotal(fallbackTotal);
    return (cashReceived - selectedTotal).clamp(0, 99999999);
  }

  bool isPaymentSufficient(int fallbackTotal) {
    final selectedTotal = calculateSelectedItemsTotal(fallbackTotal);
    if (selectedTotal <= 0) return false;
    if (isSplitBill &&
        splitMode == 'item' &&
        !billItems.any((i) => i['checked'] == true)) {
      return false;
    }
    if (selectedMethod == 'cash') {
      return cashReceived >= selectedTotal;
    }
    return true;
  }

  PaymentSplitState copyWith({
    bool? isSplitBill,
    String? splitMode,
    int? paxCount,
    int? paxToPay,
    String? selectedMethod,
    int? cashReceived,
    String? numpadBuffer,
    bool? loading,
    bool? submitting,
    bool? generatingQris,
    bool? checkingQrisStatus,
    List<Map<String, dynamic>>? billItems,
    BillingSettings? billingSettings,
    BillBreakdown? activeBill,
    QrisInvoiceData? qrisInvoice,
    String? error,
    bool clearError = false,
    bool? checkoutSuccess,
    ReceiptData? successReceipt,
    int? successChange,
  }) {
    return PaymentSplitState(
      isSplitBill: isSplitBill ?? this.isSplitBill,
      splitMode: splitMode ?? this.splitMode,
      paxCount: paxCount ?? this.paxCount,
      paxToPay: paxToPay ?? this.paxToPay,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      cashReceived: cashReceived ?? this.cashReceived,
      numpadBuffer: numpadBuffer ?? this.numpadBuffer,
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      generatingQris: generatingQris ?? this.generatingQris,
      checkingQrisStatus: checkingQrisStatus ?? this.checkingQrisStatus,
      billItems: billItems ?? this.billItems,
      billingSettings: billingSettings ?? this.billingSettings,
      activeBill: activeBill ?? this.activeBill,
      qrisInvoice: qrisInvoice ?? this.qrisInvoice,
      error: clearError ? null : (error ?? this.error),
      checkoutSuccess: checkoutSuccess ?? this.checkoutSuccess,
      successReceipt: successReceipt ?? this.successReceipt,
      successChange: successChange ?? this.successChange,
    );
  }

  @override
  List<Object?> get props => [
        isSplitBill,
        splitMode,
        paxCount,
        paxToPay,
        selectedMethod,
        cashReceived,
        numpadBuffer,
        loading,
        submitting,
        generatingQris,
        checkingQrisStatus,
        billItems,
        billingSettings,
        activeBill,
        qrisInvoice,
        error,
        checkoutSuccess,
        successReceipt,
        successChange,
      ];
}
