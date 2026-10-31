import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/audio_helper.dart';
import '../../core/utils/currency_formatter.dart';
import 'pharmacy_service.dart';
import 'widgets/pharmacy_patient_dialog.dart';
import 'widgets/pharmacy_queue_modal.dart';

/// Screen 2: Billing Klinik & Antrean Pasien (Google Stitch "Clinical Precision")
class PharmacyQueueScreen extends StatefulWidget {
  const PharmacyQueueScreen({super.key});

  @override
  State<PharmacyQueueScreen> createState() => _PharmacyQueueScreenState();
}

class _PharmacyQueueScreenState extends State<PharmacyQueueScreen> {
  String _selectedPoli = 'Semua Poli';
  String _selectedStatus = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<ClinicPatientQueueItem> _queueItems = [];

  final List<String> _poliList = [
    'Semua Poli',
    'Poli Umum',
    'Poli Anak',
    'Poli Gigi',
    'Poli Penyakit Dalam',
    'Poli Jantung & Pembuluh',
    'Laboratorium',
    'KIA',
  ];

  @override
  void initState() {
    super.initState();
    _fetchQueue();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchQueue() async {
    setState(() => _isLoading = true);
    final items = await PharmacyService.instance.fetchPatientQueue();
    if (mounted) {
      setState(() {
        _queueItems = items;
        _isLoading = false;
      });
    }
  }

  void _callPatient(ClinicPatientQueueItem item) {
    AudioHelper.tapFeedback();
    try {
      ApiClient.instance.dio.post('/v1/pharmacy/queue/call', data: {
        'queue_number': item.queueNumber,
        'patient_name': item.patientName,
        'destination': 'Loket Farmasi 1',
      });
    } catch (_) {}

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Panggilan Loket: ${item.queueNumber} - ${item.patientName} (${item.department}) menuju Loket Farmasi 1',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF006948),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _loadToCashier(ClinicPatientQueueItem item) {
    AudioHelper.tapFeedback();
    final patientData = PharmacyPatientData(
      patient: item.patientName,
      doctor: item.doctorName,
      queueNumber: item.queueNumber,
      medicalRecordNumber: item.medicalRecordNumber,
      patientCategory: item.insurance,
      allergies: item.allergy ?? '',
    );

    // Kirim data ke Kasir POS
    PharmacyService.instance.setActivePatient(patientData);

    // Switch shell tab ke Kasir POS (tab index 0)
    PharmacyService.instance.switchTab(0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pasien ${item.queueNumber} (${item.patientName}) dimuat ke Kasir POS.'),
        backgroundColor: const Color(0xFF006948),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF006948);
    const textPrimary = Color(0xFF131B2E);
    const textMuted = Color(0xFF6D7A72);
    const borderColor = Color(0xFFE2E8F0);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 800;

    final filtered = _queueItems.where((item) {
      if (_selectedStatus == 'ready' && item.status != 'ready') return false;
      if (_selectedStatus == 'pending' && item.status != 'pending') return false;
      if (_selectedStatus == 'done' && item.status != 'done') return false;

      if (_selectedPoli != 'Semua Poli' && !item.department.toLowerCase().contains(_selectedPoli.toLowerCase().replaceAll('poli ', ''))) {
        return false;
      }

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

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: SafeArea(
        child: Column(
          children: [
            // Clinical Precision Header
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
                    child: const Icon(Icons.people_outline_rounded, color: emeraldPrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text(
                              'Antrean Poli & Billing Pasien',
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
                              'Live Loket',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: emeraldPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${_queueItems.length} Antrean Terdaftar • Siap Dilayani di Kasir & Farmasi',
                          style: const TextStyle(fontSize: 11.5, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _fetchQueue,
                    tooltip: 'Segarkan Antrean',
                    icon: const Icon(Icons.refresh_rounded, color: emeraldPrimary),
                  ),
                ],
              ),
            ),

            // Search Bar & Poly Filters
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'Cari No. Antrean, RM, Nama Pasien, atau Dokter...',
                      hintStyle: const TextStyle(fontSize: 12.5, color: textMuted),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: textMuted),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Poly Pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _poliList.map((poli) {
                        final isSel = _selectedPoli == poli;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => setState(() => _selectedPoli = poli),
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSel ? emeraldPrimary : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSel ? emeraldPrimary : borderColor,
                                ),
                              ),
                              child: Text(
                                poli,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                  color: isSel ? Colors.white : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Status Pills
                  Row(
                    children: [
                      _buildStatusTab('all', 'Semua (${_queueItems.length})', emeraldPrimary),
                      const SizedBox(width: 6),
                      _buildStatusTab('ready', 'Siap Bayar', emeraldPrimary),
                      const SizedBox(width: 6),
                      _buildStatusTab('pending', 'Menunggu Resep', emeraldPrimary),
                      const SizedBox(width: 6),
                      _buildStatusTab('done', 'Selesai', emeraldPrimary),
                    ],
                  ),
                ],
              ),
            ),

            // Live Queue Summary Ribbon (Stitch Screen 2 Precision)
            _buildClinicSummaryStrip(emeraldPrimary),

            // Queue List / Grid
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: emeraldPrimary),
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Tidak ada antrean yang cocok dengan pencarian'
                                    : 'Belum ada antrean pasien untuk kategori ini',
                                style: const TextStyle(color: textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : isWide
                          ? GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 460,
                                mainAxisExtent: 220,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) => _buildQueueCard(filtered[index], emeraldPrimary),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(14),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) => _buildQueueCard(filtered[index], emeraldPrimary),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicSummaryStrip(Color emeraldPrimary) {
    final waitingCount = _queueItems.where((e) => e.status == 'ready' || e.status == 'pending').length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.receipt_long_rounded, color: emeraldPrimary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$waitingCount Pasien Menunggu Tagihan',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: Color(0xFF131B2E),
                        ),
                      ),
                      Text(
                        waitingCount > 0
                            ? 'Estimasi selesai poli: ~${waitingCount * 5} menit'
                            : 'Semua antrean saat ini telah tertangani',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF6D7A72)),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF85F8C4).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  DateTime.now().hour < 12
                      ? 'Sesi Pagi'
                      : (DateTime.now().hour < 17 ? 'Sesi Siang' : 'Sesi Malam'),
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF002114),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    AudioHelper.tapFeedback();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📢 Pemanggilan antrean audio loket diaktifkan.'),
                        backgroundColor: Color(0xFF006948),
                      ),
                    );
                  },
                  icon: const Icon(Icons.campaign_outlined, size: 16),
                  label: const Text('Panggil Antrean', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: emeraldPrimary,
                    side: BorderSide(color: emeraldPrimary.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    AudioHelper.tapFeedback();
                    PharmacyService.instance.switchTab(0);
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                  label: const Text('Tagihan Baru', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: emeraldPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTab(String key, String label, Color primary) {
    final isSel = _selectedStatus == key;
    return InkWell(
      onTap: () => setState(() => _selectedStatus = key),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSel ? primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
            color: isSel ? primary : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildQueueCard(ClinicPatientQueueItem item, Color primary) {
    final isReady = item.status == 'ready';
    final isDone = item.status == 'done';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isReady ? primary : const Color(0xFFE2E8F0),
          width: isReady ? 1.4 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Token & Patient Name & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.queueNumber,
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      item.patientName,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF131B2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isReady
                        ? const Color(0xFF006948)
                        : (isDone ? const Color(0xFF64748B) : const Color(0xFFB45309)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Row 2: Doctor & Poli & RM
          Text(
            '${item.medicalRecordNumber} • ${item.doctorName} • ${item.department}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF6D7A72)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Row 3: Insurance & Allergy Tag
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.insurance,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF006577)),
                ),
              ),
              if (item.allergy != null && item.allergy!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 11),
                      const SizedBox(width: 3),
                      Text(
                        'Alergi: ${item.allergy}',
                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const Spacer(),
          const Divider(height: 12, color: Color(0xFFF1F5F9)),

          // Row 4: Estimasi & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estimasi Tagihan:', style: TextStyle(fontSize: 9.5, color: Color(0xFF6D7A72))),
                  Text(
                    CurrencyFormatter.format(item.estimatedTotal),
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: primary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _callPatient(item),
                    icon: const Icon(Icons.volume_up_rounded, size: 14),
                    label: const Text('Panggil', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      side: BorderSide(color: primary.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 32),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: () => _loadToCashier(item),
                    icon: const Icon(Icons.point_of_sale_rounded, size: 14),
                    label: const Text('Ke Kasir', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 32),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
