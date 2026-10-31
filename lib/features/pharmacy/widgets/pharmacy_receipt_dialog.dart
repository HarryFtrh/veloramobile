import 'package:flutter/material.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../shared_pos/pos_checkout_service.dart';
import '../../shared_pos/receipt_printer_service.dart';

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
    const emeraldPrimary = Color(0xFF006948);
    const borderColor = Color(0xFFE2E8F0);
    const textPrimary = Color(0xFF131B2E);
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
                      color: const Color(0xFF86F2E4),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF006A61).withValues(alpha: 0.3), width: 3),
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: Color(0xFF006F66), size: 32),
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E7FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.person_outline, size: 20, color: Color(0xFF006577)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      patientName,
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF86F2E4).withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      medicalRecordNumber,
                                      style: const TextStyle(
                                        fontFamily: 'JetBrains Mono',
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF006F66),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'Dokter: $doctorName',
                                style: const TextStyle(fontSize: 10.5, color: textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: emeraldPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'LUNAS',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: emeraldPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Itemized Receipt List
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                            border: Border(bottom: BorderSide(color: borderColor)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.receipt_long, size: 14, color: emeraldPrimary),
                                  SizedBox(width: 6),
                                  Text(
                                    'Rincian Obat & Resep',
                                    style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Text(
                                '${items.length} Item',
                                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10.5, color: textMuted),
                              ),
                            ],
                          ),
                        ),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(12),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const Divider(height: 12, color: borderColor),
                          itemBuilder: (context, idx) {
                            final item = items[idx];
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                                      ),
                                      Text(
                                        'Qty: ${item.quantity} • Batch: ${item.batchNumber ?? "-"}',
                                        style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, color: textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(item.price * item.quantity),
                                  style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                                ),
                              ],
                            );
                          },
                        ),
                        if (tuslahFee > 0) ...[
                          const Divider(height: 1, color: borderColor),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Jasa Resep & Embalase (Tuslah)',
                                  style: TextStyle(fontSize: 11, color: textMuted),
                                ),
                                Text(
                                  CurrencyFormatter.format(tuslahFee),
                                  style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11.5, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Financial Breakdown
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal Obat', style: TextStyle(fontSize: 11, color: textMuted)),
                            Text(CurrencyFormatter.format(subtotal), style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11.5, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Metode Pembayaran', style: TextStyle(fontSize: 11, color: textMuted)),
                            Text(paymentMethod.toUpperCase(), style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF006A61))),
                          ],
                        ),
                        const Divider(height: 14, color: borderColor),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL SETTLEMENT',
                              style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                            Text(
                              CurrencyFormatter.format(grandTotal),
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: emeraldPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
                      ReceiptPrinterService.instance.printReceipt(
                        orderId: result.invoiceNumber,
                        items: items.map((e) => {
                          'name': e.name,
                          'qty': e.quantity,
                          'price': e.price,
                          'subtotal': e.price * e.quantity,
                          'batch': e.batchNumber ?? '-',
                        }).toList(),
                        total: grandTotal,
                        paymentMethod: paymentMethod,
                        customerName: '$patientName ($queueNumber)',
                        cashierName: SessionStorage.instance.getUserName() ?? 'Apoteker',
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Struk resep dikirim ke printer thermal kasir.')),
                      );
                    },
                    icon: const Icon(Icons.print_outlined, size: 16),
                    label: const Text('Cetak Struk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF006A61),
                      side: const BorderSide(color: Color(0xFF006A61)),
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
