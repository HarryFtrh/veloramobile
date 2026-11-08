import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/utils/audio_helper.dart';
import '../../auth/auth_service.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../dashboard/dashboard_screen.dart';
import '../../finance/expenses_screen.dart';
import '../../finance/return_screen.dart';
import '../../settings/settings_screen.dart';
import '../../shared_pos/printer_settings_screen.dart';
import '../../shared_pos/receipt_printer_service.dart';
import '../../shared_pos/shift_badge.dart';
import '../../subscription/subscription_screen.dart';
import '../pharmacy_calling_display_screen.dart';
import '../pharmacy_compounding_screen.dart';
import '../pharmacy_doctor_emr_screen.dart';
import '../pharmacy_executive_analytics_screen.dart';
import '../pharmacy_queue_screen.dart';
import '../pharmacy_stock_opname_screen.dart';
import 'pharmacy_medical_records_modal.dart';
import 'pharmacy_pbf_order_modal.dart';
import 'pharmacy_prescription_review_modal.dart';

/// Hub Menu Layanan Apotek Modern & Berkelas (Apotek Command Center)
class PharmacyMoreScreen extends StatelessWidget {
  final AuthUser user;
  final String? locationName;

  const PharmacyMoreScreen({
    super.key,
    required this.user,
    this.locationName,
  });

