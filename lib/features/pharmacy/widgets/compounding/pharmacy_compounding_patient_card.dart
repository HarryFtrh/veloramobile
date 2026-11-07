import 'package:flutter/material.dart';

/// Patient context and recipe banner for compounding workstation
class CompoundingPatientRecipeCard extends StatelessWidget {
  final String selectedPatient;
  final String dosageForm;
  final int packageCount;
  final bool isDtd;
  final String signa;

  const CompoundingPatientRecipeCard({
    super.key,
    required this.selectedPatient,
    required this.dosageForm,
    required this.packageCount,
    required this.isDtd,
    required this.signa,
  });

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF059669);
    const textPrimary = Color(0xFF0F172A);
    const textMuted = Color(0xFF6D7A72);
    const borderColor = Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pasien Tujuan:', style: TextStyle(fontSize: 11, color: textMuted)),
                  Text(
                    selectedPatient,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E7FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dosageForm,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: emeraldPrimary,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Jumlah Sediaan Racik:', style: TextStyle(fontSize: 11, color: textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      '$packageCount Bungkus (da in pulv no. XV)',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textPrimary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFDDD6FE), width: 0.8),
                ),
                child: Text(
                  isDtd ? 'Metode: d.t.d (Dosis Tunggal)' : 'Metode: Non-dtd (Bagi Rata)',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Signa: $signa',
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0D9488),
            ),
          ),
        ],
      ),
    );
  }
}
