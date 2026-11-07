import 'package:flutter/material.dart';
import '../pharmacy_service.dart';
import '../../shared_pos/pos_checkout_service.dart';
import 'review/pharmacy_prescription_review_checklist.dart';
import 'review/pharmacy_prescription_review_patient_card.dart';

export 'review/pharmacy_prescription_review_checklist.dart';
export 'review/pharmacy_prescription_review_patient_card.dart';

class PharmacyPrescriptionReviewModal extends StatefulWidget {
  final VoidCallback? onApprove;
  final bool showDragHandle;
  final PharmacyPatientData? patientData;
  final List<PosCartItem>? cartItems;

  const PharmacyPrescriptionReviewModal({
    super.key,
    this.onApprove,
    this.showDragHandle = true,
    this.patientData,
    this.cartItems,
  });

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onApprove,
    PharmacyPatientData? patientData,
    List<PosCartItem>? cartItems,
  }) {
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
          child: PharmacyPrescriptionReviewModal(
            onApprove: onApprove,
            patientData: patientData,
            cartItems: cartItems,
          ),
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

  List<ClinicPatientQueueItem> _pendingQueue = [];
  ClinicPatientQueueItem? _selectedQueueItem;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadPendingPrescriptions();
  }

  Future<void> _loadPendingPrescriptions() async {
    final list = await PharmacyService.instance.fetchPatientQueue();
    if (!mounted) return;
    setState(() {
      _pendingQueue = list;
      if (_selectedQueueItem == null && list.isNotEmpty) {
        _selectedQueueItem = list.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF059669);
    const borderColor = Color(0xFFE2E8F0);
    const textPrimary = Color(0xFF0F172A);
    const textMuted = Color(0xFF6D7A72);

    final allPassed = _screenings.values.every((v) => v);
    final activePatient = widget.patientData ?? PharmacyService.instance.activePatient.value;

    final patientName = activePatient?.patient.isNotEmpty == true
        ? activePatient!.patient
        : (_selectedQueueItem?.patientName.isNotEmpty == true
            ? _selectedQueueItem!.patientName
            : 'Pasien Rawat Jalan');
    final rmNumber = activePatient?.medicalRecordNumber.isNotEmpty == true
        ? activePatient!.medicalRecordNumber
        : (_selectedQueueItem?.medicalRecordNumber.isNotEmpty == true
            ? _selectedQueueItem!.medicalRecordNumber
            : '-');
    final category = activePatient?.patientCategory.isNotEmpty == true
        ? activePatient!.patientCategory
        : (_selectedQueueItem?.insurance ?? 'Umum / Resep');
    final doctorName = activePatient?.doctor.isNotEmpty == true
        ? activePatient!.doctor
        : (_selectedQueueItem?.doctorName ?? 'Dokter Pemeriksa');
    final allergies = activePatient?.allergies ?? (_selectedQueueItem?.allergy ?? '');
    final prescribedFromQueue = _selectedQueueItem?.prescribedDrugs ?? const <String>[];

    final displayInitials = patientName.isNotEmpty
        ? patientName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : 'PX';

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
                            color: emeraldPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.assignment_turned_in_outlined, color: emeraldPrimary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Telaah Resep & Verifikasi Apoteker',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'Skrining Farmasetis, Klinis, & Administrasi Resep',
                              style: TextStyle(fontSize: 11, color: textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const Divider(height: 1, color: borderColor),

        // Scrollable Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prescription Meta Header
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
                      Row(
                        children: [
                          const Icon(Icons.receipt_long_rounded, color: emeraldPrimary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Lembar Resep #${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4F8E8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 6, color: Color(0xFF0D9488)),
                            SizedBox(width: 4),
                            Text(
                              'Dalam Telaah',
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D9488),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Queue Patient Selector (when opened as Pharmacist Workstation Tab)
                if (widget.patientData == null && _pendingQueue.isNotEmpty) ...[
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _pendingQueue.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final q = _pendingQueue[idx];
                        final isSelected = _selectedQueueItem?.queueNumber == q.queueNumber;
                        return ChoiceChip(
                          selected: isSelected,
                          selectedColor: const Color(0xFFD4F8E8),
                          label: Text(
                            '${q.queueNumber} • ${q.patientName}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? emeraldPrimary : textPrimary,
                            ),
                          ),
                          onSelected: (_) => setState(() => _selectedQueueItem = q),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Patient & Physician Card
                PrescriptionReviewPatientCard(
                  patientName: patientName,
                  rmNumber: rmNumber,
                  category: category,
                  doctorName: doctorName,
                  allergies: allergies,
                  displayInitials: displayInitials,
                ),
                const SizedBox(height: 14),

                // Prescribed Items Review
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
                      const Text(
                        'Rincian Obat yang Divalidasi:',
                        style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 13.5, color: textPrimary),
                      ),
                      const SizedBox(height: 8),
                      if (widget.cartItems != null && widget.cartItems!.isNotEmpty)
                        ...widget.cartItems!.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.medication_rounded, size: 16, color: emeraldPrimary),
                                      const SizedBox(width: 8),
                                      Text(
                                        item.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${item.quantity} ${item.unit}',
                                    style: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ))
                      else if (prescribedFromQueue.isNotEmpty)
                        ...prescribedFromQueue.map((drug) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.medication_rounded, size: 16, color: emeraldPrimary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      drug,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                      else
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            'Resep e-Prescribing terhubung otomatis dengan katalog sediaan farmasi.',
                            style: TextStyle(fontSize: 11.5, color: textMuted),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 7 Benar Screening Checklist
                PrescriptionReviewChecklist(
                  screenings: _screenings,
                  onToggleItem: (key) {
                    setState(() {
                      _screenings[key] = !(_screenings[key] ?? false);
                    });
                  },
                ),
                const SizedBox(height: 14),

                // Pharmacist Verification Stamp
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_outlined, color: emeraldPrimary, size: 24),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verifikasi Apoteker Penanggung Jawab (APJ)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Text(
                              'SIA & SIPA Aktif • Sesuai Standar Pelayanan Kefarmasian Kemenkes RI',
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
        ),

        // Action Buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Permintaan konsultasi ulang resep telah dikirim ke Dokter Pemeriksa.'),
                          backgroundColor: Color(0xFFBA1A1A),
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFBA1A1A),
                    side: const BorderSide(color: Color(0xFFBA1A1A)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Tolak Resep / Konsul Dokter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (allPassed && !_isSubmitting)
                      ? () async {
                          setState(() => _isSubmitting = true);
                          await PharmacyService.instance.verifyPrescription(
                            patientName: patientName,
                            medicalRecordNumber: rmNumber,
                            doctorName: doctorName,
                            screenings: _screenings,
                          );
                          PharmacyService.instance.setActivePatient(
                            PharmacyPatientData(
                              patient: patientName,
                              doctor: doctorName,
                              queueNumber: _selectedQueueItem?.queueNumber ?? '-',
                              medicalRecordNumber: rmNumber,
                              patientCategory: category,
                              allergies: allergies,
                              prescribedDrugs: prescribedFromQueue,
                            ),
                          );
                          if (!context.mounted) return;
                          setState(() => _isSubmitting = false);
                          widget.onApprove?.call();
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✓ Resep telah ditelaah dan diverifikasi valid oleh Apoteker.'),
                              backgroundColor: emeraldPrimary,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(
                    _isSubmitting ? 'Memverifikasi...' : 'Setujui & Validasi Resep',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: emeraldPrimary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Standalone Full Page Version for AppShell & Workstation Tab
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
          onApprove: onApprove,
          showDragHandle: false,
        ),
      ),
    );
  }
}