  void _confirmLogout(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFBA1A1A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: Color(0xFFBA1A1A), size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Keluar dari Akun?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF191C1E)),
              ),
            ),
          ],
        ),
        content: const Text(
          'Pastikan seluruh transaksi kasir apotek telah tersimpan sebelum keluar.',
          style: TextStyle(fontSize: 13, color: Color(0xFF404943)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF6D7A72))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx, true);
              context.read<AuthCubit>().logout();
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = user.name.isNotEmpty ? user.name : (SessionStorage.instance.getUserName() ?? 'Apoteker Bertugas');
    final tenantName = SessionStorage.instance.getTenantName() ?? 'Velora Pharmacy';
    final branchName = locationName ?? SessionStorage.instance.getLocationName() ?? 'Unit Pelayanan Farmasi';
    final roleTitle = user.roleDisplayName.isNotEmpty ? user.roleDisplayName : 'Tenaga Medis Farmasi';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      body: CustomScrollView(
        slivers: [
          // 1. Sleek Gradient Medical Header
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF004D34),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF003825), Color(0xFF006C4C), Color(0xFF008962)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.15),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          userName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.verified_rounded, color: Color(0xFF6FF7B5), size: 16),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    roleTitle,
                                    style: const TextStyle(
                                      color: Color(0xFFB4F0CF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    '$tenantName • $branchName',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.75),
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const CashierShiftBadge(),
                          ],
                        ),
                        const Spacer(),
                        // Status Bar Strip: SatuSehat & Keystore Ready
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_rounded, size: 13, color: Color(0xFF6FF7B5)),
                              SizedBox(width: 6),
                              Text(
                                'SatuSehat Kemenkes • Keystore Encrypted • 60 FPS Engine',
                                style: TextStyle(
                                  color: Color(0xFFE1F5EC),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. Body List of Modules & Bento Cards
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Operational Bar (Laci Kasir & Printer)
                      _buildQuickActionBar(context),
                      const SizedBox(height: 22),

                      // Section 1: Pelayanan Resep & Farmasi Klinis
                      _buildSectionHeader('PELAYANAN RESEP & FARMASI KLINIS', Icons.medical_services_rounded, const Color(0xFF006C4C)),
                      const SizedBox(height: 8),
                      _buildModuleCard(
                        context: context,
                        icon: Icons.assignment_turned_in_rounded,
                        iconBg: const Color(0xFFE8F5E9),
                        iconColor: const Color(0xFF2E7D32),
                        title: 'Telaah Resep Dokter (Skrining 7 Benar)',
                        subtitle: 'Pemeriksaan administratif, farmasetik, klinis & DTD',
                        badgeText: 'Klinis',
                        badgeColor: const Color(0xFFE8F5E9),
                        badgeTextColor: const Color(0xFF1B5E20),
                        destination: const PharmacyPrescriptionReviewPage(),
                      ),
                      const SizedBox(height: 8),
                      _buildModuleCard(
                        context: context,
                        icon: Icons.science_rounded,
                        iconBg: const Color(0xFFEDE7F6),
                        iconColor: const Color(0xFF673AB7),
                        title: 'Meja Racik & Etiket Thermal',
                        subtitle: 'Kalkulator pulveres DTD, mortar digital, cetak aturan pakai',
                        badgeText: 'Racikan',
                        badgeColor: const Color(0xFFEDE7F6),
                        badgeTextColor: const Color(0xFF512DA8),
                        destination: const PharmacyCompoundingScreen(),
                      ),
                      const SizedBox(height: 8),
                      _buildModuleCard(
                        context: context,
                        icon: Icons.badge_outlined,
                        iconBg: const Color(0xFFE0F7FA),
                        iconColor: const Color(0xFF00838F),
                        title: 'Rekam Medis & Riwayat Pasien',
                        subtitle: 'Histori obat, profil alergi SatuSehat, dan copy resep',
                        destination: const PharmacyMedicalRecordsPage(),
                      ),
                      const SizedBox(height: 8),
                      _buildModuleCard(
                        context: context,
                        icon: Icons.tv_rounded,
                        iconBg: const Color(0xFFE3F2FD),
                        iconColor: const Color(0xFF1976D2),
                        title: 'Display Antrean Loket TV',
                        subtitle: 'Layar pemanggil nomor antrean audio & visual publik',
                        destination: const PharmacyCallingDisplayScreen(),
                      ),

                      const SizedBox(height: 24),

                      // Section 2: Pengadaan & Logistik Obat (Medical Blue Theme)
                      _buildSectionHeader('PENGADAAN & LOGISTIK OBAT', Icons.inventory_2_rounded, const Color(0xFF0284C7)),
                      const SizedBox(height: 8),
                      _buildModuleCard(
                        context: context,
                        icon: Icons.local_shipping_rounded,
                        iconBg: const Color(0xFFE0F2FE),
                        iconColor: const Color(0xFF0284C7),
                        title: 'Pengadaan Order PBF (Surat Pesanan)',
                        subtitle: 'SP Reguler, Prekursor, OOT, dan kontrol jatuh tempo faktur',
                        badgeText: 'SP PBF',
                        badgeColor: const Color(0xFFE0F2FE),
                        badgeTextColor: const Color(0xFF0369A1),
                        destination: const PharmacyPbfOrderPage(),
                      ),
                      const SizedBox(height: 8),
                      _buildModuleCard(
                        context: context,
                        icon: Icons.qr_code_scanner_rounded,
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                        title: 'Stock Opname Fisik & FEFO',
                        subtitle: 'Pencocokan stok nyata, nomor batch lot, dan berita acara',
                        badgeText: 'Audit FEFO',
                        badgeColor: const Color(0xFFEFF6FF),
                        badgeTextColor: const Color(0xFF1D4ED8),
                        destination: const PharmacyStockOpnameScreen(),
                      ),
                      const SizedBox(height: 8),
                      _buildModuleCard(
                        context: context,
                        icon: Icons.assignment_return_rounded,
                        iconBg: const Color(0xFFFFEBEE),
                        iconColor: const Color(0xFFC62828),
                        title: 'Retur Obat & Faktur Pembelian',
                        subtitle: 'Klaim retur obat kadaluarsa/rusak ke PBF atau dari pasien',
                        destination: const ReturnScreen(),
                      ),

                      const SizedBox(height: 24),

                      // Section 3: Integrasi Dokter & Poli Klinik
                      _buildSectionHeader('INTEGRASI DOKTER & POLI', Icons.health_and_safety_rounded, const Color(0xFF0D9488)),
                      const SizedBox(height: 8),
                      _buildModuleCard(
                        context: context,
                        icon: Icons.edit_note_rounded,
                        iconBg: const Color(0xFFE0F2F1),
                        iconColor: const Color(0xFF00796B),
                        title: 'Workstation Dokter & e-Resep',
                        subtitle: 'Pemeriksaan EMR, diagnosa ICD-10, dan resep digital langsung',
                        destination: const PharmacyDoctorEmrScreen(),
                      ),

                      const SizedBox(height: 24),

                      // Section 4: Keuangan & Analitik Eksekutif
                      _buildSectionHeader('KEUANGAN & ANALITIK BISNIS', Icons.analytics_rounded, const Color(0xFF4F46E5)),
                      const SizedBox(height: 8),
                      _buildModuleCard(
                        context: context,
                        icon: Icons.insights_rounded,
                        iconBg: const Color(0xFFEEF2FF),
                        iconColor: const Color(0xFF4338CA),
                        title: 'Executive Analytics & Margin Laba',
                        subtitle: 'Gross profit margin, HPP obat, omzet riil, dan performa laba',
                        badgeText: 'Eksekutif',
                        badgeColor: const Color(0xFFEEF2FF),
                        badgeTextColor: const Color(0xFF3730A3),
                        destination: const PharmacyExecutiveAnalyticsScreen(),
                      ),
                      const SizedBox(height: 8),
                      _buildModuleCard(
                        context: context,
                        icon: Icons.bar_chart_rounded,
                        iconBg: const Color(0xFFF3E8FF),
                        iconColor: const Color(0xFF7E22CE),
                        title: 'Dashboard Performa Apotek',
                        subtitle: 'Grafik transaksi, tren penjualan, dan produk terlaris',
                        destination: const DashboardScreen(),
                      ),
                      const SizedBox(height: 8),
                      _buildModuleCard(
                        context: context,
                        icon: Icons.payments_rounded,
                        iconBg: const Color(0xFFFCE7F3),
                        iconColor: const Color(0xFFBE185D),
                        title: 'Buku Pengeluaran Kasir',
                        subtitle: 'Pencatatan kas kecil (petty cash) dan beban operasional toko',
                        destination: const ExpensesScreen(),
                      ),

                      const SizedBox(height: 24),

                      // Section 5: Perangkat & Hardware
                      _buildSectionHeader('PERANGKAT KERAS & HARDWARE', Icons.print_rounded, const Color(0xFF475569)),
                      const SizedBox(height: 8),
                      _buildModuleCard(
                        context: context,
                        icon: Icons.print_rounded,
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                        title: 'Printer Struk & Hardware Apotek',
                        subtitle: 'Konfigurasi Bluetooth, LAN port 9100, etiket, & laci kas',
                        destination: const PrinterSettingsScreen(),
                      ),

                      const SizedBox(height: 24),

                      // Section 6: Lisensi & Pengaturan
                      _buildSectionHeader('LISENSI & PENGATURAN AKUN', Icons.settings_rounded, const Color(0xFF475569)),
                      const SizedBox(height: 8),
                      _buildModuleCard(
                        context: context,
                        icon: Icons.workspace_premium_rounded,
                        iconBg: const Color(0xFFFEF3C7),
                        iconColor: const Color(0xFFD97706),
                        title: 'Paket & Langganan Apotek',
                        subtitle: 'Status paket Velora Pro, kuota transaksi, & masa aktif',
                        destination: const SubscriptionScreen(),
                      ),
                      const SizedBox(height: 10),
                      _buildModuleCard(
                        context: context,
                        icon: Icons.tune_rounded,
                        iconBg: const Color(0xFFF1F5F9),
                        iconColor: const Color(0xFF334155),
                        title: 'Pengaturan Akun & Keamanan',
                        subtitle: 'Profil apoteker, PIN cepat kasir, & sesi perangkat',
                        destination: const SettingsScreen(),
                      ),

                      const SizedBox(height: 32),

                      // Tombol Keluar / Logout
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmLogout(context),
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text(
                            'Keluar dari Akun Kasir',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFBA1A1A),
                            side: const BorderSide(color: Color(0xFFFFDAD6), width: 1.5),
                            backgroundColor: const Color(0xFFFFDAD6).withValues(alpha: 0.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Velora Mobile v2.0 • Apotek & Klinik Edition',
                          style: TextStyle(fontSize: 11, color: Color(0xFF8A938C), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E4DF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickButton(
              context: context,
              icon: Icons.point_of_sale_rounded,
              label: 'Buka Laci',
              color: const Color(0xFF006C4C),
              onTap: () async {
                AudioHelper.actionFeedback();
                await ReceiptPrinterService.instance.openCashDrawer();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Sinyal pembuka laci kasir (Cash Drawer) telah dikirim.'),
                      backgroundColor: Color(0xFF006C4C),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ),
          Container(height: 28, width: 1, color: const Color(0xFFE1E4DF)),
          Expanded(
            child: _buildQuickButton(
              context: context,
              icon: Icons.print_rounded,
              label: 'Set Printer',
              color: const Color(0xFF1E293B),
              onTap: () {
                AudioHelper.tapFeedback();
                ReceiptPrinterService.instance.openSettings(context);
              },
            ),
          ),
          Container(height: 28, width: 1, color: const Color(0xFFE1E4DF)),
          Expanded(
            child: _buildQuickButton(
              context: context,
              icon: Icons.record_voice_over_rounded,
              label: 'Panggil Loket',
              color: const Color(0xFF0284C7),
              onTap: () {
                AudioHelper.tapFeedback();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PharmacyQueueScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildModuleCard({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget destination,
    String? badgeText,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            AudioHelper.tapFeedback();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => destination),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (badgeText != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeColor ?? const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                badgeText,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: badgeTextColor ?? const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFCBD5E1)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
