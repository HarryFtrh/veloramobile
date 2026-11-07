import 'package:flutter/material.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../models/pharmacy_payment_mode.dart';

/// Bottom action footer with auto-print toggle and primary settlement CTA
class PharmacyCheckoutActionFooter extends StatelessWidget {
  final bool autoPrintReceipt;
  final ValueChanged<bool> onToggleAutoPrint;
  final PharmacyPaymentMode selectedMode;
  final num changeAmount;
  final num grandTotal;
  final bool isProcessing;
  final VoidCallback onProcessSettlement;

  const PharmacyCheckoutActionFooter({
    super.key,
    required this.autoPrintReceipt,
    required this.onToggleAutoPrint,
    required this.selectedMode,
    required this.changeAmount,
    required this.grandTotal,
    required this.isProcessing,
    required this.onProcessSettlement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: ClinicalPalette.border)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: autoPrintReceipt,
                      activeColor: ClinicalPalette.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) => onToggleAutoPrint(val ?? true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Cetak struk kasir & etiket otomatis',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: ClinicalPalette.textPrimary,
                    ),
                  ),
                ],
              ),
              if (selectedMode == PharmacyPaymentMode.cash && changeAmount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Text(
                    'Kembalian: ${CurrencyFormatter.formatRupiah(changeAmount)}',
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: ClinicalPalette.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Big Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isProcessing ? null : onProcessSettlement,
              style: ElevatedButton.styleFrom(
                backgroundColor: ClinicalPalette.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: ClinicalPalette.primary.withValues(alpha: 0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'SELESAIKAN & CETAK STRUK (${CurrencyFormatter.formatRupiah(grandTotal)})',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mobile sticky bottom bar for small screens
class PharmacyCheckoutMobileStickyBottomBar extends StatelessWidget {
  final bool isProcessing;
  final num grandTotal;
  final VoidCallback onProcessSettlement;

  const PharmacyCheckoutMobileStickyBottomBar({
    super.key,
    required this.isProcessing,
    required this.grandTotal,
    required this.onProcessSettlement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: ClinicalPalette.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: isProcessing ? null : onProcessSettlement,
          style: ElevatedButton.styleFrom(
            backgroundColor: ClinicalPalette.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: isProcessing
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
                  'SELESAIKAN (${CurrencyFormatter.formatRupiah(grandTotal)})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
        ),
      ),
    );
  }
}
