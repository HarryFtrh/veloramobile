import 'package:flutter/material.dart';
import '../queue/pharmacy_queue_modal_card.dart';

/// Active patient context card, live queue switcher, and vital signs monitoring
class DoctorPatientVitalCard extends StatelessWidget {
  final List<ClinicPatientQueueItem> liveQueue;
  final String queueNumber;
  final String patientName;
  final String medicalRecordNumber;
  final String bp;
  final String pulse;
  final String temp;
  final String allergies;
  final ValueChanged<ClinicPatientQueueItem> onSelectPatient;
  final VoidCallback onRefreshQueue;

  const DoctorPatientVitalCard({
    super.key,
    required this.liveQueue,
    required this.queueNumber,
    required this.patientName,
    required this.medicalRecordNumber,
    required this.bp,
    required this.pulse,
    required this.temp,
    required this.allergies,
    required this.onSelectPatient,
    required this.onRefreshQueue,
  });

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF059669);
    const textPrimary = Color(0xFF0F172A);
    const textMuted = Color(0xFF6D7A72);
    const borderColor = Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (liveQueue.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pilih Pasien dari Antrean Live:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: emeraldPrimary),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: emeraldPrimary),
                  tooltip: 'Segarkan Antrean Pasien',
                  onPressed: onRefreshQueue,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: liveQueue.map((q) {
                  final isSelected = q.queueNumber == queueNumber;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => onSelectPatient(q),
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
                      queueNumber,
                      style: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold, color: emeraldPrimary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    patientName,
                    style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                ],
              ),
              Text('No. RM: $medicalRecordNumber', style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11.5, color: textMuted)),
            ],
          ),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),

          // Vital signs
          Row(
            children: [
              Expanded(child: _buildVitalPill('Tensi Darah', bp, Icons.favorite_border_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _buildVitalPill('Nadi', pulse, Icons.monitor_heart_outlined)),
              const SizedBox(width: 8),
              Expanded(child: _buildVitalPill('Suhu', temp, Icons.thermostat_rounded)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFECEB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFCDD2), width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Peringatan Dokter: $allergies',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalPill(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: const Color(0xFF6D7A72)),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 9.5, color: Color(0xFF6D7A72))),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }
}
