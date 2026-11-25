import 'package:material_ui/material_ui.dart';
import '../../../core/design/tokens.dart';
import '../../../core/storage/session_storage.dart';
import '../../shared_pos/services/pos_checkout_service.dart';
import '../../shared_pos/services/receipt_printer_service.dart';
import 'receipt/pharmacy_receipt_financial_breakdown.dart';
import 'receipt/pharmacy_receipt_item_list.dart';
import 'receipt/pharmacy_receipt_patient_banner.dart';
import '../pharmacy_colors.dart';

export 'receipt/pharmacy_receipt_financial_breakdown.dart';
export 'receipt/pharmacy_receipt_item_list.dart';
export 'receipt/pharmacy_receipt_patient_banner.dart';

class PharmacyReceiptDialog extends StatefulWidget {
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

  @override
  State<PharmacyReceiptDialog> createState() => _PharmacyReceiptDialogState();

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
}

class _PharmacyReceiptDialogState extends State<PharmacyReceiptDialog> {
  bool _isPrinting = false;

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = PharmacyColors.primary;
    final borderColor = context.palette.line;
    final textPrimary = context.palette.textPrimary;
    final textMuted = context.palette.textSecondary;
    final now = DateTime.now();
    final timeStr = DateTimeFormatter.dateTime(now);

    return Container(
      decoration: BoxDecoration(
        color: context.palette.canvas,
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
                    'Faktur #${widget.result.invoiceNumber}',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                  const SizedBox(height: 14),

                  // Patient Banner
                  PharmacyReceiptPatientBanner(
                    patientName: widget.patientName,
                    medicalRecordNumber: widget.medicalRecordNumber,
                    doctorName: widget.doctorName,
                  ),
                  const SizedBox(height: 12),

                  // Itemized Receipt List
                  PharmacyReceiptItemList(
                    items: widget.items,
                    tuslahFee: widget.tuslahFee,
                  ),
                  const SizedBox(height: 12),

                  // Financial Breakdown
                  PharmacyReceiptFinancialBreakdown(
                    subtotal: widget.subtotal,
                    paymentMethod: widget.paymentMethod,
                    grandTotal: widget.grandTotal,
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.palette.surface,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isPrinting
                        ? null
                        : () async {
                            if (_isPrinting) return;
                            setState(() => _isPrinting = true);
                            try {
                              final session = SessionStorage.instance;
                              await ReceiptPrinterService.instance.printReceipt(
                                ReceiptData(
                                  storeName: session.getTenantName() ?? session.getLocationName() ?? 'Apotek',
                                  storeAddress: session.getStoreAddress() ?? session.getLocationName() ?? '-',
                                  storePhone: session.getStorePhone() ?? '-',
                                  invoiceNumber: widget.result.invoiceNumber,
                                  cashierName: session.getUserName() ?? 'Apoteker',
                                  tableOrPatient: '${widget.patientName} (${widget.queueNumber})',
                                  timestamp: DateTime.now(),
                                  items: widget.items,
                                  subtotal: widget.subtotal,
                                  tax: widget.tuslahFee,
                                  grandTotal: widget.grandTotal,
                                  paidAmount: widget.result.paidAmount,
                                  changeAmount: widget.result.changeAmount,
                                  paymentMethod: widget.paymentMethod,
                                  qrData: widget.result.qrData,
                                ),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Struk resep dikirim ke printer thermal kasir.')),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _isPrinting = false);
                            }
                          },
                    icon: const Icon(Icons.print_outlined, size: 16),
                    label: Text(
                      _isPrinting ? 'Mencetak...' : 'Cetak Struk',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
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
                    onPressed: widget.onNewSale,
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
