import 'package:flutter/material.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/audio_helper.dart';
import '../shared_pos/product_catalog_service.dart';
import 'pharmacy_service.dart';
import 'widgets/pharmacy_queue_modal.dart';

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
  String _bp = '-';
  String _pulse = '-';
  String _temp = '-';
  String _allergies = 'Tidak ada riwayat alergi obat';

  final TextEditingController _anamnesisController = TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController(text: 'Pemeriksaan Klinis Rawat Jalan');

  final List<Map<String, String>> _prescribedItems = [];

  List<ClinicPatientQueueItem> _liveQueue = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _doctorName = SessionStorage.instance.getUserName() ?? 'dr. Spesialis Poli';
    _sip = SessionStorage.instance.getUserRole() ?? 'SIP: Aktif';
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

  Future<void> _sendElectronicPrescription() async {
    AudioHelper.tapFeedback();
    await PharmacyService.instance.sendElectronicPrescription(
      patientName: _patientName,
      medicalRecordNumber: _medicalRecordNumber,
      doctorName: _doctorName,
      department: _department,
      diagnosis: _diagnosisController.text.trim().isNotEmpty ? _diagnosisController.text.trim() : 'Pemeriksaan Klinis Rawat Jalan',
      prescribedDrugs: _prescribedItems.map((e) => '${e['name']} (${e['dose']})').toList(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '✓ e-Resep untuk $_patientName ($_queueNumber) berhasil dikirim ke Antrean Loket Farmasi & Meja Racik.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF006948),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF006948);
    const textPrimary = Color(0xFF131B2E);
    const textMuted = Color(0xFF6D7A72);
    const borderColor = Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        title: const Text(
          'Workstation Dokter & e-Prescribing',
          style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: borderColor),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Header Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: emeraldPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.medical_services_outlined, color: emeraldPrimary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _doctorName,
                            style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary),
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
                    if (_liveQueue.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Pilih Pasien dari Antrean Live (/v1/pharmacy/queue):',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: emeraldPrimary),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, size: 16, color: emeraldPrimary),
                            tooltip: 'Segarkan Antrean Pasien',
                            onPressed: _fetchLivePatients,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _liveQueue.map((q) {
                            final isSelected = q.queueNumber == _queueNumber;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                onTap: () => _selectPatientFromQueue(q),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isSelected ? emeraldPrimary : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isSelected ? emeraldPrimary : borderColor),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        q.queueNumber,
                                        style: TextStyle(
                                          fontFamily: 'JetBrains Mono',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10.5,
                                          color: isSelected ? Colors.white : emeraldPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        q.patientName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? Colors.white : textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: emeraldPrimary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _queueNumber,
                                style: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold, color: emeraldPrimary),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _patientName,
                              style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 14.5),
                            ),
                          ],
                        ),
                        Text('No. RM: $_medicalRecordNumber', style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11.5, color: textMuted)),
                      ],
                    ),
                    const Divider(height: 16, color: Color(0xFFF1F5F9)),

                    // Vital signs
                    Row(
                      children: [
                        Expanded(child: _buildVitalPill('Tensi Darah', _bp, Icons.favorite_border_rounded)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildVitalPill('Nadi', _pulse, Icons.monitor_heart_outlined)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildVitalPill('Suhu', _temp, Icons.thermostat_rounded)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Peringatan Dokter: $_allergies',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Anamnesis & Diagnosis
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
                    const Text('Anamnesis & Keluhan Pasien', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _anamnesisController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderColor)),
                      ),
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    const SizedBox(height: 10),
                    const Text('Diagnosis Klinis (ICD-10)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _diagnosisController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        hintText: 'Contoh: J00 - Nasofaringitis akut / Observasi Febris',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF006948), width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      style: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold, fontSize: 12.5, color: textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // e-Prescription List
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('R/ Lembar Peresepan Digital (e-Resep)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        InkWell(
                          onTap: () async {
                            final catalog = await ProductCatalogService.instance.fetchCatalog();
                            if (!mounted) return;
                            showModalBottomSheet(
                              context: context,
                              builder: (ctx) => Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Pilih Obat dari Formularium POS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 10),
                                    Expanded(
                                      child: ListView(
                                        children: catalog.products.map((p) => ListTile(
                                          leading: const Icon(Icons.medication_rounded, color: emeraldPrimary),
                                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                          subtitle: Text(p.category, style: const TextStyle(fontSize: 11)),
                                          onTap: () {
                                            setState(() {
                                              _prescribedItems.add({
                                                'name': p.name,
                                                'dose': '10 Unit',
                                                'signa': '3 x Sehari 1 Sesudah Makan',
                                              });
                                            });
                                            Navigator.pop(ctx);
                                          },
                                        )).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              children: [
                                Icon(Icons.add_circle_outline_rounded, size: 14, color: emeraldPrimary),
                                SizedBox(width: 4),
                                Text('+ Tambah Obat', style: TextStyle(fontSize: 11.5, color: emeraldPrimary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_prescribedItems.isNotEmpty)
                      ..._prescribedItems.map((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.medication_liquid_outlined, color: emeraldPrimary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text(item['signa']!, style: const TextStyle(fontSize: 11, color: textMuted)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)),
                                child: Text(item['dose']!, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      })
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        child: const Text(
                          'Belum ada obat yang diresepkan. Klik "+ Tambah Obat" untuk memilih dari formularium katalog.',
                          style: TextStyle(color: textMuted, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Send Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sendElectronicPrescription,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text(
                    'Kirim e-Resep ke Antrean Loket Farmasi',
                    style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: emeraldPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editVitalSign(String label) {
    AudioHelper.tapFeedback();
    final ctrl = TextEditingController(
      text: label == 'Tensi Darah'
          ? (_bp == '-' ? '' : _bp)
          : (label == 'Nadi'
              ? (_pulse == '-' ? '' : _pulse)
              : (_temp == '-' ? '' : _temp)),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Input $label Pasien', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: label == 'Tensi Darah' ? '120/80 mmHg' : (label == 'Nadi' ? '78 bpm' : '36.5 °C'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006948),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                final val = ctrl.text.trim();
                if (label == 'Tensi Darah') _bp = val.isNotEmpty ? val : '-';
                if (label == 'Nadi') _pulse = val.isNotEmpty ? val : '-';
                if (label == 'Suhu') _temp = val.isNotEmpty ? val : '-';
              });
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalPill(String label, String value, IconData icon) {
    return InkWell(
      onTap: () => _editVitalSign(label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: const Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
              ],
            ),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }
}
