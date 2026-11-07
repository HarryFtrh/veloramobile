class PharmacyPatientData {
  final String patient;
  final String doctor;
  final String queueNumber;
  final String medicalRecordNumber;
  final String patientCategory;
  final String allergies;
  final List<String> prescribedDrugs;

  /// Kepatuhan Kemenkes RI SatuSehat (FHIR Patient ID / IHS)
  final String? satuSehatId;

  /// NIK 16 digit pasien untuk validasi SatuSehat & BPJS
  final String? nik;

  /// Nomor SIP Dokter (Kepatuhan BPOM SIPNAP untuk Narkotika & Psikotropika)
  final String? doctorSipNumber;

  /// Persetujuan pemrosesan rekam medis (Kepatuhan UU No. 27/2022 tentang Pelindungan Data Pribadi / PDP)
  final bool pdpConsentGiven;

  const PharmacyPatientData({
    required this.patient,
    required this.doctor,
    this.queueNumber = '-',
    this.medicalRecordNumber = '-',
    this.patientCategory = 'Umum',
    this.allergies = '',
    this.prescribedDrugs = const [],
    this.satuSehatId,
    this.nik,
    this.doctorSipNumber,
    this.pdpConsentGiven = true,
  });

  Map<String, dynamic> toJson() => {
        'patient': patient,
        'doctor': doctor,
        'queue_number': queueNumber,
        'medical_record_number': medicalRecordNumber,
        'patient_category': patientCategory,
        'allergies': allergies,
        'prescribed_drugs': prescribedDrugs,
        if (satuSehatId != null) 'satu_sehat_id': satuSehatId,
        if (nik != null) 'nik': nik,
        if (doctorSipNumber != null) 'doctor_sip_number': doctorSipNumber,
        'pdp_consent_given': pdpConsentGiven,
      };
}
