import 'package:flutter/material.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/storage/session_storage.dart';
import '../../models/pharmacy_etiket_item.dart';

/// Physical simulated thermal etiket sticker preview (Etiket Putih vs Etiket Biru)
class PharmacyEtiketPreviewCard extends StatelessWidget {
  final PharmacyEtiketItem item;
  final String patientName;
  final String queueNumber;
  final String medicalRecordNumber;
  final String doctorName;

  const PharmacyEtiketPreviewCard({
    super.key,
    required this.item,
    required this.patientName,
    required this.queueNumber,
    required this.medicalRecordNumber,
    required this.doctorName,
  });

  @override
  Widget build(BuildContext context) {
    final isLuar = item.isObatLuar;
    final now = DateTime.now();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLuar ? const Color(0xFFF0F9FF) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLuar ? const Color(0xFF0284C7) : const Color(0xFF64748B),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            (SessionStorage.instance.getTenantName() ?? 'VELORA PHARMACY').toUpperCase(),
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isLuar ? const Color(0xFF0369A1) : ClinicalPalette.textPrimary,
            ),
          ),
          Text(
            'Apotek & Klinik Terpadu • SIA: 442/089/SIA/2023',
            style: TextStyle(
              fontSize: 9.5,
              color: isLuar ? const Color(0xFF0284C7) : ClinicalPalette.textTertiary,
            ),
          ),
          const SizedBox(height: 6),
          Container(height: 1, color: isLuar ? const Color(0xFFBAE6FD) : ClinicalPalette.border),
          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tgl: ${now.day}/${now.month}/${now.year}', style: const TextStyle(fontSize: 10, color: ClinicalPalette.textTertiary)),
              Text('No. RM: $medicalRecordNumber', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ClinicalPalette.textPrimary)),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pasien: $patientName', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ClinicalPalette.textPrimary)),
              Text('Antrean: $queueNumber', style: const TextStyle(fontSize: 10, color: ClinicalPalette.textTertiary)),
            ],
          ),
          const SizedBox(height: 8),

          // Drug Name Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: isLuar ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${item.item.name} (${item.item.quantity} ${item.item.modifiers ?? "TAB"})',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: ClinicalPalette.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),

          // Big Signa Text
          Text(
            item.signa.toUpperCase(),
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: isLuar ? const Color(0xFF0369A1) : ClinicalPalette.primary,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            item.waktuMinum,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ClinicalPalette.textSecondary),
          ),

          if (isLuar) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFBA1A1A),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'OBAT LUAR - TIDAK BOLEH DITELAN',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],

          const SizedBox(height: 8),
          Container(height: 1, color: isLuar ? const Color(0xFFBAE6FD) : ClinicalPalette.border),
          const SizedBox(height: 4),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dokter: $doctorName', style: const TextStyle(fontSize: 9.5, color: ClinicalPalette.textTertiary)),
              Text('Apoteker: ${SessionStorage.instance.getUserName() ?? "Apoteker"}', style: const TextStyle(fontSize: 9.5, color: ClinicalPalette.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }
}
