import 'package:flutter/material.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/audio_helper.dart';
import 'services/pharmacy_catalog_service.dart';
import 'pharmacy_service.dart';
import 'widgets/doctor/pharmacy_doctor_patient_vital_card.dart';
import 'widgets/doctor/pharmacy_doctor_prescription_table.dart';

export 'widgets/doctor/pharmacy_doctor_patient_vital_card.dart';
export 'widgets/doctor/pharmacy_doctor_prescription_table.dart';

/// Workstation Dokter: EMR Rekam Medis & e-Prescribing (Google Stitch "Clinical Precision")
class PharmacyDoctorEmrScreen extends StatefulWidget {
  const PharmacyDoctorEmrScreen({super.key});

  @override
  State<PharmacyDoctorEmrScreen> createState() => _PharmacyDoctorEmrScreenState();
}

class _PharmacyDoctorEmrScreenState extends State<PharmacyDoctorEmrScreen> {
  late String _doctorName;
  late String _sip;
  String _department = 'Poli Spesialis';

  // Active Patient Context
  String _patientName = 'Pilih Pasien';
  String _queueNumber = '-';
  String _medicalRecordNumber = '-';
  final String _bp = '-';
  final String _pulse = '-';
  final String _temp = '-';
  String _allergies = 'Tidak ada riwayat alergi obat';

  final TextEditingController _anamnesisController = TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();

  final List<Map<String, String>> _prescribedItems = [];
  List<ClinicPatientQueueItem> _liveQueue = [];
  bool _isLoading = false; // ignore: unused_field

  @override
  void initState() {
    super.initState();
    _doctorName = SessionStorage.instance.getUserName() ?? 'Dokter Pemeriksa';
    _sip = SessionStorage.instance.getUserRole() ?? 'SIP: Aktif';
    _department = SessionStorage.instance.getLocationName() ?? 'Poli Rawat Jalan';
    final active = PharmacyService.instance.activePatient.value;
    if (active != null) {
      _patientName = active.patient;
      _queueNumber = active.queueNumber;
      _medicalRecordNumber = active.medicalRecordNumber;
      _allergies = active.allergies.isNotEmpty ? active.allergies : 'Tidak ada riwayat alergi obat';
      if (active.doctor.isNotEmpty) _doctorName = active.doctor;
    }
    _fetchLivePatients();
  }

  Future<void> _fetchLivePatients() async {
    setState(() => _isLoading = true);
    final list = await PharmacyService.instance.fetchPatientQueue();
    if (mounted) {
      setState(() {
        _liveQueue = list;
        if (list.isNotEmpty && _patientName == 'Pilih Pasien') {
          final first = list.first;
          _patientName = first.patientName;
          _queueNumber = first.queueNumber;
          _medicalRecordNumber = first.medicalRecordNumber;
          _allergies = first.allergy ?? 'Tidak ada riwayat alergi obat';
          _department = first.department;
          _doctorName = first.doctorName;
          if (first.prescribedDrugs.isNotEmpty) {
            _prescribedItems.clear();
            for (final d in first.prescribedDrugs) {
              _prescribedItems.add({
                'name': d,
                'dose': '10 Sediaan',
                'signa': '3 x Sehari 1 Sesudah Makan',
              });
            }
          }
        }
        _isLoading = false;
      });
    }
  }

  void _selectPatientFromQueue(ClinicPatientQueueItem item) {
    AudioHelper.tapFeedback();
    setState(() {
      _patientName = item.patientName;
      _queueNumber = item.queueNumber;
      _medicalRecordNumber = item.medicalRecordNumber;
      _allergies = item.allergy ?? 'Tidak ada riwayat alergi obat';
      _department = item.department;
      _doctorName = item.doctorName;
      _prescribedItems.clear();
      for (final d in item.prescribedDrugs) {
        _prescribedItems.add({
          'name': d,
          'dose': '10 Sediaan',
          'signa': '3 x Sehari 1 Sesudah Makan',
        });
      }
    });
  }

  @override
  void dispose() {
    _anamnesisController.dispose();
    _diagnosisController.dispose();
    super.dispose();
  }

  Future<void> _addDrugDialog() async {
    AudioHelper.tapFeedback();
    try {
      final catalog = await PharmacyCatalogService.instance.fetchCatalog();
      if (!mounted) return;
      if (catalog.products.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Katalog obat formularium kosong.')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (ctx) {
          String searchQ = '';
          return StatefulBuilder(
            builder: (ctx, setDialogState) {
              final filtered = catalog.products.where((p) => p.matchesQuery(searchQ)).toList();

              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  children: [
                    Icon(Icons.medication_rounded, color: Color(0xFF059669)),
                    SizedBox(width: 8),
                    Text('Pilih Obat untuk Pasien', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 380,
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari obat...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (val) => setDialogState(() => searchQ = val.trim()),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(child: Text('Tidak ada obat ditemukan', style: TextStyle(color: Colors.grey)))
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, idx) => const Divider(height: 1),
                                itemBuilder: (ctx, idx) {
                                  final p = filtered[idx];
                                  return ListTile(
                                    dense: true,
                                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('Kategori: ${p.category} • Sediaan: ${p.unit}'),
                                    trailing: const Icon(Icons.add_circle_outline, color: Color(0xFF059669)),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _promptDrugSigna(p.name);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
                ],
              );
            },
          );
        },
      );
    } catch (_) {}
  }

