import 'package:flutter/material.dart';
import '../../../../core/design/tokens.dart';

/// Banner Konteks Pasien & Validasi Resep Dokter di Layar Utama POS Apotek
class PharmacyPatientBanner extends StatelessWidget {
  final bool isClinicPatientLoaded;
  final String selectedPatient;
  final String queueNumber;
  final String medicalRecordNumber;
  final String selectedDoctor;
  final String patientAllergies;
  final bool isPrescriptionValidated;
  final VoidCallback onOpenMedicalRecords;
  final VoidCallback onChangePatient;
  final VoidCallback onReviewPrescription;
  final bool isWide;

  const PharmacyPatientBanner({
    super.key,
    required this.isClinicPatientLoaded,
    required this.selectedPatient,
    required this.queueNumber,
    required this.medicalRecordNumber,
    required this.selectedDoctor,
    required this.patientAllergies,
    required this.isPrescriptionValidated,
    required this.onOpenMedicalRecords,
    required this.onChangePatient,
    required this.onReviewPrescription,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    if (isWide && !isClinicPatientLoaded) {
      return const SizedBox.shrink();
    }

    const emeraldPrimary = ClinicalPalette.primary;
    const secondaryTeal = ClinicalPalette.secondary;
    const borderColor = Color(0xFFE2E8F0);
    final isWalkIn = !isClinicPatientLoaded;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Patient Context Strip
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isWalkIn
                      ? emeraldPrimary.withValues(alpha: 0.1)
                      : secondaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isWalkIn ? Icons.storefront_outlined : Icons.badge_outlined,
                  size: 18,
                  color: isWalkIn ? emeraldPrimary : secondaryTeal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isWalkIn ? 'Pelanggan Walk-in (Umum)' : selectedPatient,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isWalkIn
                                ? emeraldPrimary.withValues(alpha: 0.1)
                                : secondaryTeal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isWalkIn ? 'Bebas' : 'Antrean $queueNumber',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isWalkIn ? emeraldPrimary : secondaryTeal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isWalkIn
                          ? 'Penjualan kasir langsung tanpa antrean klinik'
                          : 'No. RM: $medicalRecordNumber • Dokter: ${selectedDoctor != '-' && selectedDoctor.isNotEmpty ? selectedDoctor : 'Resep Luar'}'
                              '${patientAllergies.isNotEmpty ? " • Alergi: $patientAllergies" : ""}',
                      style: TextStyle(
                        fontSize: 11,
                        color: patientAllergies.isNotEmpty ? const Color(0xFFBA1A1A) : const Color(0xFF6D7A72),
                        fontWeight: patientAllergies.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!isWalkIn) ...[
                InkWell(
                  onTap: onOpenMedicalRecords,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF8FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderColor),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.assignment_outlined, size: 14, color: secondaryTeal),
                        SizedBox(width: 4),
                        Text(
                          'Rekam Medis',
                          style: TextStyle(
                            color: secondaryTeal,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              InkWell(
                onTap: onChangePatient,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: isWalkIn ? const Color(0xFFFAF8FF) : const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isWalkIn ? borderColor : const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isWalkIn ? Icons.person_add_alt_1_rounded : Icons.sync_alt_rounded,
                        size: 14,
                        color: isWalkIn ? emeraldPrimary : const Color(0xFFBA1A1A),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isWalkIn ? 'Pilih Pasien' : 'Ganti',
                        style: TextStyle(
                          color: isWalkIn ? emeraldPrimary : const Color(0xFFBA1A1A),
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. Prescription Validation Alert Banner (if loaded from clinic)
        if (isClinicPatientLoaded)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isPrescriptionValidated ? const Color(0xFFF0FDF4) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isPrescriptionValidated ? const Color(0xFFBBF7D0) : const Color(0xFFBFDBFE),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isPrescriptionValidated ? Icons.verified_rounded : Icons.pending_actions_rounded,
                  size: 16,
                  color: isPrescriptionValidated ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isPrescriptionValidated
                        ? 'Resep Elektronik telah divalidasi oleh Apoteker penanggung jawab'
                        : 'Resep Elektronik terhubung • Memerlukan skrining klinis apoteker',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isPrescriptionValidated ? const Color(0xFF166534) : const Color(0xFF1E40AF),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onReviewPrescription,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    isPrescriptionValidated ? 'Lihat Telaah' : 'Skrining Sekarang',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isPrescriptionValidated ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
