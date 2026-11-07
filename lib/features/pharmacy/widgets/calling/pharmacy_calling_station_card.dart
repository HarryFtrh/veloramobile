import 'package:flutter/material.dart';

/// Counter station card on the calling display with recall button
class PharmacyCallingStationCard extends StatelessWidget {
  final Map<String, String> station;
  final VoidCallback onRecall;
  final Color primaryColor;

  const PharmacyCallingStationCard({
    super.key,
    required this.station,
    required this.onRecall,
    this.primaryColor = const Color(0xFF059669),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
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
              color: primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              station['counter'] ?? '',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: primaryColor,
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
            onPressed: onRecall,
            icon: const Icon(Icons.volume_up_rounded, size: 16),
            label: const Text('Panggil Ulang', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: BorderSide(color: primaryColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
