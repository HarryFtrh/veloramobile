import 'package:flutter/material.dart';
import '../../../../core/utils/audio_helper.dart';
import '../../pharmacy_service.dart';

/// Live queue summary ribbon showing patient count, estimation, and quick call button
class PharmacyQueueSummaryStrip extends StatelessWidget {
  final int waitingCount;
  final Color emeraldPrimary;

  const PharmacyQueueSummaryStrip({
    super.key,
    required this.waitingCount,
    required this.emeraldPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final sessionText = now.hour < 12
        ? 'Sesi Pagi'
        : (now.hour < 17 ? 'Sesi Siang' : 'Sesi Malam');

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
                          color: Color(0xFF0F172A),
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
                  sessionText,
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
                    final active = PharmacyService.instance.activePatient.value;
                    PharmacyService.instance.callQueueItem(
                      queueNumber: active?.queueNumber ?? 'A-001',
                      patientName: active?.patient ?? 'Pasien Berikutnya',
                      destination: 'Loket Farmasi 1',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📢 Pemanggilan antrean audio loket dikirim ke layar TV publik.'),
                        backgroundColor: Color(0xFF059669),
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
                    PharmacyService.instance.switchToPosTab();
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
}
