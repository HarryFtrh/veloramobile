import '../../shared_pos/pos_checkout_service.dart';

enum ClinicalSafetyLevel {
  safe,
  warning,
  contraindication,
}

class ClinicalSafetyAlert {
  final ClinicalSafetyLevel level;
  final String title;
  final String message;
  final String recommendation;
  final List<String> involvedDrugs;

  const ClinicalSafetyAlert({
    required this.level,
    required this.title,
    required this.message,
    required this.recommendation,
    required this.involvedDrugs,
  });
}

class PharmacyClinicalSafetyService {
  static final PharmacyClinicalSafetyService instance = PharmacyClinicalSafetyService._();
  PharmacyClinicalSafetyService._();

  /// Melakukan telaah resep otomatis: cek alergi pasien dan interaksi antar obat di keranjang
  List<ClinicalSafetyAlert> checkCartSafety({
    required List<PosCartItem> items,
    required String patientAllergies,
  }) {
    final List<ClinicalSafetyAlert> alerts = [];
    final lowerAllergies = patientAllergies.toLowerCase();

    // 1. Skrining Alergi Pasien
    if (patientAllergies.trim().isNotEmpty && patientAllergies != '-') {
      for (final item in items) {
        final drugName = item.name.toLowerCase();

        // Alergi Penisilin / Betalaktam
        if (lowerAllergies.contains('penisilin') || lowerAllergies.contains('penicillin')) {
          if (drugName.contains('amoxicillin') ||
              drugName.contains('amoksisilin') ||
              drugName.contains('ampicillin') ||
              drugName.contains('clavulanat')) {
            alerts.add(ClinicalSafetyAlert(
              level: ClinicalSafetyLevel.contraindication,
              title: 'Alergi Obat: Golongan Penisilin',
              message: 'Pasien memiliki riwayat alergi $patientAllergies. Pemberian ${item.name} berisiko memicu reaksi anafilaksis / hipersensitivitas.',
              recommendation: 'Ganti dengan antibiotik golongan makrolida (Azithromycin/Erythromycin) setelah konfirmasi dokter.',
              involvedDrugs: [item.name],
            ));
          }
        }

        // Alergi NSAID / Ibuprofen / Aspirin
        if (lowerAllergies.contains('nsaid') || lowerAllergies.contains('aspirin') || lowerAllergies.contains('ibuprofen')) {
          if (drugName.contains('ibuprofen') ||
              drugName.contains('ketorolac') ||
              drugName.contains('asam mefenamat') ||
              drugName.contains('mefenamat') ||
              drugName.contains('meloxicam') ||
              drugName.contains('aspirin') ||
              drugName.contains('natrium diklofenak') ||
              drugName.contains('diklofenak')) {
            alerts.add(ClinicalSafetyAlert(
              level: ClinicalSafetyLevel.contraindication,
              title: 'Alergi Obat: Golongan NSAID',
              message: 'Pasien tercatat alergi terhadap NSAID. ${item.name} berpotensi memicu bronkospasme atau syok hipersensitif.',
              recommendation: 'Ganti analgetik dengan Paracetamol murni atau konsultasikan kembali ke dokter spesialis.',
              involvedDrugs: [item.name],
            ));
          }
        }

        // Alergi Paracetamol
        if (lowerAllergies.contains('paracetamol') || lowerAllergies.contains('parasetamol')) {
          if (drugName.contains('paracetamol') || drugName.contains('parasetamol') || drugName.contains('panadol')) {
            alerts.add(ClinicalSafetyAlert(
              level: ClinicalSafetyLevel.contraindication,
              title: 'Alergi Pasien: Parasetamol',
              message: 'Pasien memiliki catatan alergi terhadap Paracetamol.',
              recommendation: 'Hindari obat yang mengandung parasetamol tunggal maupun kombinasi.',
              involvedDrugs: [item.name],
            ));
          }
        }

        // Alergi Sulfa
        if (lowerAllergies.contains('sulfa') || lowerAllergies.contains('sulfonamid')) {
          if (drugName.contains('cotrimoxazole') || drugName.contains('kotrimoksazol') || drugName.contains('sulfamethoxazole')) {
            alerts.add(ClinicalSafetyAlert(
              level: ClinicalSafetyLevel.contraindication,
              title: 'Alergi Pasien: Golongan Sulfa',
              message: 'Pasien memiliki riwayat alergi antibiotik golongan sulfonamida.',
              recommendation: 'Konfirmasikan antibiotik alternatif non-sulfa kepada dokter penulis resep.',
              involvedDrugs: [item.name],
            ));
          }
        }
      }
    }

    // 2. Skrining Interaksi Antar Obat di Keranjang (Drug-Drug Interaction)
    final names = items.map((e) => e.name.toLowerCase()).toList();

    // Interaksi: Ciprofloxacin / Quinolone + Antasida / Logam berat (Penurunan Bioavailabilitas)
    final hasQuinolone = names.any((n) => n.contains('ciprofloxacin') || n.contains('levofloxacin') || n.contains('ofloxacin'));
    final hasAntacid = names.any((n) => n.contains('antasida') || n.contains('mylanta') || n.contains('kalsium') || n.contains('magnesium') || n.contains('promag'));
    if (hasQuinolone && hasAntacid) {
      alerts.add(const ClinicalSafetyAlert(
        level: ClinicalSafetyLevel.warning,
        title: 'Interaksi Penyerapan: Fluorokuinolon + Antasida',
        message: 'Kation logam pada antasida (Al/Mg/Ca) membentuk kelat dengan antibiotik kuinolon sehingga menurunkan penyerapan hingga 85%.',
        recommendation: 'Berikan jeda minum minimal 2 jam sebelum atau 4 jam setelah antasida.',
        involvedDrugs: ['Kuinolon', 'Antasida'],
      ));
    }

    // Interaksi: NSAID ganda atau NSAID + Kortikosteroid (Risiko Ulkus Lambung / Perdarahan GI)
    final hasNsaid = names.any((n) => n.contains('ibuprofen') || n.contains('asam mefenamat') || n.contains('ketorolac') || n.contains('meloxicam') || n.contains('diklofenak'));
    final hasSteroid = names.any((n) => n.contains('dexamethasone') || n.contains('deksametason') || n.contains('prednisone') || n.contains('metilprednisolon'));
    if (hasNsaid && hasSteroid) {
      alerts.add(const ClinicalSafetyAlert(
        level: ClinicalSafetyLevel.warning,
        title: 'Interaksi Aditif: NSAID + Kortikosteroid',
        message: 'Kombinasi NSAID dan kortikosteroid melipatgandakan risiko erosi mukosa lambung dan perdarahan gastrointestinal.',
        recommendation: 'Disarankan penambahan Gastroprotektor (PPI seperti Omeprazole) dan diminum sesudah makan.',
        involvedDrugs: ['NSAID', 'Kortikosteroid'],
      ));
    }

    // Interaksi: Simvastatin + Amlodipine (Peningkatan Konsentrasi Statin)
    final hasSimvastatin = names.any((n) => n.contains('simvastatin'));
    final hasAmlodipine = names.any((n) => n.contains('amlodipine') || n.contains('amlodipin'));
    if (hasSimvastatin && hasAmlodipine) {
      alerts.add(const ClinicalSafetyAlert(
        level: ClinicalSafetyLevel.warning,
        title: 'Interaksi Metabolik: Simvastatin + Amlodipine',
        message: 'Amlodipine menghambat enzim CYP3A4 yang memetabolisme Simvastatin, meningkatkan risiko miopati/rhabdomyolisis.',
        recommendation: 'Batas dosis simvastatin maksimal 20mg/hari saat dikombinasikan dengan amlodipine.',
        involvedDrugs: ['Simvastatin', 'Amlodipine'],
      ));
    }

    // Duplikasi Parasetamol (Kombinasi Flu + Paracetamol tunggal)
    final paracetamolCount = names.where((n) => n.contains('paracetamol') || n.contains('parasetamol') || n.contains('panadol') || n.contains('sanmol') || n.contains('mixagrip') || n.contains('flutamol')).length;
    if (paracetamolCount >= 2) {
      alerts.add(const ClinicalSafetyAlert(
        level: ClinicalSafetyLevel.warning,
        title: 'Peringatan Duplikasi Dosis: Parasetamol',
        message: 'Terdeteksi lebih dari satu produk yang mengandung Paracetamol di keranjang transaksi.',
        recommendation: 'Pastikan total asupan parasetamol harian tidak melebihi 4.000 mg (4 gram) untuk mencegah toksisitas hepar.',
        involvedDrugs: ['Paracetamol Multi-Item'],
      ));
    }

    return alerts;
  }
}
