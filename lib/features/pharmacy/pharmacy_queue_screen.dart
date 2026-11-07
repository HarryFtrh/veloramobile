import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/audio_helper.dart';
import 'pharmacy_service.dart';
import 'widgets/queue/pharmacy_queue_card.dart';
import 'widgets/queue/pharmacy_queue_summary_strip.dart';
import 'widgets/queue/pharmacy_queue_filters.dart';

export 'widgets/queue/pharmacy_queue_card.dart';
export 'widgets/queue/pharmacy_queue_summary_strip.dart';
export 'widgets/queue/pharmacy_queue_filters.dart';

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
        backgroundColor: const Color(0xFF059669),
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
      prescribedDrugs: item.prescribedDrugs,
    );

    PharmacyService.instance.setActivePatient(patientData);
    PharmacyService.instance.switchToPosTab();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pasien ${item.queueNumber} (${item.patientName}) dimuat ke Kasir POS.'),
        backgroundColor: const Color(0xFF059669),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF059669);
    const textPrimary = Color(0xFF0F172A);
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

    final waitingCount = _queueItems.where((e) => e.status == 'ready' || e.status == 'pending').length;

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
                    child: const Icon(Icons.people_alt_outlined, color: emeraldPrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Antrean Resep & Billing Klinik',
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
                              'Live Bridge SIMRS',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: emeraldPrimary),
                            ),
                          ],
                        ),
                        Text(
                          'Integrasi Rekam Medis Poli, e-Resep, & Billing Pasien',
                          style: TextStyle(fontSize: 11.5, color: textMuted),
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
            PharmacyQueueFilters(
              searchController: _searchController,
              searchQuery: _searchQuery,
              poliList: _poliList,
              selectedPoli: _selectedPoli,
              selectedStatus: _selectedStatus,
              totalCount: _queueItems.length,
              emeraldPrimary: emeraldPrimary,
              onSearchChanged: (val) => setState(() => _searchQuery = val.trim()),
              onClearSearch: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              onSelectPoli: (poli) => setState(() => _selectedPoli = poli),
              onSelectStatus: (status) => setState(() => _selectedStatus = status),
            ),

            // Live Queue Summary Ribbon
            PharmacyQueueSummaryStrip(
              waitingCount: waitingCount,
              emeraldPrimary: emeraldPrimary,
            ),

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
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                return PharmacyQueueCard(
                                  item: item,
                                  primary: emeraldPrimary,
                                  onCall: () => _callPatient(item),
                                  onLoadToCashier: () => _loadToCashier(item),
                                );
                              },
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(14),
                              itemCount: filtered.length,
                              separatorBuilder: (_, idx) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                return PharmacyQueueCard(
                                  item: item,
                                  primary: emeraldPrimary,
                                  onCall: () => _callPatient(item),
                                  onLoadToCashier: () => _loadToCashier(item),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
