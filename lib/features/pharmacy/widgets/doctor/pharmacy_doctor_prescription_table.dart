import 'package:flutter/material.dart';

/// Doctor prescription table for adding, displaying, and removing prescribed items
class DoctorPrescriptionTable extends StatelessWidget {
  final List<Map<String, String>> prescribedItems;
  final VoidCallback onAddDrug;
  final ValueChanged<Map<String, String>> onRemoveDrug;

  const DoctorPrescriptionTable({
    super.key,
    required this.prescribedItems,
    required this.onAddDrug,
    required this.onRemoveDrug,
  });

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF059669);
    const textPrimary = Color(0xFF0F172A);
    const textMuted = Color(0xFF6D7A72);
    const borderColor = Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'e-Resep Elektronik Obat (R/)',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: textPrimary,
                ),
              ),
              InkWell(
                onTap: onAddDrug,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: emeraldPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle_outline_rounded, size: 14, color: emeraldPrimary),
                      SizedBox(width: 4),
                      Text('+ Tambah Obat', style: TextStyle(fontSize: 11, color: emeraldPrimary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (prescribedItems.isNotEmpty)
            ...prescribedItems.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medication_rounded, size: 18, color: emeraldPrimary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Signa: ${item['signa']}', style: const TextStyle(fontSize: 11, color: textMuted)),
                        ],
                      ),
                    ),
                    Text(
                      item['dose'] ?? '',
                      style: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold, fontSize: 11.5, color: textPrimary),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFBA1A1A)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => onRemoveDrug(item),
                    ),
                  ],
                ),
              );
            })
          else
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.edit_note_rounded, size: 36, color: Colors.grey.shade400),
                  const SizedBox(height: 6),
                  const Text('Belum ada resep obat tertulis.', style: TextStyle(fontSize: 12, color: textMuted)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: onAddDrug,
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Tulis Resep Obat', style: TextStyle(fontSize: 11.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: emeraldPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
