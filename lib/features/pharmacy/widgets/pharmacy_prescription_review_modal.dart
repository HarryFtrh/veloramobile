import 'package:flutter/material.dart';

class PharmacyPrescriptionReviewModal extends StatefulWidget {
  final VoidCallback? onApprove;
  final bool showDragHandle;

  const PharmacyPrescriptionReviewModal({super.key, this.onApprove, this.showDragHandle = true});

  static Future<void> show(BuildContext context, {VoidCallback? onApprove}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
          maxWidth: 620,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAF8FF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: PharmacyPrescriptionReviewModal(onApprove: onApprove),
        ),
      ),
    );
  }

  @override
  State<PharmacyPrescriptionReviewModal> createState() => _PharmacyPrescriptionReviewModalState();
}

class _PharmacyPrescriptionReviewModalState extends State<PharmacyPrescriptionReviewModal> {
  // 7 Benar Skrining Checklist
  final Map<String, bool> _screenings = {
    'Tepat Identitas Pasien & Umur': true,
    'Tepat Indikasi & Diagnosis Klinis': true,
    'Tepat Obat & Sediaan Farmasetis': true,
    'Tepat Dosis & Frekuensi Pemberian': true,
    'Tepat Cara & Rute Pemberian (Signa)': true,
    'Tidak Ada Duplikasi / Interaksi Obat': true,
    'Tidak Ada Kontraindikasi / Alergi': true,
  };

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF006948);
    const borderColor = Color(0xFFE2E8F0);
    const textPrimary = Color(0xFF131B2E);
    const textMuted = Color(0xFF6D7A72);

    final allPassed = _screenings.values.every((v) => v);

    return Column(
      children: [
        // Drag handle & Header
        if (widget.showDragHandle)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF006A61).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.assignment_outlined, color: Color(0xFF006A61), size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Telaah Klinis Resep Dokter',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'Skrining 7 Benar Farmasi & Validasi SIP',
                              style: TextStyle(fontSize: 11, color: textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const Divider(height: 1, color: borderColor),

        // Scrollable Body
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Ticket Status Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'E-PRESCRIPTION #ERX-2024-8841',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF006577),
                          ),
                        ),
                        Text(
                          'Poli Penyakit Dalam • Waktu: 10:24 WIB',
                          style: TextStyle(fontSize: 11, color: textMuted),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF86F2E4).withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 6, color: Color(0xFF006F66)),
                          SizedBox(width: 4),
                          Text(
                            'Dalam Telaah',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF006F66),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Patient & Physician Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E7FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'DL',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF006948),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Ny. Dewi Lestari (P / 34 th)',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                'No. Rekam Medis: RM-08234 • BPJS Kesehatan',
                                style: TextStyle(fontSize: 11, color: textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: const [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Diagnosis DPJP:', style: TextStyle(fontSize: 11, color: textMuted)),
                              Text('Faringitis Akut (J02.9)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textPrimary)),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Dokter Perujuk:', style: TextStyle(fontSize: 11, color: textMuted)),
                              Text('dr. Hendra Sp.PD (SIP: 446/2021/SIP.DOK)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Allergy Safety Banner
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFDAD6).withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                        border: const Border(left: BorderSide(color: Color(0xFFBA1A1A), width: 3)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFBA1A1A)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Alergi Terdaftar: Penicillin',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFBA1A1A)),
                                ),
                                Text(
                                  'Pemeriksaan keamanan: Tidak ada golongan penicillin dalam R/ ini. Aman disiapkan.',
                                  style: TextStyle(fontSize: 10.5, color: textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Prescribed Medicines Section
              const Text(
                'Daftar R/ Obat Pasien (3 Item)',
                style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              const SizedBox(height: 8),

              // Rx 1: Cefixime
              _buildPrescriptionItem(
                rxNumber: 'Rx 1',
                title: 'Cefixime 100mg Kapsul',
                qty: 'Jumlah: 10 Kapsul',
                signa: 'S 2 dd 1 cap pc (Habiskan)',
                signaDesc: 'Diminum 2x sehari 1 kaplet setelah makan. Harus dihabiskan.',
                batch: 'CFX-2024A',
                isRacikan: false,
              ),
              const SizedBox(height: 8),

              // Rx 2: Paracetamol
              _buildPrescriptionItem(
                rxNumber: 'Rx 2',
                title: 'Paracetamol 500mg',
                qty: 'Jumlah: 10 Tablet',
                signa: 'S 3 dd 1 tab prn (Bila demam/nyeri)',
                signaDesc: 'Diminum 3x sehari 1 tablet hanya jika demam / nyeri.',
                batch: 'PCT-9921B',
                isRacikan: false,
              ),
              const SizedBox(height: 8),

              // Rx 3: Racikan Pulveres
              _buildPrescriptionItem(
                rxNumber: 'Rx 3 RACIKAN',
                title: 'Pulveres Batuk / Puyer Perkamen',
                qty: 'Kemasan: 15 Bungkus (Etiket Putih)',
                signa: 'S 3 dd 1 pulv pc',
                signaDesc: 'Formula: Ambroxol 30mg (7.5 Tab), Dexamethasone 0.5mg (7.5 Tab), Cetirizine 10mg (5 Tab). Haluskan homogen.',
                batch: 'RACIK-P01',
                isRacikan: true,
              ),
              const SizedBox(height: 14),

              // Skrining 7 Benar Checklist
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kajian Skrining 7 Benar Farmasi',
                          style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: allPassed ? emeraldPrimary.withValues(alpha: 0.1) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            allPassed ? 'LENGKAP' : 'BELUM VALID',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: allPassed ? emeraldPrimary : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ..._screenings.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _screenings[entry.key] = !entry.value;
                            });
                          },
                          child: Row(
                            children: [
                              Icon(
                                entry.value ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                size: 18,
                                color: entry.value ? emeraldPrimary : textMuted,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: entry.value ? FontWeight.w600 : FontWeight.normal,
                                    color: entry.value ? textPrimary : textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bottom CTA
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Etiket aturan pakai (putih & biru) dikirim ke thermal printer.')),
                      );
                    },
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text('Cetak Etiket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF006A61),
                      side: const BorderSide(color: Color(0xFF006A61)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: allPassed
                        ? () {
                            Navigator.pop(context);
                            widget.onApprove?.call();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Telaah resep tervalidasi! R/ obat siap diracik & diserahkan.'),
                                backgroundColor: Color(0xFF006948),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.verified_rounded, size: 18),
                    label: const Text('Validasi & Siapkan Obat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: emeraldPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrescriptionItem({
    required String rxNumber,
    required String title,
    required String qty,
    required String signa,
    required String signaDesc,
    required String batch,
    required bool isRacikan,
  }) {
    const emeraldPrimary = Color(0xFF006948);
    const borderColor = Color(0xFFE2E8F0);
    const textPrimary = Color(0xFF131B2E);
    const textMuted = Color(0xFF6D7A72);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isRacikan ? emeraldPrimary.withValues(alpha: 0.4) : borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isRacikan ? emeraldPrimary : const Color(0xFF131B2E),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      rxNumber,
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                qty,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 13, color: emeraldPrimary),
                    const SizedBox(width: 4),
                    Text(
                      signa,
                      style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: FontWeight.bold, color: emeraldPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  signaDesc,
                  style: const TextStyle(fontSize: 10.5, color: textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Batch: $batch',
                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, color: textMuted),
              ),
              const Text(
                'FEFO Stok Tersedia',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: emeraldPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Standalone Full Page Version for AppShell MoreScreen
class PharmacyPrescriptionReviewPage extends StatelessWidget {
  final VoidCallback? onApprove;

  const PharmacyPrescriptionReviewPage({super.key, this.onApprove});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        title: const Text(
          'Telaah Resep Dokter & Skrining',
          style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF131B2E),
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: SafeArea(
        child: PharmacyPrescriptionReviewModal(
          onApprove: () {
            if (onApprove != null) {
              onApprove!();
            } else {
              Navigator.pop(context);
            }
          },
          showDragHandle: false,
        ),
      ),
    );
  }
}
