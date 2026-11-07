/// Model antrean pasien poli/klinik untuk kasir apotek & farmasi klinis
class ClinicPatientQueueItem {
  final String queueNumber;
  final String patientName;
  final String medicalRecordNumber;
  final String doctorName;
  final String department;
  final String insurance;
  final String? allergy;
  final String status; // 'ready', 'pending', 'done'
  final num estimatedTotal;
  final List<String> prescribedDrugs;

  const ClinicPatientQueueItem({
    required this.queueNumber,
    required this.patientName,
    required this.medicalRecordNumber,
    required this.doctorName,
    required this.department,
    required this.insurance,
    this.allergy,
    required this.status,
    required this.estimatedTotal,
    this.prescribedDrugs = const [],
  });
}

/// Model item peringatan kedaluwarsa (ED FEFO) dan stok kritis apotek
class PharmacyStockAlertItem {
  final String name;
  final String category;
  final String batchNumber;
  final String expiryDate;
  final int daysToExpiry;
  final int stock;
  final String unit;
  final num price;
  final bool isHardDrug;

  const PharmacyStockAlertItem({
    required this.name,
    required this.category,
    required this.batchNumber,
    required this.expiryDate,
    required this.daysToExpiry,
    required this.stock,
    required this.unit,
    required this.price,
    this.isHardDrug = false,
  });
}