  void _promptDrugSigna(String drugName) {
    final signaCtrl = TextEditingController(text: '3 x Sehari 1 Tablet Sesudah Makan');
    final doseCtrl = TextEditingController(text: '10 Sediaan');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Aturan Pakai untuk $drugName', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: doseCtrl,
              decoration: InputDecoration(
                labelText: 'Jumlah Sediaan / Dosis',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: signaCtrl,
              decoration: InputDecoration(
                labelText: 'Signa / Instruksi Aturan Pakai',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                _prescribedItems.add({
                  'name': drugName,
                  'dose': doseCtrl.text.trim(),
                  'signa': signaCtrl.text.trim(),
                });
              });
              Navigator.pop(ctx);
            },
            child: const Text('Simpan ke Resep'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPrescription() async {
    AudioHelper.tapFeedback();
    if (_prescribedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan minimal 1 obat pada lembar resep sebelum mengirim ke Instalasi Farmasi.'),
          backgroundColor: Color(0xFFBA1A1A),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final drugSummaryList = _prescribedItems
        .map((e) => '${e['name']} (${e['dose']} - ${e['signa']})')
        .toList();

    final ok = await PharmacyService.instance.sendElectronicPrescription(
      patientName: _patientName,
      medicalRecordNumber: _medicalRecordNumber,
      doctorName: _doctorName,
      department: _department,
      diagnosis: _diagnosisController.text.trim(),
      prescribedDrugs: drugSummaryList,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Resep elektronik untuk $_patientName berhasil dikirim ke Instalasi Farmasi.'),
          backgroundColor: const Color(0xFF059669),
          duration: const Duration(seconds: 3),
        ),
      );
      await _fetchLivePatients();
    }
  }

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF059669);
    const textPrimary = Color(0xFF0F172A);
    const textMuted = Color(0xFF6D7A72);
    const borderColor = Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: SafeArea(
        child: Column(
          children: [
            // Clinical Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: emeraldPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.medical_services_outlined, color: emeraldPrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'EMR & e-Prescribing Dokter',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: textPrimary,
                              ),
                            ),
                            SizedBox(width: 8),
                            CircleAvatar(radius: 4, backgroundColor: emeraldPrimary),
                            SizedBox(width: 4),
                            Text(
                              'Tele-Poli Terhubung',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: emeraldPrimary),
                            ),
                          ],
                        ),
                        Text(
                          'Catatan Klinis Pasien, Anamnesis, & Resep Elektronik Farmasi',
                          style: TextStyle(fontSize: 11.5, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Doctor Profile Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(0xFFF1F5F9),
                            child: Icon(Icons.person_outline_rounded, color: emeraldPrimary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _doctorName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: textPrimary),
                                ),
                                Text('SIP: $_sip  •  $_department', style: const TextStyle(fontSize: 11.5, color: textMuted)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4F8E8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Poli Aktif', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: emeraldPrimary)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Active Patient & Vital Signs Card
                    DoctorPatientVitalCard(
                      liveQueue: _liveQueue,
                      queueNumber: _queueNumber,
                      patientName: _patientName,
                      medicalRecordNumber: _medicalRecordNumber,
                      bp: _bp,
                      pulse: _pulse,
                      temp: _temp,
                      allergies: _allergies,
                      onSelectPatient: _selectPatientFromQueue,
                      onRefreshQueue: _fetchLivePatients,
                    ),
                    const SizedBox(height: 14),

                    // Diagnosis & Anamnesis
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Diagnosis & Catatan Medis (ICD-10)',
                            style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 13.5, color: textPrimary),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _diagnosisController,
                            decoration: InputDecoration(
                              labelText: 'Diagnosis Primer / Asesmen',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _anamnesisController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'Ketik keluhan pasien, riwayat alergi obat, dan instruksi penunjang...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Prescribed Drugs Table
                    DoctorPrescriptionTable(
                      prescribedItems: _prescribedItems,
                      onAddDrug: _addDrugDialog,
                      onRemoveDrug: (item) => setState(() => _prescribedItems.remove(item)),
                    ),
                    const SizedBox(height: 20),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _submitPrescription,
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text('Kirim e-Resep ke Loket Farmasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: emeraldPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
