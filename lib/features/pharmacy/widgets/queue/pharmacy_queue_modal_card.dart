import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../models/pharmacy_domain_models.dart';
import '../pharmacy_patient_dialog.dart';

export '../../models/pharmacy_domain_models.dart' show ClinicPatientQueueItem;

/// Queue item card in the queue modal sheet
class PharmacyQueueModalCard extends StatelessWidget {
  final ClinicPatientQueueItem item;
  final ValueChanged<PharmacyPatientData> onSelect;
  final Color primaryColor;

  const PharmacyQueueModalCard({
    super.key,
    required this.item,
    required this.onSelect,
    this.primaryColor = const Color(0xFF059669),
  });

  @override
  Widget build(BuildContext context) {
    final isReady = item.status == 'ready';
    final isDone = item.status == 'done';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReady ? primaryColor : const Color(0xFFE2E8F0),
          width: isReady ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E7FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.queueNumber,
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.patientName,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isReady
                      ? const Color(0xFFD4F8E8)
                      : (isDone ? const Color(0xFFF1F5F9) : const Color(0xFFEFF6FF)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isReady ? 'Siap Bayar' : (isDone ? 'Selesai' : 'Menunggu Resep'),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isReady
                        ? const Color(0xFF059669)
                        : (isDone ? const Color(0xFF64748B) : const Color(0xFF1D4ED8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Dokter & Poli & RM
          Row(
            children: [
              Text(
                '${item.medicalRecordNumber} • ${item.doctorName}',
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF6D7A72)),
              ),
              const SizedBox(width: 4),
              Text(
                '(${item.department})',
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF6D7A72)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Badges: Asuransi & Alergi
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F3FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.insurance,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF0D9488)),
                ),
              ),
              if (item.allergy != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECEB),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFFFCDD2), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 12),
                      const SizedBox(width: 3),
                      Text(
                        'Alergi: ${item.allergy}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Divider(height: 18, color: Color(0xFFF0F2F5)),

          // Bottom line: Estimasi Biaya & Tombol Pilih ke Kasir
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estimasi Tagihan:', style: TextStyle(fontSize: 10, color: Color(0xFF6D7A72))),
                  Text(
                    CurrencyFormatter.format(item.estimatedTotal),
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  onSelect(
                    PharmacyPatientData(
                      patient: '${item.patientName} (${item.queueNumber})',
                      doctor: item.doctorName,
                      queueNumber: item.queueNumber,
                      medicalRecordNumber: item.medicalRecordNumber,
                      patientCategory: item.insurance,
                      allergies: item.allergy ?? '',
                      prescribedDrugs: item.prescribedDrugs,
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: const Text('Muat ke Kasir', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
