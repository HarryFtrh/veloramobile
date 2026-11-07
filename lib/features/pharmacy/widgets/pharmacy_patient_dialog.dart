import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../pharmacy_service.dart';
import 'patient/pharmacy_patient_category_chips.dart';
import 'patient/pharmacy_patient_autocomplete.dart';

export '../models/pharmacy_patient_data.dart';
export 'patient/pharmacy_patient_category_chips.dart';
export 'patient/pharmacy_patient_autocomplete.dart';

class PharmacyPatientDialog extends StatefulWidget {
  final String initialPatient;
  final String initialDoctor;
  final String? initialQueueNumber;
  final String? initialMedicalRecordNumber;
  final String? initialAllergies;
  final ValueChanged<PharmacyPatientData> onSave;

  const PharmacyPatientDialog({
    super.key,
    required this.initialPatient,
    required this.initialDoctor,
    this.initialQueueNumber,
    this.initialMedicalRecordNumber,
    this.initialAllergies,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required String initialPatient,
    required String initialDoctor,
    String? initialQueueNumber,
    String? initialMedicalRecordNumber,
    String? initialAllergies,
    required ValueChanged<PharmacyPatientData> onSave,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => PharmacyPatientDialog(
        initialPatient: initialPatient,
        initialDoctor: initialDoctor,
        initialQueueNumber: initialQueueNumber,
        initialMedicalRecordNumber: initialMedicalRecordNumber,
        initialAllergies: initialAllergies,
        onSave: onSave,
      ),
    );
  }

  @override
  State<PharmacyPatientDialog> createState() => _PharmacyPatientDialogState();
}

class _PharmacyPatientDialogState extends State<PharmacyPatientDialog> {
  late final TextEditingController _patientController;
  late final TextEditingController _doctorController;
  late final TextEditingController _queueController;
  late final TextEditingController _rmController;
  late final TextEditingController _allergiesController;
  late final TextEditingController _nikController;
  bool _pdpConsent = true;
  late String _selectedCategory;

  Timer? _patientDebounce;
  Timer? _doctorDebounce;
  bool _isSearchingPatients = false;
  bool _isSearchingDoctors = false;
  List<PharmacyPatientData> _patientSuggestions = const [];
  List<Map<String, String>> _doctorSuggestions = const [];

  static const List<String> presetCategories = [
    'Umum',
    'BPJS Kesehatan',
    'Asuransi Swasta',
    'Kronis / Prolanis',
  ];

  @override
  void initState() {
    super.initState();
    _patientController = TextEditingController(text: widget.initialPatient);
    _doctorController = TextEditingController(text: widget.initialDoctor);
    _queueController = TextEditingController(text: widget.initialQueueNumber ?? '');
    _rmController = TextEditingController(text: widget.initialMedicalRecordNumber ?? '');
    _allergiesController = TextEditingController(text: widget.initialAllergies ?? '');
    _nikController = TextEditingController();
    _selectedCategory = 'Umum';
    for (final cat in presetCategories) {
      if (widget.initialPatient.toLowerCase().contains(cat.toLowerCase())) {
        _selectedCategory = cat;
        break;
      }
    }
  }

  @override
  void dispose() {
    _patientDebounce?.cancel();
    _doctorDebounce?.cancel();
    _patientController.dispose();
    _doctorController.dispose();
    _queueController.dispose();
    _rmController.dispose();
    _allergiesController.dispose();
    _nikController.dispose();
    super.dispose();
  }

