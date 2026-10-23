import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';

class PharmacyPatientData {
  final String patient;
  final String doctor;

  const PharmacyPatientData({
    required this.patient,
    required this.doctor,
  });
}

class PharmacyPatientDialog extends StatefulWidget {
  final String initialPatient;
  final String initialDoctor;
  final ValueChanged<PharmacyPatientData> onSave;

  const PharmacyPatientDialog({
    super.key,
    required this.initialPatient,
    required this.initialDoctor,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required String initialPatient,
    required String initialDoctor,
    required ValueChanged<PharmacyPatientData> onSave,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => PharmacyPatientDialog(
        initialPatient: initialPatient,
        initialDoctor: initialDoctor,
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
  late String _selectedPatient;

  static const List<String> presetPatients = [
    'Pasien Umum / Walk-in',
    'Pasien BPJS',
    'Pasien Kronis / Prolanis',
    'Pasien Asuransi Swasta',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPatient = widget.initialPatient;
    _patientController = TextEditingController(text: widget.initialPatient);
    _doctorController = TextEditingController(text: widget.initialDoctor);
  }

  @override
  void dispose() {
    _patientController.dispose();
    _doctorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AlertDialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: p.line, width: 1.2),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.medical_services_outlined, color: p.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Identitas Pasien & Dokter',
              style: TextStyle(color: p.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.dialogMaxWidth),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kategori Pasien Cepat:',
                style: TextStyle(color: p.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: presetPatients.map((cat) {
                  final isSelected = cat == _selectedPatient;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: p.primary,
                    backgroundColor: p.canvas,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? p.primary : p.line,
                      ),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : p.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 11,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedPatient = cat;
                        _patientController.text = cat;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _patientController,
                style: TextStyle(fontSize: 13, color: p.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nama Pasien / No. RM',
                  labelStyle: TextStyle(color: p.textSecondary, fontSize: 12),
                  hintText: 'Contoh: Ny. Ratna / RM-0982',
                  hintStyle: TextStyle(color: p.textSecondary.withValues(alpha: 0.5), fontSize: 12),
                  filled: true,
                  fillColor: p.canvas,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: p.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: p.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: p.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _doctorController,
                style: TextStyle(fontSize: 13, color: p.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Dokter Perujuk / Penulis Resep',
                  labelStyle: TextStyle(color: p.textSecondary, fontSize: 12),
                  hintText: 'Contoh: dr. Anita Wijaya, Sp.A',
                  hintStyle: TextStyle(color: p.textSecondary.withValues(alpha: 0.5), fontSize: 12),
                  filled: true,
                  fillColor: p.canvas,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: p.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: p.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: p.primary, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal', style: TextStyle(color: p.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: p.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          onPressed: () {
            final patientText = _patientController.text.trim();
            final doctorText = _doctorController.text.trim();
            widget.onSave(
              PharmacyPatientData(
                patient: patientText.isNotEmpty ? patientText : _selectedPatient,
                doctor: doctorText.isNotEmpty ? doctorText : widget.initialDoctor,
              ),
            );
            Navigator.pop(context);
          },
          child: const Text('Simpan Data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
