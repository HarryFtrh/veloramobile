import 'package:flutter/material.dart';

/// Giant Calling Hero Banner for pharmacy TV/tablet public calling display
class PharmacyCallingHeroBanner extends StatelessWidget {
  final String token;
  final String patient;
  final String destination;

  const PharmacyCallingHeroBanner({
    super.key,
    required this.token,
    required this.patient,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF004D34)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33059669),
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
            token,
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.w900,
              fontSize: 54,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          Text(
            patient,
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
              'Silakan menuju: $destination',
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
    );
  }
}
