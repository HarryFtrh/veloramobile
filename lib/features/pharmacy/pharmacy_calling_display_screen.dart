import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/utils/audio_helper.dart';
import 'pharmacy_service.dart';
import 'widgets/calling/pharmacy_calling_hero_banner.dart';
import 'widgets/calling/pharmacy_calling_station_card.dart';

export 'widgets/calling/pharmacy_calling_hero_banner.dart';
export 'widgets/calling/pharmacy_calling_station_card.dart';

/// Display Layar Tablet Publik / TV Panggilan Loket Farmasi (Google Stitch "Clinical Precision")
class PharmacyCallingDisplayScreen extends StatefulWidget {
  const PharmacyCallingDisplayScreen({super.key});

  @override
  State<PharmacyCallingDisplayScreen> createState() => _PharmacyCallingDisplayScreenState();
}

class _PharmacyCallingDisplayScreenState extends State<PharmacyCallingDisplayScreen> {
  late Timer _clockTimer;
  Timer? _queuePollTimer;
  DateTime _now = DateTime.now();

  String _currentCallingToken = '-';
  String _currentCallingPatient = 'Menunggu Panggilan Antrean';
  String _currentCallingDestination = 'Loket 1 (Penyerahan Obat & Konseling)';

  List<Map<String, String>> _counterStations = [];

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _fetchLiveQueue();
    // Poll API antrean setiap 15 detik
    _queuePollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _fetchLiveQueue();
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _queuePollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLiveQueue() async {
    final list = await PharmacyService.instance.fetchPatientQueue();
    if (mounted) {
      setState(() {
        if (list.isNotEmpty) {
          final first = list.first;
          _currentCallingToken = first.queueNumber;
          _currentCallingPatient = first.patientName;
          _currentCallingDestination = 'Loket 1 (Penyerahan Obat & Konseling)';

          final List<Map<String, String>> stations = [];
          for (int i = 0; i < 3; i++) {
            final item = i < list.length ? list[i] : null;
            final loketNum = i + 1;
            final title = i == 0
                ? 'Penyerahan Obat & Konseling'
                : (i == 1 ? 'Kasir & Pembayaran Billing' : 'Penerimaan Resep & Telaah');
            stations.add({
              'counter': 'LOKET $loketNum',
              'title': title,
              'token': item?.queueNumber ?? '-',
              'patient': item?.patientName ?? 'Standby',
              'status': item != null ? (item.status == 'ready' ? 'Siap Dilayani' : 'Sedang Diproses') : 'Standby',
            });
          }
          _counterStations = stations;
        } else {
          _currentCallingToken = '-';
          _currentCallingPatient = 'Tidak Ada Antrean Aktif';
          _counterStations = [
            {
              'counter': 'LOKET 1',
              'title': 'Penyerahan Obat & Konseling',
              'token': '-',
              'patient': 'Standby',
              'status': 'Menunggu Antrean',
            },
            {
              'counter': 'LOKET 2',
              'title': 'Kasir & Pembayaran Billing',
              'token': '-',
              'patient': 'Standby',
              'status': 'Menunggu Antrean',
            },
            {
              'counter': 'LOKET 3',
              'title': 'Penerimaan Resep & Telaah',
              'token': '-',
              'patient': 'Standby',
              'status': 'Menunggu Antrean',
            },
          ];
        }
      });
    }
  }

  void _recallTicket(Map<String, String> station) {
    AudioHelper.tapFeedback();
    final token = station['token'] ?? '';
    final patient = station['patient'] ?? '';
    final dest = '${station['counter']} (${station['title']})';
    setState(() {
      _currentCallingToken = token;
      _currentCallingPatient = patient;
      _currentCallingDestination = dest;
    });
    PharmacyService.instance.callQueueItem(
      queueNumber: token,
      patientName: patient,
      destination: dest,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.campaign_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '📢 "Nomor Antrean $_currentCallingToken, silakan menuju $_currentCallingDestination"',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF059669);

    final timeStr =
        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')} WIB';

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: SafeArea(
        child: Column(
          children: [
            // Top Display Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(bottom: BorderSide(color: Color(0xFF283044))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: emeraldPrimary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Velora Pharmacy - Display Antrean Publik',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Display Layar Loket Farmasi & Penyerahan Obat',
                            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule_rounded, color: emeraldPrimary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Giant Calling Banner
            PharmacyCallingHeroBanner(
              token: _currentCallingToken,
              patient: _currentCallingPatient,
              destination: _currentCallingDestination,
            ),

            // Active Counters Row
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 700;
                    return isWide
                        ? Row(
                            children: _counterStations.map((station) {
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: PharmacyCallingStationCard(
                                    station: station,
                                    primaryColor: emeraldPrimary,
                                    onRecall: () => _recallTicket(station),
                                  ),
                                ),
                              );
                            }).toList(),
                          )
                        : ListView.separated(
                            itemCount: _counterStations.length,
                            separatorBuilder: (_, idx) => const SizedBox(height: 12),
                            itemBuilder: (context, index) => PharmacyCallingStationCard(
                              station: _counterStations[index],
                              primaryColor: emeraldPrimary,
                              onRecall: () => _recallTicket(_counterStations[index]),
                            ),
                          );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
