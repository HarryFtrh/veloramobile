import 'package:flutter/material.dart';
import '../../../../core/utils/audio_helper.dart';

/// Modal bottom sheet for choosing patient data source (Clinic queue vs manual input vs walk-in)
class PharmacyPatientSourceSheet extends StatelessWidget {
  final bool isClinicPatientLoaded;
  final VoidCallback onOpenQueue;
  final VoidCallback onOpenManualDialog;
  final VoidCallback onResetToWalkIn;

  const PharmacyPatientSourceSheet({
    super.key,
    required this.isClinicPatientLoaded,
    required this.onOpenQueue,
    required this.onOpenManualDialog,
    required this.onResetToWalkIn,
  });

  static Future<void> show({
    required BuildContext context,
    required bool isClinicPatientLoaded,
    required VoidCallback onOpenQueue,
    required VoidCallback onOpenManualDialog,
    required VoidCallback onResetToWalkIn,
  }) {
    AudioHelper.tapFeedback();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PharmacyPatientSourceSheet(
        isClinicPatientLoaded: isClinicPatientLoaded,
        onOpenQueue: onOpenQueue,
        onOpenManualDialog: onOpenManualDialog,
        onResetToWalkIn: onResetToWalkIn,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pilih Sumber Data Pasien',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Muat data dari antrean resep poli klinik atau input identitas langsung',
              style: TextStyle(color: Color(0xFF6D7A72), fontSize: 12),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.people_outline_rounded, color: Color(0xFF059669)),
              ),
              title: const Text(
                'Antrean Klinik & Billing Pasien',
                style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              subtitle: const Text(
                'Pilih pasien dari loket poli rawat jalan / dokter klinik',
                style: TextStyle(fontSize: 11, color: Color(0xFF6D7A72)),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF6D7A72)),
              onTap: () {
                Navigator.pop(context);
                onOpenQueue();
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.badge_outlined, color: Color(0xFF0D9488)),
              ),
              title: const Text(
                'Edit Identitas Pasien Manual',
                style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              subtitle: const Text(
                'Ketik manual nama pasien, No. RM, dokter perujuk, dan alergi',
                style: TextStyle(fontSize: 11, color: Color(0xFF6D7A72)),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF6D7A72)),
              onTap: () {
                Navigator.pop(context);
                onOpenManualDialog();
              },
            ),
            if (isClinicPatientLoaded) ...[
              const SizedBox(height: 10),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBA1A1A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_off_outlined, color: Color(0xFFBA1A1A)),
                ),
                title: const Text(
                  'Reset ke Pelanggan Walk-in (Umum)',
                  style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                subtitle: const Text(
                  'Hapus data pasien klinik & kembali ke transaksi umum',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6D7A72)),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF6D7A72)),
                onTap: () {
                  Navigator.pop(context);
                  onResetToWalkIn();
                },
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
