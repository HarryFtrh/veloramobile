import 'package:flutter/material.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../shared_pos/pos_checkout_service.dart';

/// Jagged paper cut painter for physical receipt look
class JaggedEdgePainter extends CustomPainter {
  final bool isTop;
  const JaggedEdgePainter({required this.isTop});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFAF8FF)
      ..style = PaintingStyle.fill;

    final path = Path();
    const toothWidth = 10.0;
    final toothHeight = size.height;
    final teethCount = (size.width / toothWidth).ceil();

    if (isTop) {
      path.moveTo(0, toothHeight);
      for (int i = 0; i < teethCount; i++) {
        final x = i * toothWidth;
        path.lineTo(x + toothWidth / 2, 0);
        path.lineTo(x + toothWidth, toothHeight);
      }
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
      path.close();
    } else {
      path.moveTo(0, 0);
      for (int i = 0; i < teethCount; i++) {
        final x = i * toothWidth;
        path.lineTo(x + toothWidth / 2, toothHeight);
        path.lineTo(x + toothWidth, 0);
      }
      path.lineTo(size.width, toothHeight);
      path.lineTo(0, toothHeight);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Simulated Barcode Widget (Code-128 Look)
class ReceiptSimulatedBarcode extends StatelessWidget {
  final String code;

  const ReceiptSimulatedBarcode({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: ClinicalPalette.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(36, (index) {
              final widths = [1.0, 2.0, 1.5, 3.0, 1.0, 2.5, 1.0, 1.5];
              final w = widths[index % widths.length];
              return Container(
                width: w,
                color: index % 2 == 0 ? const Color(0xFF0F172A) : Colors.transparent,
                margin: const EdgeInsets.symmetric(horizontal: 1),
              );
            }),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '*$code*',
          style: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 9,
            color: ClinicalPalette.textTertiary,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Thermal receipt live preview and audit column
class PharmacyCheckoutReceiptAudit extends StatelessWidget {
  final List<PosCartItem> items;
  final num subtotal;
  final num tuslahFee;
  final num embalaseFee;
  final num taxAmount;
  final String taxName;
  final num discountAmount;
  final num grandTotal;
  final String patientName;
  final String queueNumber;
  final String medicalRecordNumber;
  final String doctorName;
  final VoidCallback onShareWhatsApp;

  const PharmacyCheckoutReceiptAudit({
    super.key,
    required this.items,
    required this.subtotal,
    this.tuslahFee = 0,
    this.embalaseFee = 0,
    this.taxAmount = 0,
    this.taxName = 'PPN',
    this.discountAmount = 0,
    required this.grandTotal,
    required this.patientName,
    required this.queueNumber,
    required this.medicalRecordNumber,
    required this.doctorName,
    required this.onShareWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';
    final barcodeStr = 'TRX-${now.year}${now.month.toString().padLeft(2, "0")}${now.day.toString().padLeft(2, "0")}-$queueNumber';

    return Column(
      children: [
        // Header Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            border: Border(bottom: BorderSide(color: ClinicalPalette.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.receipt_long_rounded, color: ClinicalPalette.primary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Pratinjau Struk & Rincian Transaksi',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: ClinicalPalette.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.share_rounded, size: 18, color: ClinicalPalette.primary),
                    tooltip: 'Kirim Struk via WhatsApp',
                    onPressed: onShareWhatsApp,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: ClinicalPalette.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'TERMINAL AUDIT COPY',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: ClinicalPalette.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Scrollable Receipt Paper with Jagged Paper Tear Effect
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 390),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top Jagged Cut Paper Edge
                    const CustomPaint(
                      size: Size(390, 8),
                      painter: JaggedEdgePainter(isTop: true),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Pharmacy Header
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: ClinicalPalette.primary.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.health_and_safety_rounded, color: ClinicalPalette.primary, size: 22),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  (SessionStorage.instance.getTenantName() ?? 'VELORA PHARMACY').toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: ClinicalPalette.textPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  SessionStorage.instance.getLocationName() ?? 'Cabang Utama • Apotek & Klinik Terpadu',
                                  style: const TextStyle(fontSize: 10.5, color: ClinicalPalette.textTertiary),
                                ),
                                Text(
                                  SessionStorage.instance.getStoreAddress() ?? 'Jl. Kesehatan Medika No. 18 • Telp: (021) 7892011',
                                  style: const TextStyle(fontSize: 10, color: ClinicalPalette.textTertiary),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),
                          _buildDashedLine(),
                          const SizedBox(height: 10),

                          // Metadata
                          _buildMetadataRow('Pasien / Klien:', patientName, isBold: true),
                          _buildMetadataRow('No. Antrean:', queueNumber),
                          _buildMetadataRow('No. Rekam Medis:', medicalRecordNumber, isAccent: true),
                          _buildMetadataRow('Dokter Peresep:', doctorName),
                          _buildMetadataRow('Kasir / Petugas:', SessionStorage.instance.getUserName() ?? 'Apoteker'),
                          _buildMetadataRow('Waktu Transaksi:', timeStr),

                          const SizedBox(height: 10),
                          _buildDashedLine(),
                          const SizedBox(height: 10),

                          // Items Table Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('RINCIAN OBAT & ALKES', style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: FontWeight.bold, color: ClinicalPalette.textTertiary)),
                              Text('SUBTOTAL', style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: FontWeight.bold, color: ClinicalPalette.textTertiary)),
                            ],
                          ),
                          const SizedBox(height: 6),

                          ...items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: ClinicalPalette.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        CurrencyFormatter.formatRupiah(item.price * item.quantity),
                                        style: const TextStyle(
                                          fontFamily: 'JetBrains Mono',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: ClinicalPalette.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${item.quantity}x @ ${CurrencyFormatter.formatRupiah(item.price)}',
                                        style: const TextStyle(fontSize: 10.5, color: ClinicalPalette.textTertiary),
                                      ),
                                      if (item.batchNumber != null && item.batchNumber != '-')
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            'B: ${item.batchNumber}',
                                            style: const TextStyle(
                                              fontFamily: 'JetBrains Mono',
                                              fontSize: 9,
                                              color: ClinicalPalette.textSecondary,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),

                          const SizedBox(height: 10),
                          _buildDashedLine(),
                          const SizedBox(height: 10),

                          // Financial Calculations
                          _buildFinancialRow('Subtotal Obat', subtotal),
                          if (tuslahFee > 0)
                            _buildFinancialRow('Jasa Tuslah / Dispensing', tuslahFee, isSubtle: true),
                          if (embalaseFee > 0)
                            _buildFinancialRow('Biaya Embalase & Wadah', embalaseFee, isSubtle: true),
                          if (taxAmount > 0)
                            _buildFinancialRow(taxName, taxAmount, isSubtle: true),
                          if (discountAmount > 0)
                            _buildFinancialRow('Diskon', -discountAmount, isDiscount: true),

                          const SizedBox(height: 8),
                          Container(height: 1, color: ClinicalPalette.border),
                          const SizedBox(height: 8),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL TAGIHAN',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: ClinicalPalette.textPrimary,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.formatRupiah(grandTotal),
                                style: const TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: ClinicalPalette.primary,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          _buildDashedLine(),
                          const SizedBox(height: 12),

                          // Barcode
                          ReceiptSimulatedBarcode(code: barcodeStr),
                          const SizedBox(height: 8),

                          // Thermal Footer Note
                          const Center(
                            child: Text(
                              'Obat yang sudah dibeli tidak dapat ditukar/dikembalikan.\nSemoga lekas sembuh.',
                              style: TextStyle(fontSize: 9.5, color: ClinicalPalette.textTertiary, fontStyle: FontStyle.italic),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Jagged Cut Paper Edge
                    const CustomPaint(
                      size: Size(390, 8),
                      painter: JaggedEdgePainter(isTop: false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataRow(String label, String value, {bool isBold = false, bool isAccent = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: ClinicalPalette.textTertiary)),
          Text(
            value,
            style: TextStyle(
              fontFamily: isAccent ? 'JetBrains Mono' : 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: isBold || isAccent ? FontWeight.bold : FontWeight.w500,
              color: isAccent ? ClinicalPalette.primary : ClinicalPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String label, num amount, {bool isSubtle = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: isSubtle ? ClinicalPalette.textTertiary : ClinicalPalette.textSecondary,
            ),
          ),
          Text(
            '${isDiscount ? "-" : ""}${CurrencyFormatter.formatRupiah(amount.abs())}',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDiscount ? ClinicalPalette.danger : ClinicalPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedLine() {
    return Row(
      children: List.generate(
        30,
        (i) => Expanded(
          child: Container(
            color: i % 2 == 0 ? ClinicalPalette.border : Colors.transparent,
            height: 1,
          ),
        ),
      ),
    );
  }
}
