import 'package:flutter/material.dart';

/// Patient profile card with clinical allergy alert ribbon
class PharmacyPatientRecordProfileCard extends StatelessWidget {
  final String patientName;
  final String rmNumber;
  final String category;
  final String allergies;

  const PharmacyPatientRecordProfileCard({
    super.key,
    required this.patientName,
    required this.rmNumber,
    required this.category,
    required this.allergies,
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E7FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.person, color: emeraldPrimary, size: 24),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          patientName,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            rmNumber,
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
                    const SizedBox(height: 2),
                    Text(
                      'Kategori: $category • No. RM: $rmNumber',
                      style: const TextStyle(fontSize: 11, color: textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Allergy Alert Ribbon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: allergies.isNotEmpty
                  ? const Color(0xFFFFDAD6).withValues(alpha: 0.35)
                  : const Color(0xFF059669).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(
                  color: allergies.isNotEmpty ? const Color(0xFFBA1A1A) : const Color(0xFF059669),
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  allergies.isNotEmpty ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                  size: 18,
                  color: allergies.isNotEmpty ? const Color(0xFFBA1A1A) : const Color(0xFF059669),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    allergies.isNotEmpty
                        ? 'Alergi Terdaftar: $allergies (Kritis)'
                        : 'Tidak ada riwayat alergi obat terdaftar (Aman)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: allergies.isNotEmpty ? const Color(0xFFBA1A1A) : const Color(0xFF059669),
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
