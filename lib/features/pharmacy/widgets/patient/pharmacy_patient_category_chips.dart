import 'package:material_ui/material_ui.dart';
import '../../../../core/design/tokens.dart';
import '../../pharmacy_colors.dart';

/// Choice chips for selecting patient category / insurance provider
class PharmacyPatientCategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelectCategory;

  const PharmacyPatientCategoryChips({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = PharmacyColors.primary;
    final surfaceCanvas = context.palette.canvas;
    final borderColor = context.palette.line;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategori Pasien / Penjamin:',
          style: TextStyle(color: context.palette.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((cat) {
            final isSelected = cat == selectedCategory;
            return ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              selectedColor: emeraldPrimary,
              backgroundColor: surfaceCanvas,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? emeraldPrimary : borderColor,
                ),
              ),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF3D4A42),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 11.5,
              ),
              onSelected: (_) => onSelectCategory(cat),
            );
          }).toList(),
        ),
      ],
    );
  }
}
