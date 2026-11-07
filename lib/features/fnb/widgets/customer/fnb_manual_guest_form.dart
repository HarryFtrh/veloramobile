import 'package:flutter/material.dart';
import '../../../../core/design/tokens.dart';

/// Form tab for typing manual guest names and applying custom discount
class FnbManualGuestForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController discountController;
  final VoidCallback onApply;
  final ValueChanged<String> onSelectPreset;
  final ValueChanged<int> onSelectQuickDiscount;

  const FnbManualGuestForm({
    super.key,
    required this.nameController,
    required this.discountController,
    required this.onApply,
    required this.onSelectPreset,
    required this.onSelectQuickDiscount,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nama Pemesan / Meja',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.textPrimary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: 'Mis. Pak Bambang, Tamu Meja 4, Rombongan A',
              prefixIcon: const Icon(Icons.person_pin_rounded),
              filled: true,
              fillColor: p.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Preset Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPresetChip('Walk-In', p),
              _buildPresetChip('Tamu Spesial', p),
              _buildPresetChip('VIP Lounge', p),
              _buildPresetChip('Takeaway', p),
            ],
          ),

          const SizedBox(height: 20),
          Text(
            'Diskon Khusus (%) - Opsional',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.textPrimary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: discountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Mis. 10 (untuk 10%)',
              prefixIcon: const Icon(Icons.percent_rounded),
              filled: true,
              fillColor: p.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Quick Discount Buttons
          Row(
            children: [
              _buildDiscountQuickBtn(0, p, primaryColor),
              const SizedBox(width: 8),
              _buildDiscountQuickBtn(5, p, primaryColor),
              const SizedBox(width: 8),
              _buildDiscountQuickBtn(10, p, primaryColor),
              const SizedBox(width: 8),
              _buildDiscountQuickBtn(15, p, primaryColor),
              const SizedBox(width: 8),
              _buildDiscountQuickBtn(20, p, primaryColor),
            ],
          ),

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 1,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Terapkan Nama Pelanggan',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, AppPalette p) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      backgroundColor: p.surfaceMuted,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onPressed: () => onSelectPreset(label),
    );
  }

  Widget _buildDiscountQuickBtn(int percent, AppPalette p, Color primaryColor) {
    final isSelected = discountController.text.trim() == percent.toString() ||
        (percent == 0 && (discountController.text.trim().isEmpty || discountController.text.trim() == '0'));

    return Expanded(
      child: OutlinedButton(
        onPressed: () => onSelectQuickDiscount(percent),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          backgroundColor: isSelected ? primaryColor : p.surface,
          foregroundColor: isSelected ? Colors.white : p.textPrimary,
          side: BorderSide(
            color: isSelected ? primaryColor : p.line,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          '$percent%',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
