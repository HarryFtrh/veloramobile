import 'package:material_ui/material_ui.dart';
import '../../../../core/design/tokens.dart';
import '../../pharmacy_colors.dart';

/// The 7 Benar clinical pharmacy screening checklist
class PrescriptionReviewChecklist extends StatelessWidget {
  final Map<String, bool> screenings;
  final ValueChanged<String> onToggleItem;

  const PrescriptionReviewChecklist({
    super.key,
    required this.screenings,
    required this.onToggleItem,
  });

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = PharmacyColors.primary;
    final borderColor = context.palette.line;
    final textPrimary = context.palette.textPrimary;
    final textMuted = context.palette.textSecondary;

    final passedCount = screenings.values.where((v) => v).length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.surface,
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
                'Telaah Resep Klinis (Standar 7 Benar)',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: passedCount == screenings.length
                      ? const Color(0xFF059669).withValues(alpha: 0.14)
                      : const Color(0xFF0284C7).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$passedCount/${screenings.length} Lolos',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: passedCount == screenings.length ? emeraldPrimary : const Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Lakukan verifikasi klinis farmasetis sebelum obat disiapkan.',
            style: TextStyle(fontSize: 11, color: textMuted),
          ),
          const SizedBox(height: 10),

          ...screenings.entries.map((entry) {
            final isChecked = entry.value;
            return InkWell(
              onTap: () => onToggleItem(entry.key),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: isChecked,
                        activeColor: emeraldPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (_) => onToggleItem(entry.key),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                          color: isChecked ? textPrimary : textMuted,
                        ),
                      ),
                    ),
                    Icon(
                      isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: isChecked ? emeraldPrimary : Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
