import 'pos_checkout_service.dart';

class CompletedSaleRecord {
  final String invoiceNumber;
  final DateTime time;
  final num total;
  final String paymentMethod;
  final String? tableOrCustomer;
  final List<PosCartItem> items;
  bool isVoided;

  CompletedSaleRecord({
    required this.invoiceNumber,
    required this.time,
    required this.total,
    required this.paymentMethod,
    this.tableOrCustomer,
    required this.items,
    this.isVoided = false,
  });
}

class ShiftSalesStorage {
  static final List<CompletedSaleRecord> activeShiftSales = [];

  static void add(CompletedSaleRecord record) {
    activeShiftSales.insert(0, record);
  }

  static void clear() {
    activeShiftSales.clear();
  }
}
