import 'package:flutter/material.dart';

/// Patient context, initials avatar, doctor perujuk, and allergy warning banner for prescription review
class PrescriptionReviewPatientCard extends StatelessWidget {
  final String patientName;
  final String rmNumber;
  final String category;
  final String doctorName;
  final String allergies;
  final String displayInitials;

  const PrescriptionReviewPatientCard({
    super.key,
    required this.patientName,
    required this.rmNumber,
    required this.category,
    required this.doctorName,
    required this.allergies,
    required this.displayInitials,
  });

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF059669);
    const borderColor = Color(0xFFE2E8F0);
    const textPrimary = Color(0xFF0F172A);
    const textMuted = Color(0xFF6D7A72);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E7FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    displayInitials,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.bold,
                      color: emeraldPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'No. Rekam Medis: $rmNumber • $category',
                      style: const TextStyle(fontSize: 11, color: textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Layanan:', style: TextStyle(fontSize: 11, color: textMuted)),
                    Text('Dispensasi Obat Farmasi', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textPrimary)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Dokter Perujuk:', style: TextStyle(fontSize: 11, color: textMuted)),
                    Text(doctorName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Allergy Safety Banner
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: allergies.isNotEmpty
                  ? const Color(0xFFFFDAD6).withValues(alpha: 0.35)
                  : emeraldPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(
                  color: allergies.isNotEmpty ? const Color(0xFFBA1A1A) : emeraldPrimary,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  allergies.isNotEmpty ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                  size: 18,
                  color: allergies.isNotEmpty ? const Color(0xFFBA1A1A) : emeraldPrimary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        allergies.isNotEmpty
                            ? 'Alergi Terdaftar: $allergies'
                            : 'Tidak Ada Riwayat Alergi (Aman)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: allergies.isNotEmpty ? const Color(0xFFBA1A1A) : emeraldPrimary,
                        ),
                      ),
                      Text(
                        allergies.isNotEmpty
                            ? 'Pemeriksaan keamanan: Verifikasi interaksi & kontraindikasi obat sebelum penyerahan.'
                            : 'Pemeriksaan keamanan: Pasien tidak memiliki riwayat alergi obat terdaftar.',
                        style: const TextStyle(fontSize: 10.5, color: textMuted),
                      ),
                    ],
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