  void _onPatientQueryChanged(String val) {
    _patientDebounce?.cancel();
    final q = val.trim();
    if (q.length < 2 || q == 'Pelanggan Umum (Walk-in)') {
      if (_patientSuggestions.isNotEmpty || _isSearchingPatients) {
        setState(() {
          _patientSuggestions = const [];
          _isSearchingPatients = false;
        });
      }
      return;
    }

    _patientDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => _isSearchingPatients = true);
      final results = await PharmacyService.instance.searchPatientsScout(q);
      if (mounted) {
        setState(() {
          _patientSuggestions = results;
          _isSearchingPatients = false;
        });
      }
    });
  }

  void _onDoctorQueryChanged(String val) {
    _doctorDebounce?.cancel();
    final q = val.trim();
    if (q.length < 2 || q == '-') {
      if (_doctorSuggestions.isNotEmpty || _isSearchingDoctors) {
        setState(() {
          _doctorSuggestions = const [];
          _isSearchingDoctors = false;
        });
      }
      return;
    }

    _doctorDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => _isSearchingDoctors = true);
      final results = await PharmacyService.instance.searchDoctors(q);
      if (mounted) {
        setState(() {
          _doctorSuggestions = results;
          _isSearchingDoctors = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF059669);
    const borderColor = Color(0xFFE2E8F0);
    const surfaceCanvas = Color(0xFFFAF8FF);

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderColor, width: 1),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: emeraldPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person_pin_circle_outlined, color: emeraldPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Identitas Pasien & Dokter',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Konteks klinis resep dan penagihan kasir farmasi',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6D7A72)),
                ),
              ],
            ),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.dialogMaxWidth),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PharmacyPatientCategoryChips(
                categories: presetCategories,
                selectedCategory: _selectedCategory,
                onSelectCategory: (cat) {
                  setState(() {
                    _selectedCategory = cat;
                    if (_patientController.text.isEmpty ||
                        _patientController.text == 'Pasien Umum / Walk-in' ||
                        presetCategories.contains(_patientController.text)) {
                      _patientController.text = cat == 'Umum' ? 'Pelanggan Umum (Walk-in)' : 'Pasien $cat';
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: _queueController,
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: emeraldPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'No. Antrean',
                        labelStyle: const TextStyle(color: Color(0xFF6D7A72), fontSize: 11.5),
                        prefixIcon: const Icon(Icons.tag_rounded, size: 16, color: emeraldPrimary),
                        filled: true,
                        fillColor: surfaceCanvas,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: emeraldPrimary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 6,
                    child: TextField(
                      controller: _rmController,
                      onChanged: _onPatientQueryChanged,
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        labelText: 'No. Rekam Medis (RM)',
                        labelStyle: const TextStyle(color: Color(0xFF6D7A72), fontSize: 11.5),
                        prefixIcon: const Icon(Icons.badge_outlined, size: 16, color: Color(0xFF0D9488)),
                        filled: true,
                        fillColor: surfaceCanvas,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: emeraldPrimary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _patientController,
                onChanged: _onPatientQueryChanged,
                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap Pasien (Cari Scout)',
                  labelStyle: const TextStyle(color: Color(0xFF6D7A72), fontSize: 11.5),
                  hintText: 'Ketik nama atau No. RM untuk cari cepat...',
                  hintStyle: const TextStyle(color: Color(0xFFBCCAC0), fontSize: 12),
                  prefixIcon: const Icon(Icons.person_search_outlined, size: 18, color: Color(0xFF6D7A72)),
                  suffixIcon: _isSearchingPatients
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: emeraldPrimary),
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: surfaceCanvas,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: emeraldPrimary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              if (_patientSuggestions.isNotEmpty)
                PharmacyPatientAutocompleteList(
                  suggestions: _patientSuggestions,
                  onSelect: (p) {
                    setState(() {
                      _patientController.text = p.patient;
                      if (p.medicalRecordNumber != '-' && p.medicalRecordNumber.isNotEmpty) {
                        _rmController.text = p.medicalRecordNumber;
                      }
                      if (p.allergies.isNotEmpty) {
                        _allergiesController.text = p.allergies;
                      }
                      if (p.doctor != '-' && p.doctor.isNotEmpty) {
                        _doctorController.text = p.doctor;
                      }
                      if (presetCategories.contains(p.patientCategory)) {
                        _selectedCategory = p.patientCategory;
                      }
                      _patientSuggestions = const [];
                    });
                  },
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _doctorController,
                onChanged: _onDoctorQueryChanged,
                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Dokter Pemeriksa & SIP',
                  labelStyle: const TextStyle(color: Color(0xFF6D7A72), fontSize: 11.5),
                  hintText: 'Contoh: dr. Nama Dokter (SIP: No. SIP)',
                  hintStyle: const TextStyle(color: Color(0xFFBCCAC0), fontSize: 12),
                  prefixIcon: const Icon(Icons.medical_services_outlined, size: 18, color: Color(0xFF6D7A72)),
                  suffixIcon: _isSearchingDoctors
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: emeraldPrimary),
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: surfaceCanvas,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: emeraldPrimary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              if (_doctorSuggestions.isNotEmpty)
                PharmacyDoctorAutocompleteList(
                  suggestions: _doctorSuggestions,
                  onSelect: (d) {
                    setState(() {
                      _doctorController.text = d['display'] ?? d['name'] ?? '';
                      _doctorSuggestions = const [];
                    });
                  },
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _allergiesController,
                style: const TextStyle(fontSize: 13, color: Color(0xFFBA1A1A), fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Riwayat Alergi Obat (Opsional)',
                  labelStyle: const TextStyle(color: Color(0xFFBA1A1A), fontSize: 11.5),
                  hintText: 'Contoh: Alergi Penisilin, Amoksisilin, Aspirin',
                  hintStyle: const TextStyle(color: Color(0xFFBCCAC0), fontSize: 12),
                  prefixIcon: const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFBA1A1A)),
                  filled: true,
                  fillColor: const Color(0xFFFFDAD6).withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFFFDAD6)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFFFDAD6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nikController,
                keyboardType: TextInputType.number,
                maxLength: 16,
                style: const TextStyle(fontSize: 13, color: Color(0xFF191C1E)),
                decoration: InputDecoration(
                  counterText: '',
                  labelText: 'NIK Pasien (SatuSehat Kemenkes RI)',
                  labelStyle: const TextStyle(color: Color(0xFF6D7A72), fontSize: 11.5),
                  hintText: '16 digit NIK untuk integrasi SatuSehat',
                  hintStyle: const TextStyle(color: Color(0xFFBCCAC0), fontSize: 12),
                  prefixIcon: const Icon(Icons.verified_user_outlined, size: 18, color: Color(0xFF006C4C)),
                  filled: true,
                  fillColor: surfaceCanvas,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: emeraldPrimary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
              // Kepatuhan UU PDP No. 27/2022
              InkWell(
                onTap: () => setState(() => _pdpConsent = !_pdpConsent),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _pdpConsent,
                          activeColor: emeraldPrimary,
                          onChanged: (val) => setState(() => _pdpConsent = val ?? true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Persetujuan UU PDP No. 27/2022: Pasien menyetujui penyimpanan data medis untuk pelayanan kefarmasian.',
                          style: TextStyle(fontSize: 10.5, color: Color(0xFF6D7A72)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Color(0xFF6D7A72))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: emeraldPrimary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: 0,
          ),
          onPressed: () {
            final patientText = _patientController.text.trim();
            final doctorText = _doctorController.text.trim();
            final queueText = _queueController.text.trim();
            final rmText = _rmController.text.trim();
            final allergiesText = _allergiesController.text.trim();
            final nikText = _nikController.text.trim();

            widget.onSave(
              PharmacyPatientData(
                patient: patientText.isNotEmpty ? patientText : 'Pelanggan Umum (Walk-in)',
                doctor: doctorText.isNotEmpty ? doctorText : widget.initialDoctor,
                queueNumber: queueText.isNotEmpty ? queueText : '-',
                medicalRecordNumber: rmText.isNotEmpty ? rmText : '-',
                patientCategory: _selectedCategory,
                allergies: allergiesText,
                nik: nikText.isNotEmpty ? nikText : null,
                pdpConsentGiven: _pdpConsent,
              ),
            );
            Navigator.pop(context);
          },
          child: const Text('Terapkan ke Kasir', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
