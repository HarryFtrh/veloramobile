import 'package:flutter/material.dart';
import '../../models/pharmacy_patient_data.dart';

/// Autocomplete suggestions dropdown container for patient search
class PharmacyPatientAutocompleteList extends StatelessWidget {
  final List<PharmacyPatientData> suggestions;
  final ValueChanged<PharmacyPatientData> onSelect;

  const PharmacyPatientAutocompleteList({
    super.key,
    required this.suggestions,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: suggestions.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (ctx, idx) {
          final item = suggestions[idx];
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: const Icon(Icons.person_pin_outlined, color: Color(0xFF059669), size: 18),
            title: Text(item.patient, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
            subtitle: Text('RM: ${item.medicalRecordNumber} • ${item.patientCategory}', style: const TextStyle(fontSize: 10.5)),
            onTap: () => onSelect(item),
          );
        },
      ),
    );
  }
}

/// Autocomplete suggestions dropdown container for doctor search
class PharmacyDoctorAutocompleteList extends StatelessWidget {
  final List<Map<String, String>> suggestions;
  final ValueChanged<Map<String, String>> onSelect;

  const PharmacyDoctorAutocompleteList({
    super.key,
    required this.suggestions,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: suggestions.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (ctx, idx) {
          final item = suggestions[idx];
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: const Icon(Icons.medical_services_outlined, color: Color(0xFF0D9488), size: 18),
            title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
            subtitle: Text(item['poli'] ?? 'Dokter Spesialis', style: const TextStyle(fontSize: 10.5)),
            onTap: () => onSelect(item),
          );
        },
      ),
    );
  }
}
