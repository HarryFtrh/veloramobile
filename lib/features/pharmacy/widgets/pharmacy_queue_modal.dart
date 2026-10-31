import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import 'pharmacy_patient_dialog.dart';
import '../pharmacy_service.dart';

/// Model antrean pasien poli/klinik untuk kasir apotek
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

/// Modal lembar antrean & billing pasien klinik (sesuai desain Google Stitch Clinical Precision)
class PharmacyQueueModal extends StatefulWidget {
  final Function(PharmacyPatientData patientData) onSelectPatient;

  const PharmacyQueueModal({
    super.key,
    required this.onSelectPatient,
  });

  static Future<void> show(
    BuildContext context, {
    required Function(PharmacyPatientData patientData) onSelectPatient,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
          maxWidth: 620,
        ),
        child: PharmacyQueueModal(onSelectPatient: onSelectPatient),
      ),
    );
  }

  @override
  State<PharmacyQueueModal> createState() => _PharmacyQueueModalState();
}

class _PharmacyQueueModalState extends State<PharmacyQueueModal> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  bool _isLoading = false; // ignore: unused_field
  List<ClinicPatientQueueItem> _queueItems = [];

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    final items = await PharmacyService.instance.fetchPatientQueue();
    if (mounted) {
      setState(() {
        _queueItems = items;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF059669); // Clinical Emerald
    const canvasColor = Color(0xFFFAF8FF);

    final filtered = _queueItems.where((item) {
      if (_selectedFilter == 'ready' && item.status != 'ready') return false;
      if (_selectedFilter == 'pending' && item.status != 'pending') return false;
      if (_selectedFilter == 'done' && item.status != 'done') return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = item.patientName.toLowerCase().contains(q);
        final matchRm = item.medicalRecordNumber.toLowerCase().contains(q);
        final matchDoc = item.doctorName.toLowerCase().contains(q);
        final matchQ = item.queueNumber.toLowerCase().contains(q);
        return matchName || matchRm || matchDoc || matchQ;
      }
      return true;
    }).toList();

    return Container(
      decoration: const BoxDecoration(
        color: canvasColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFBCCAC0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Modal Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E7FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: primaryColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Antrean & Billing Pasien',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Klinik & Loket Apotek Farmasi',
                          style: TextStyle(fontSize: 12, color: Color(0xFF6D7A72)),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF6D7A72)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Cari No. RM, Nama Pasien, atau Dokter...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF6D7A72)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6D7A72), size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryColor, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFilterChip('all', 'Semua Antrean (${_queueItems.length})', primaryColor),
                const SizedBox(width: 8),
                _buildFilterChip('ready', 'Siap Bayar (2)', primaryColor),
                const SizedBox(width: 8),
                _buildFilterChip('pending', 'Menunggu Resep (1)', primaryColor),
                const SizedBox(width: 8),
                _buildFilterChip('done', 'Selesai (1)', primaryColor),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Queue List
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada antrean pasien yang cocok.',
                      style: TextStyle(color: Color(0xFF6D7A72)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, idx) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final item = filtered[i];
                      return _buildQueueCard(item, primaryColor);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, Color primaryColor) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _selectedFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF3D4A42),
          ),
        ),
      ),
    );
  }

  Widget _buildQueueCard(ClinicPatientQueueItem item, Color primaryColor) {
    final isReady = item.status == 'ready';
    final isDone = item.status == 'done';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReady ? primaryColor : const Color(0xFFE2E8F0),
          width: isReady ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E7FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.queueNumber,
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.patientName,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isReady
                      ? const Color(0xFFD4F8E8)
                      : (isDone ? const Color(0xFFF1F5F9) : const Color(0xFFFEF3C7)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isReady ? 'Siap Bayar' : (isDone ? 'Selesai' : 'Menunggu Resep'),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isReady
                        ? const Color(0xFF059669)
                        : (isDone ? const Color(0xFF64748B) : const Color(0xFFB45309)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Dokter & Poli & RM
          Row(
            children: [
              Text(
                '${item.medicalRecordNumber} • ${item.doctorName}',
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF6D7A72)),
              ),
              const SizedBox(width: 4),
              Text(
                '(${item.department})',
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF6D7A72)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Badges: Asuransi & Alergi
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F3FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.insurance,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF0D9488)),
                ),
              ),
              if (item.allergy != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 12),
                      const SizedBox(width: 3),
                      Text(
                        'Alergi: ${item.allergy}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Divider(height: 18, color: Color(0xFFF0F2F5)),

          // Bottom line: Estimasi Biaya & Tombol Pilih ke Kasir
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estimasi Tagihan:', style: TextStyle(fontSize: 10, color: Color(0xFF6D7A72))),
                  Text(
                    CurrencyFormatter.format(item.estimatedTotal),
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  widget.onSelectPatient(
                    PharmacyPatientData(
                      patient: '${item.patientName} (${item.queueNumber})',
                      doctor: item.doctorName,
                    ),
                  );
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: const Text('Muat ke Kasir', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
