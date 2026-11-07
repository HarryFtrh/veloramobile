import 'package:flutter/material.dart';

/// Patient context banner displayed on the pharmacy thermal receipt dialog
class PharmacyReceiptPatientBanner extends StatelessWidget {
  final String patientName;
  final String medicalRecordNumber;
  final String doctorName;

  const PharmacyReceiptPatientBanner({
    super.key,
    required this.patientName,
    required this.medicalRecordNumber,
    required this.doctorName,
  });

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF059669);
    const borderColor = Color(0xFFE2E8F0);
    const textPrimary = Color(0xFF0F172A);
    const textMuted = Color(0xFF6D7A72);

    return Container(
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
            child: const Icon(Icons.person_outline, size: 20, color: Color(0xFF0D9488)),
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
                        color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        medicalRecordNumber,
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D9488),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  (doctorName.isNotEmpty && doctorName != '-' && doctorName != 'dr. -')
                      ? 'Dokter: $doctorName'
                      : 'Penjualan Bebas / Walk-in',
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
    );
  }
}
