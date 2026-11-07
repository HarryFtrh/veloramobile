import 'package:flutter/material.dart';
import '../../../../core/storage/session_storage.dart';

/// Real-time live etiket preview card for Compounding workstation
class CompoundingEtiketPreviewCard extends StatelessWidget {
  final String labelType;
  final String selectedPatient;
  final String signa;
  final ValueChanged<String> onSelectLabelType;

  const CompoundingEtiketPreviewCard({
    super.key,
    required this.labelType,
    required this.selectedPatient,
    required this.signa,
    required this.onSelectLabelType,
  });

  @override
  Widget build(BuildContext context) {
    const textMuted = Color(0xFF6D7A72);
    final isPutih = labelType == 'putih';
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPutih ? Colors.white : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPutih ? const Color(0xFF059669) : const Color(0xFF2563EB),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ETIKET ${isPutih ? 'PUTIH (OBAT DALAM / ORAL)' : 'BIRU (OBAT LUAR)'}',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: isPutih ? const Color(0xFF059669) : const Color(0xFF2563EB),
                ),
              ),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Putih (Oral)', style: TextStyle(fontSize: 11)),
                    selected: isPutih,
                    onSelected: (val) {
                      if (val) onSelectLabelType('putih');
                    },
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('Biru (Luar)', style: TextStyle(fontSize: 11)),
                    selected: !isPutih,
                    onSelected: (val) {
                      if (val) onSelectLabelType('biru');
                    },
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 14),
          Text(
            (SessionStorage.instance.getTenantName() ?? SessionStorage.instance.getLocationName() ?? 'APOTEK VELORA').toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const Text('SIP & Surat Izin Apotek Aktif Berizin Resmi', style: TextStyle(fontSize: 9.5, color: textMuted)),
          const SizedBox(height: 8),
          Text(
            'No. Resep: R/${now.year}${now.month.toString().padLeft(2, "0")}-${now.second.toString().padLeft(3, "0")}  •  Tgl: ${now.day}/${now.month}/${now.year}',
            style: const TextStyle(fontSize: 10.5, fontFamily: 'JetBrains Mono'),
          ),
          Text('Pasien: $selectedPatient', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              signa,
              style: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
            ),
          ),
          const SizedBox(height: 6),
          const Text('Kocok Dahulu / Simpan di Tempat Sejuk & Kering Terlindung dari Cahaya', style: TextStyle(fontSize: 9.5, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}
