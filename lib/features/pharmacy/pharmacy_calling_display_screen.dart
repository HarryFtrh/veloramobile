import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/utils/audio_helper.dart';
import 'pharmacy_service.dart';

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
  bool _isLoading = true;

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
        _isLoading = false;
      });
    }
  }

  void _recallTicket(Map<String, String> station) {
    AudioHelper.tapFeedback();
    setState(() {
      _currentCallingToken = station['token'] ?? '';
      _currentCallingPatient = station['patient'] ?? '';
      _currentCallingDestination = '${station['counter']} (${station['title']})';
    });
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
        backgroundColor: const Color(0xFF006948),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF006948);
    const darkSurface = Color(0xFF131B2E);
    const borderColor = Color(0xFFE2E8F0);

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
                color: Color(0xFF131B2E),
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
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF006948), Color(0xFF004D34)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33006948),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF85F8C4),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'PANGGILAN LOKET TERBARU',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 1.5,
                          color: Color(0xFF85F8C4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentCallingToken,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontWeight: FontWeight.w900,
                      fontSize: 54,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    _currentCallingPatient,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Silakan menuju: $_currentCallingDestination',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF85F8C4),
                      ),
                    ),
                  ),
                ],
              ),
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
                                  child: _buildCounterCard(station, emeraldPrimary),
                                ),
                              );
                            }).toList(),
                          )
                        : ListView.separated(
                            itemCount: _counterStations.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) => _buildCounterCard(_counterStations[index], emeraldPrimary),
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

  Widget _buildCounterCard(Map<String, String> station, Color primary) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF283044)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              station['counter'] ?? '',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: primary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            station['title'] ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            station['token'] ?? '',
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.w900,
              fontSize: 34,
              color: Colors.white,
            ),
          ),
          Text(
            station['patient'] ?? '',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFFCBD5E1),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _recallTicket(station),
            icon: const Icon(Icons.volume_up_rounded, size: 16),
            label: const Text('Panggil Ulang', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: BorderSide(color: primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
