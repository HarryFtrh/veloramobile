import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../pharmacy_service.dart';

/// Tile displaying an individual patient medication visit history and repeat prescription action
class PharmacyMedicationHistoryTile extends StatelessWidget {
  final PharmacyPatientHistory history;
  final ValueChanged<List<String>>? onRepeatPrescription;

  const PharmacyMedicationHistoryTile({
    super.key,
    required this.history,
    this.onRepeatPrescription,
  });

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF059669);
    const borderColor = Color(0xFFE2E8F0);
    const textPrimary = Color(0xFF0F172A);
    const textMuted = Color(0xFF6D7A72);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                history.visitDate,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              Text(
                history.invoiceNumber,
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: emeraldPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Dokter: ${history.doctorName} • Diagnosis: ${history.diagnosis}',
            style: const TextStyle(fontSize: 11, color: textMuted),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: history.medicines
                  .map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 5, color: emeraldPrimary),
                            const SizedBox(width: 6),
                            Text(m, style: const TextStyle(fontSize: 11, color: textPrimary)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Tebus: ${CurrencyFormatter.format(history.total)}',
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              if (onRepeatPrescription != null)
                InkWell(
                  onTap: () => onRepeatPrescription!(history.medicines),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.repeat_rounded, size: 12, color: emeraldPrimary),
                        SizedBox(width: 4),
                        Text(
                          'Ulangi Resep',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: emeraldPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
