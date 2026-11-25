import '../../../core/storage/session_storage.dart';
import '../services/pos_checkout_service.dart';

class ReceiptData {
  final String storeName;
  final String storeAddress;
  final String storePhone;
  final String? storeLogo;
  final bool showLogo;
  final String invoiceNumber;
  final String cashierName;
  final String? tableOrPatient;
  final DateTime timestamp;
  final List<PosCartItem> items;
  final num subtotal;
  final num discount;
  final num serviceCharge;
  final num tax;
  final num rounding;
  final num grandTotal;
  final num paidAmount;
  final num changeAmount;
  final String paymentMethod;
  final String? qrData;
  final String? note;

  ReceiptData({
    required this.storeName,
    String? storeAddress,
    String? storePhone,
    String? storeLogo,
    bool? showLogo,
    String? invoiceNumber,
    String? orderNumber,
    required this.cashierName,
    String? tableOrPatient,
    String? tableName,
    String? customerName,
    required this.timestamp,
    required this.items,
    num? subtotal,
    num? discount,
    num? serviceCharge,
    num? tax,
    num? rounding,
    num? grandTotal,
    num? total,
    num? paidAmount,
    num? received,
    num? changeAmount,
    num? change,
    String? paymentMethod,
    this.qrData,
    this.note,
  })  : storeAddress = storeAddress ?? SessionStorage.instance.getStoreAddress() ?? '',
        storePhone = storePhone ?? SessionStorage.instance.getStorePhone() ?? '',
        storeLogo = storeLogo ?? SessionStorage.instance.getStoreLogo(),
        showLogo = showLogo ?? SessionStorage.instance.isPrinterShowLogo(),
        invoiceNumber = invoiceNumber ?? orderNumber ?? '-',
        tableOrPatient = tableOrPatient ??
            (tableName != null && customerName != null
                ? '$tableName ($customerName)'
                : (tableName ?? customerName)),
        subtotal = subtotal ?? grandTotal ?? total ?? 0,
        discount = discount ?? 0,
        serviceCharge = serviceCharge ?? 0,
        tax = tax ?? 0,
        rounding = rounding ?? 0,
        grandTotal = grandTotal ?? total ?? 0,
        paidAmount = paidAmount ?? received ?? grandTotal ?? total ?? 0,
        changeAmount = changeAmount ?? change ?? 0,
        paymentMethod = paymentMethod ?? 'TUNAI';

  String get orderNumber => invoiceNumber;
  num get total => grandTotal;
  num get received => paidAmount;
  num get change => changeAmount;
  String? get tableName => tableOrPatient;
  String? get customerName => tableOrPatient;
}
