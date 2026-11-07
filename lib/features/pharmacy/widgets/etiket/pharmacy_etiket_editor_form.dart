import 'package:flutter/material.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/utils/audio_helper.dart';
import '../../models/pharmacy_etiket_item.dart';

/// Editor form for Etiket Signa: type chips (Putih vs Biru), signa presets, waktu minum, and custom notes
class PharmacyEtiketEditorForm extends StatelessWidget {
  final PharmacyEtiketItem item;
  final List<String> commonSignasOral;
  final List<String> commonSignasLuar;
  final VoidCallback onChanged;

  const PharmacyEtiketEditorForm({
    super.key,
    required this.item,
    required this.commonSignasOral,
    required this.commonSignasLuar,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isLuar = item.isObatLuar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type Selector: Etiket Putih vs Etiket Biru
        Row(
          children: [
            const Text(
              'Jenis Etiket:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: ClinicalPalette.textPrimary),
            ),
            const SizedBox(width: 12),
            ChoiceChip(
              label: const Text('Etiket Putih (Oral/Dalam)'),
              selected: !isLuar,
              selectedColor: const Color(0xFFE2E8F0),
              backgroundColor: const Color(0xFFF1F5F9),
              labelStyle: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
                color: !isLuar ? ClinicalPalette.textPrimary : ClinicalPalette.textTertiary,
              ),
              onSelected: (val) {
                if (val) {
                  item.isObatLuar = false;
                  item.waktuMinum = 'Sesudah Makan';
                  item.signa = '3 x sehari 1 tablet';
                  onChanged();
                }
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Etiket Biru (Obat Luar)'),
              selected: isLuar,
              selectedColor: const Color(0xFFBAE6FD),
              backgroundColor: const Color(0xFFF1F5F9),
              labelStyle: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
                color: isLuar ? const Color(0xFF0369A1) : ClinicalPalette.textTertiary,
              ),
              onSelected: (val) {
                if (val) {
                  item.isObatLuar = true;
                  item.waktuMinum = 'Obat Luar';
                  item.signa = 'Oleskan tipis 2x sehari pada area sakit';
                  onChanged();
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Preset Signa Chips
        const Text(
          'Pilih Aturan Pakai Cepat (Signa):',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: ClinicalPalette.textSecondary),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: (isLuar ? commonSignasLuar : commonSignasOral).map((s) {
            final isCur = item.signa == s;
            return InkWell(
              onTap: () {
                AudioHelper.tapFeedback();
                item.signa = s;
                onChanged();
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isCur ? ClinicalPalette.primary.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isCur ? ClinicalPalette.primary : ClinicalPalette.border,
                  ),
                ),
                child: Text(
                  s,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontWeight: isCur ? FontWeight.bold : FontWeight.normal,
                    color: isCur ? ClinicalPalette.primary : ClinicalPalette.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Waktu Minum Selector (for Oral)
        if (!isLuar) ...[
          const Text(
            'Keterangan Waktu Minum:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: ClinicalPalette.textSecondary),
          ),
          const SizedBox(height: 6),
          Row(
            children: ['Sesudah Makan', 'Sebelum Makan', 'Bersama Makanan'].map((w) {
              final isSel = item.waktuMinum == w;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(w),
                  selected: isSel,
                  selectedColor: ClinicalPalette.primary,
                  backgroundColor: const Color(0xFFF1F5F9),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSel ? Colors.white : ClinicalPalette.textPrimary,
                  ),
                  onSelected: (val) {
                    if (val) {
                      item.waktuMinum = w;
                      onChanged();
                    }
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
