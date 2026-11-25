import 'package:material_ui/material_ui.dart';
import '../../../../core/design/tokens.dart';
import '../../pharmacy_colors.dart';

/// Active ingredients list and weighting calculator table
class CompoundingIngredientsTable extends StatelessWidget {
  final List<Map<String, dynamic>> ingredients;
  final VoidCallback onAddIngredient;
  final ValueChanged<Map<String, dynamic>> onRemoveIngredient;

  const CompoundingIngredientsTable({
    super.key,
    required this.ingredients,
    required this.onAddIngredient,
    required this.onRemoveIngredient,
  });

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = PharmacyColors.primary;
    final textPrimary = context.palette.textPrimary;
    final textMuted = context.palette.textSecondary;
    final borderColor = context.palette.line;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Komposisi Bahan & Kalkulasi Penimbangan',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: textPrimary,
                ),
              ),
              InkWell(
                onTap: onAddIngredient,
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
                      Text(
                        '+ Tambah Bahan',
                        style: TextStyle(fontSize: 11, color: emeraldPrimary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (ingredients.isNotEmpty)
            ...ingredients.map((ing) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.palette.canvas,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.palette.line),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medication_rounded, size: 18, color: emeraldPrimary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ing['name'],
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary),
                          ),
                          Text(
                            'Dosis / bungkus: ${ing['dosePerPack']}',
                            style: TextStyle(fontSize: 11, color: textMuted),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          ing['totalNeeded'],
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Ambil dari stok ${ing['stockUnit']}',
                          style: TextStyle(fontSize: 10, color: textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFBA1A1A)),
                      tooltip: 'Hapus Bahan',
                      onPressed: () => onRemoveIngredient(ing),
                    ),
                  ],
                ),
              );
            })
          else
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.medication_liquid_outlined, size: 36, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada bahan obat racikan.',
                    style: TextStyle(color: textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: onAddIngredient,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Pilih Bahan dari Formularium', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: emeraldPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
