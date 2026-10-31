import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/utils/audio_helper.dart';
import '../../../core/utils/currency_formatter.dart';

class PharmacyCustomerFacingDisplay extends StatelessWidget {
  final num grandTotal;
  final String patientName;
  final String queueNumber;
  final VoidCallback onPaymentConfirmed;

  const PharmacyCustomerFacingDisplay({
    super.key,
    required this.grandTotal,
    required this.patientName,
    required this.queueNumber,
    required this.onPaymentConfirmed,
  });

  static Future<void> show({
    required BuildContext context,
    required num grandTotal,
    required String patientName,
    required String queueNumber,
    required VoidCallback onPaymentConfirmed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: PharmacyCustomerFacingDisplay(
            grandTotal: grandTotal,
            patientName: patientName,
            queueNumber: queueNumber,
            onPaymentConfirmed: onPaymentConfirmed,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ClinicalPalette.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (SessionStorage.instance.getTenantName() ?? 'VELORA PHARMACY').toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Text(
                          'LAYAR PEMBAYARAN PASIEN',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 10,
                            color: Color(0xFF94A3B8),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  tooltip: 'Tutup Layar Pasien',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Main QR & Total Section
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                // Patient & Queue Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_rounded, size: 16, color: ClinicalPalette.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Pasien: $patientName',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: ClinicalPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: ClinicalPalette.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          queueNumber,
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'TOTAL YANG HARUS DIBAYAR',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: ClinicalPalette.textTertiary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.formatRupiah(grandTotal),
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: ClinicalPalette.primary,
                  ),
                ),
                const SizedBox(height: 24),

                // QR Container with Glow & Pulsating Border
                Container(
                  width: 220,
                  height: 220,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ClinicalPalette.primary, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: ClinicalPalette.primary.withValues(alpha: 0.15),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.qr_code_2_rounded, size: 190, color: Color(0xFF0F172A)),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6),
                          ],
                        ),
                        child: const Icon(Icons.local_pharmacy_rounded, size: 28, color: ClinicalPalette.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Pindai QRIS Menggunakan Aplikasi Bank atau Dompet Digital Apa Saja',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ClinicalPalette.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  'BCA, Mandiri Livin, BRImo, BNI+, GoPay, OVO, Dana, ShopeePay',
                  style: TextStyle(
                    fontSize: 11,
                    color: ClinicalPalette.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Bottom Action Confirm
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              border: Border(top: BorderSide(color: ClinicalPalette.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.wifi_rounded, size: 16, color: ClinicalPalette.primary),
                    SizedBox(width: 6),
                    Text(
                      'Menunggu pembayaran pasien...',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11,
                        color: ClinicalPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    AudioHelper.actionFeedback();
                    Navigator.of(context).pop();
                    onPaymentConfirmed();
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Konfirmasi Diterima'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ClinicalPalette.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
