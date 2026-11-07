import 'package:flutter/material.dart';
import '../../../core/storage/session_storage.dart';
import '../../shared_pos/pos_checkout_service.dart';
import '../../shared_pos/receipt_printer_service.dart';
import 'receipt/pharmacy_receipt_financial_breakdown.dart';
import 'receipt/pharmacy_receipt_item_list.dart';
import 'receipt/pharmacy_receipt_patient_banner.dart';

export 'receipt/pharmacy_receipt_financial_breakdown.dart';
export 'receipt/pharmacy_receipt_item_list.dart';
export 'receipt/pharmacy_receipt_patient_banner.dart';

class PharmacyReceiptDialog extends StatelessWidget {
  final PosCheckoutResult result;
  final String patientName;
  final String queueNumber;
  final String medicalRecordNumber;
  final String doctorName;
  final List<PosCartItem> items;
  final num subtotal;
  final num tuslahFee;
  final num grandTotal;
  final String paymentMethod;
  final VoidCallback onNewSale;

  const PharmacyReceiptDialog({
    super.key,
    required this.result,
    required this.patientName,
    required this.queueNumber,
    required this.medicalRecordNumber,
    required this.doctorName,
    required this.items,
    required this.subtotal,
    required this.tuslahFee,
    required this.grandTotal,
    required this.paymentMethod,
    required this.onNewSale,
  });

  static Future<void> show({
    required BuildContext context,
    required PosCheckoutResult result,
    required String patientName,
    required String queueNumber,
    required String medicalRecordNumber,
    required String doctorName,
    required List<PosCartItem> items,
    required num subtotal,
    required num tuslahFee,
    required num grandTotal,
    required String paymentMethod,
    required VoidCallback onNewSale,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: PharmacyReceiptDialog(
            result: result,
            patientName: patientName,
            queueNumber: queueNumber,
            medicalRecordNumber: medicalRecordNumber,
            doctorName: doctorName,
            items: items,
            subtotal: subtotal,
            tuslahFee: tuslahFee,
            grandTotal: grandTotal,
            paymentMethod: paymentMethod,
            onNewSale: () {
              Navigator.pop(ctx);
              onNewSale();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF059669);
    const borderColor = Color(0xFFE2E8F0);
    const textPrimary = Color(0xFF0F172A);
    const textMuted = Color(0xFF6D7A72);
    final now = DateTime.now();
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final monthName = (now.month >= 1 && now.month <= 12) ? monthNames[now.month - 1] : '';
    final timeStr = '${now.day} $monthName ${now.year}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Accent Bar
          Container(
            height: 6,
            decoration: const BoxDecoration(
              color: emeraldPrimary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),

          // Scrollable Receipt Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Success Hero Badge
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.3), width: 3),
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: Color(0xFF0D9488), size: 32),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Pembayaran Sukses',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: emeraldPrimary,
                    ),
                  ),
                  Text(
                    'Faktur #${result.invoiceNumber}',
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: const TextStyle(fontSize: 11, color: textMuted),
                  ),
                  const SizedBox(height: 14),

                  // Patient Banner
                  PharmacyReceiptPatientBanner(
                    patientName: patientName,
                    medicalRecordNumber: medicalRecordNumber,
                    doctorName: doctorName,
                  ),
                  const SizedBox(height: 12),

                  // Itemized Receipt List
                  PharmacyReceiptItemList(
                    items: items,
                    tuslahFee: tuslahFee,
                  ),
                  const SizedBox(height: 12),

                  // Financial Breakdown
                  PharmacyReceiptFinancialBreakdown(
                    subtotal: subtotal,
                    paymentMethod: paymentMethod,
                    grandTotal: grandTotal,
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final session = SessionStorage.instance;
                      ReceiptPrinterService.instance.printReceipt(
                        ReceiptData(
                          storeName: session.getTenantName() ?? session.getLocationName() ?? 'Apotek',
                          storeAddress: session.getStoreAddress() ?? session.getLocationName() ?? '-',
                          storePhone: session.getStorePhone() ?? '-',
                          invoiceNumber: result.invoiceNumber,
                          cashierName: session.getUserName() ?? 'Apoteker',
                          tableOrPatient: '$patientName ($queueNumber)',
                          timestamp: DateTime.now(),
                          items: items,
                          subtotal: subtotal,
                          tax: tuslahFee,
                          grandTotal: grandTotal,
                          paidAmount: result.paidAmount,
                          changeAmount: result.changeAmount,
                          paymentMethod: paymentMethod,
                          qrData: result.qrData,
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Struk resep dikirim ke printer thermal kasir.')),
                      );
                    },
                    icon: const Icon(Icons.print_outlined, size: 16),
                    label: const Text('Cetak Struk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0D9488),
                      side: const BorderSide(color: Color(0xFF0D9488)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onNewSale,
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: const Text('Transaksi Resep Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: emeraldPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
