import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../pharmacy_service.dart';
import 'pharmacy_patient_dialog.dart';

class PharmacyMedicalRecordsModal extends StatefulWidget {
  final String? initialRm;
  final String? patientName;
  final PharmacyPatientData? patientData;
  final Function(List<String> medicines)? onRepeatPrescription;
  final bool showDragHandle;

  const PharmacyMedicalRecordsModal({
    super.key,
    this.initialRm,
    this.patientName,
    this.patientData,
    this.onRepeatPrescription,
    this.showDragHandle = true,
  });

  static Future<void> show(
    BuildContext context, {
    String? initialRm,
    String? patientName,
    PharmacyPatientData? patientData,
    Function(List<String> medicines)? onRepeatPrescription,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 620,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAF8FF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: PharmacyMedicalRecordsModal(
            initialRm: initialRm,
            patientName: patientName,
            patientData: patientData,
            onRepeatPrescription: onRepeatPrescription,
          ),
        ),
      ),
    );
  }

  @override
  State<PharmacyMedicalRecordsModal> createState() => _PharmacyMedicalRecordsModalState();
}

class _PharmacyMedicalRecordsModalState extends State<PharmacyMedicalRecordsModal> {
  bool _isLoading = true;
  List<PharmacyPatientHistory> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final active = widget.patientData ?? PharmacyService.instance.activePatient.value;
    final rm = widget.initialRm ?? (active?.medicalRecordNumber.isNotEmpty == true ? active!.medicalRecordNumber : '');
    final list = await PharmacyService.instance.fetchPatientMedicationHistory(rm.isNotEmpty ? rm : 'active');
    if (mounted) {
      setState(() {
        _history = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF059669);
    const borderColor = Color(0xFFE2E8F0);
    const textPrimary = Color(0xFF0F172A);
    const textMuted = Color(0xFF6D7A72);

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
                            color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.assignment_outlined, color: Color(0xFF0D9488), size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rekam Medis & Riwayat Obat',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'Histori Pengobatan Pasien & Alert Alergi',
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

        Builder(
          builder: (context) {
            final active = widget.patientData ?? PharmacyService.instance.activePatient.value;
            final patientName = (widget.patientName != null && widget.patientName!.isNotEmpty)
                ? widget.patientName!
                : (active?.patient.isNotEmpty == true ? active!.patient : 'Pelanggan Umum (Walk-in)');
            final rmNumber = (widget.initialRm != null && widget.initialRm!.isNotEmpty && widget.initialRm != '-')
                ? widget.initialRm!
                : (active?.medicalRecordNumber.isNotEmpty == true && active!.medicalRecordNumber != '-' ? active.medicalRecordNumber : '-');
            final category = (active?.patientCategory.isNotEmpty == true) ? active!.patientCategory : 'Umum';
            final allergies = (active?.allergies.trim().isNotEmpty == true) ? active!.allergies.trim() : '';

            return Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Patient Profile Card
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
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E7FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Icon(Icons.person, color: emeraldPrimary, size: 24),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        patientName,
                                        style: const TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF86F2E4).withValues(alpha: 0.4),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          rmNumber,
                                          style: const TextStyle(
                                            fontFamily: 'JetBrains Mono',
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF006F66),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Kategori: $category • No. RM: $rmNumber',
                                    style: const TextStyle(fontSize: 11, color: textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Allergy Alert Ribbon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: allergies.isNotEmpty
                                ? const Color(0xFFFFDAD6).withValues(alpha: 0.35)
                                : const Color(0xFF059669).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              left: BorderSide(
                                color: allergies.isNotEmpty ? const Color(0xFFBA1A1A) : const Color(0xFF059669),
                                width: 3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                allergies.isNotEmpty ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                                size: 18,
                                color: allergies.isNotEmpty ? const Color(0xFFBA1A1A) : const Color(0xFF059669),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  allergies.isNotEmpty
                                      ? 'Alergi Terdaftar: $allergies (Kritis)'
                                      : 'Tidak ada riwayat alergi obat terdaftar (Aman)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: allergies.isNotEmpty ? const Color(0xFFBA1A1A) : const Color(0xFF059669),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Medication History Header
                  const Text(
                    'Riwayat Pengambilan Obat & Kunjungan Poli',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: emeraldPrimary)))
                  else if (_history.isNotEmpty)
                    ..._history.map((hist) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
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
                            Text(
                              hist.visitDate,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              hist.invoiceNumber,
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: emeraldPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dokter: ${hist.doctorName} • Diagnosis: ${hist.diagnosis}',
                          style: const TextStyle(fontSize: 11, color: textMuted),
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
                            children: hist.medicines
                                .map((m) => Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.circle, size: 5, color: emeraldPrimary),
                                          const SizedBox(width: 6),
                                          Text(m, style: const TextStyle(fontSize: 11, color: textPrimary)),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Tebus: ${CurrencyFormatter.format(hist.total)}',
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                widget.onRepeatPrescription?.call(hist.medicines);
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFBBF7D0)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.repeat_rounded, size: 12, color: emeraldPrimary),
                                    SizedBox(width: 4),
                                    Text(
                                      'Ulangi Resep',
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: emeraldPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                })
              else
                Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.history_toggle_off_rounded, size: 36, color: textMuted),
                        SizedBox(height: 8),
                        Text(
                          'Belum ada riwayat rekam medis pasien',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Histori kunjungan poli dan pengambilan obat pasien akan tercatat secara otomatis setelah transaksi selesai.',
                          style: TextStyle(fontSize: 11, color: textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
      ],
    );
  }
}

/// Standalone Full Page Version for AppShell MoreScreen
class PharmacyMedicalRecordsPage extends StatelessWidget {
  final String? initialRm;
  final String? patientName;

  const PharmacyMedicalRecordsPage({
    super.key,
    this.initialRm,
    this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        title: const Text(
          'Rekam Medis & Riwayat Pasien',
          style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: SafeArea(
        child: PharmacyMedicalRecordsModal(
          initialRm: initialRm,
          patientName: patientName,
          showDragHandle: false,
        ),
      ),
    );
  }
}
