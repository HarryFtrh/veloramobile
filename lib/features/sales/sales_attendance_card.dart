import 'package:flutter/material.dart';

class SalesAttendanceCard extends StatelessWidget {
  final bool isClockedIn;
  final DateTime? clockInTime;
  final bool isLoading;
  final VoidCallback onClockToggle;
  final Color accentColor;

  const SalesAttendanceCard({
    super.key,
    required this.isClockedIn,
    required this.clockInTime,
    required this.isLoading,
    required this.onClockToggle,
    this.accentColor = const Color(0xFF818CF8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF252B63),
            Color(0xFF171A35),
            Color(0xFF121522),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.route_rounded,
                  color: accentColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isClockedIn ? 'Kamu sedang bertugas' : 'Siap mulai bekerja?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isClockedIn
                          ? 'Presensi aktif di lapangan'
                          : 'Presensi lokasi untuk memulai rute',
                      style: const TextStyle(
                        color: Color(0xFFB6BDD6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: isClockedIn
                      ? const Color(0xFF34D399)
                      : const Color(0xFFFBBF24),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isClockedIn
                              ? const Color(0xFF34D399)
                              : const Color(0xFFFBBF24))
                          .withValues(alpha: 0.45),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STATUS PRESENSI',
                      style: TextStyle(
                        color: Color(0xFFA8AFCA),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isClockedIn && clockInTime != null
                          ? 'Mulai ${clockInTime!.hour.toString().padLeft(2, '0')}:${clockInTime!.minute.toString().padLeft(2, '0')}'
                          : 'Belum clock-in',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.my_location_rounded,
                color: Color(0xFFA5B4FC),
                size: 20,
              ),
              const SizedBox(width: 6),
              const Text(
                'GPS aktif',
                style: TextStyle(
                  color: Color(0xFFD7DBF0),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onClockToggle,
              style: ElevatedButton.styleFrom(
                backgroundColor: isClockedIn
                    ? const Color(0xFFB93852)
                    : accentColor,
                disabledBackgroundColor: accentColor.withValues(alpha: 0.55),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: isLoading
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      isClockedIn
                          ? Icons.stop_circle_outlined
                          : Icons.location_on_rounded,
                      size: 19,
                    ),
              label: Text(
                isClockedIn ? 'Akhiri Presensi' : 'Clock-in dengan GPS',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
