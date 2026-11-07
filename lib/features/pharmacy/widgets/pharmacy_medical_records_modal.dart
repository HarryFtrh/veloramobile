import 'package:flutter/material.dart';
import '../pharmacy_service.dart';
import 'records/pharmacy_medication_history_tile.dart';
import 'records/pharmacy_patient_record_profile_card.dart';

export 'records/pharmacy_medication_history_tile.dart';
export 'records/pharmacy_patient_record_profile_card.dart';

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
  PharmacyPatientData? _selectedPatient;
  final TextEditingController _searchCtrl = TextEditingController();
  List<PharmacyPatientData> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _selectedPatient = widget.patientData ?? PharmacyService.instance.activePatient.value;
    _loadHistory();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final active = _selectedPatient ?? widget.patientData ?? PharmacyService.instance.activePatient.value;
    final rm = widget.initialRm ?? (active?.medicalRecordNumber.isNotEmpty == true ? active!.medicalRecordNumber : '');
    final list = await PharmacyService.instance.fetchPatientMedicationHistory(rm.isNotEmpty ? rm : 'active');
    if (mounted) {
      setState(() {
        _history = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _onSearchPatient(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final res = await PharmacyService.instance.searchPatientsScout(q.trim());
    if (mounted) {
      setState(() => _searchResults = res);
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
            final active = _selectedPatient ?? widget.patientData ?? PharmacyService.instance.activePatient.value;
            final patientName = (widget.patientName != null && widget.patientName!.isNotEmpty && _selectedPatient == null)
                ? widget.patientName!
                : (active?.patient.isNotEmpty == true ? active!.patient : 'Pelanggan Umum (Walk-in)');
            final rmNumber = (widget.initialRm != null && widget.initialRm!.isNotEmpty && widget.initialRm != '-' && _selectedPatient == null)
                ? widget.initialRm!
                : (active?.medicalRecordNumber.isNotEmpty == true && active!.medicalRecordNumber != '-' ? active.medicalRecordNumber : '-');
            final category = (active?.patientCategory.isNotEmpty == true) ? active!.patientCategory : 'Umum';
            final allergies = (active?.allergies.trim().isNotEmpty == true) ? active!.allergies.trim() : '';

            return Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Search Patient RM Bar
                  TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchPatient,
                    decoration: InputDecoration(
                      hintText: 'Cari nama pasien atau No. RM...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: borderColor),
                      ),
                    ),
                  ),
                  if (_searchResults.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: _searchResults.take(4).map((p) {
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.person_outline_rounded, color: emeraldPrimary, size: 18),
                            title: Text(p.patient, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                            subtitle: Text('RM: ${p.medicalRecordNumber} • ${p.patientCategory}', style: const TextStyle(fontSize: 11)),
                            onTap: () {
                              setState(() {
                                _selectedPatient = p;
                                _searchResults = [];
                                _searchCtrl.clear();
                                _isLoading = true;
                              });
                              PharmacyService.instance.setActivePatient(p);
                              _loadHistory();
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Patient Profile Card
                  PharmacyPatientRecordProfileCard(
                    patientName: patientName,
                    rmNumber: rmNumber,
                    category: category,
                    allergies: allergies,
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
                    ..._history.map((hist) => PharmacyMedicationHistoryTile(
                          history: hist,
                          onRepeatPrescription: widget.onRepeatPrescription != null
                              ? (meds) {
                                  Navigator.pop(context);
                                  widget.onRepeatPrescription!(meds);
                                }
                              : null,
                        ))
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
