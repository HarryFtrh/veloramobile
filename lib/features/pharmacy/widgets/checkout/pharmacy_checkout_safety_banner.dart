import 'package:flutter/material.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/utils/audio_helper.dart';
import '../../services/pharmacy_clinical_safety_service.dart';

/// Clinical Safety Alert Banner for pharmacy checkout & cart verification
class PharmacyCheckoutSafetyBanner extends StatelessWidget {
  final List<ClinicalSafetyAlert> safetyAlerts;
  final bool isClinicalReviewAcknowledged;
  final ValueChanged<bool> onToggleAcknowledged;
  final EdgeInsetsGeometry margin;

  const PharmacyCheckoutSafetyBanner({
    super.key,
    required this.safetyAlerts,
    required this.isClinicalReviewAcknowledged,
    required this.onToggleAcknowledged,
    this.margin = const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    if (safetyAlerts.isEmpty) {
      return Container(
        margin: margin,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: const [
            Icon(Icons.verified_user_rounded, color: ClinicalPalette.primary, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Skrining Klinis Lolos: Tidak terdeteksi interaksi mayor atau kontraindikasi alergi pasien.',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11.5,
                  color: ClinicalPalette.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final hasContra = safetyAlerts.any((a) => a.level == ClinicalSafetyLevel.contraindication);
    final borderColor = hasContra ? const Color(0xFFFECACA) : const Color(0xFFFED7AA);
    final bgColor = hasContra ? const Color(0xFFFEF2F2) : const Color(0xFFFFF7ED);
    final iconColor = hasContra ? ClinicalPalette.danger : ClinicalPalette.warning;

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                iconColor == ClinicalPalette.danger ? Icons.gpp_bad_rounded : Icons.warning_rounded,
                color: iconColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasContra ? 'PERINGATAN KONTRAINDIKASI ALERGI PASIEN' : 'PERHATIAN INTERAKSI OBAT KLINIS',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: iconColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${safetyAlerts.length} Peringatan',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ...safetyAlerts.map((alert) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ${alert.title}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: iconColor),
                  ),
                  Text(
                    alert.message,
                    style: TextStyle(fontSize: 11, color: ClinicalPalette.textPrimary.withValues(alpha: 0.85)),
                  ),
                  Text(
                    'Saran: ${alert.recommendation}',
                    style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: ClinicalPalette.textSecondary),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 6),
          InkWell(
            onTap: () {
              AudioHelper.tapFeedback();
              onToggleAcknowledged(!isClinicalReviewAcknowledged);
            },
            child: Row(
              children: [
                SizedBox(
                  height: 20,
                  width: 20,
                  child: Checkbox(
                    value: isClinicalReviewAcknowledged,
                    activeColor: ClinicalPalette.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (v) => onToggleAcknowledged(v ?? false),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Telaah Apoteker: Verifikasi Resep Aman Dilanjutkan',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: ClinicalPalette.textPrimary,
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
