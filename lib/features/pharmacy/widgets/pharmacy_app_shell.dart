import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/auth_service.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../finance/return_screen.dart';
import '../../shell/app_shell.dart';
import '../pharmacy_service.dart';
import '../pharmacy_pos_screen.dart';
import '../pharmacy_queue_screen.dart';
import '../pharmacy_stock_alert_screen.dart';
import '../pharmacy_shift_report_screen.dart';
import '../pharmacy_compounding_screen.dart';
import '../pharmacy_stock_opname_screen.dart';
import '../pharmacy_doctor_emr_screen.dart';
import '../pharmacy_executive_analytics_screen.dart';
import 'pharmacy_medical_records_modal.dart';
import 'pharmacy_pbf_order_modal.dart';
import 'pharmacy_prescription_review_modal.dart';
import 'pharmacy_more_screen.dart';

/// Role-Aware Workstation Shell untuk Apotek & Klinik Farmasi
/// Memetakan antarmuka awal secara otomatis sesuai profesi staf:
/// - Dokter -> EMR Rekam Medis & Form e-Resep Pasien
/// - Apoteker -> Telaah Resep (Skrining 7 Benar) & Meja Racik
/// - Gudang & Logistik -> Stok Obat ED FEFO & Stock Opname
/// - Kasir -> Kasir POS Apotek & Antrean Loket
/// - Owner/Admin -> Executive Analytics & Gross Margin
class PharmacyAppShell extends StatelessWidget {
  final AuthUser user;
  final String? locationName;

  const PharmacyAppShell({
    super.key,
    required this.user,
    this.locationName,
  });

  @override
  Widget build(BuildContext context) {
    final isDoctor = user.isDoctor;
    final isPharmacist = user.isPharmacist;
    final isWarehouse = user.isWarehouse;
    final isOwnerOrAdmin = user.isOwnerOrAdmin;

    final List<ShellTab> tabs;

    if (isDoctor) {
      PharmacyService.instance.posTabIndex = 0;
      // 🩺 WORKSTATION DOKTER & POLI KLINIK: Langsung buka EMR & Form e-Resep
      tabs = [
        ShellTab(
          label: 'e-Resep & EMR',
          icon: Icons.medical_services_outlined,
          selectedIcon: Icons.medical_services_rounded,
          builder: (_) => const PharmacyDoctorEmrScreen(),
        ),
        ShellTab(
          label: 'Antrean Pasien',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long_rounded,
          builder: (_) => const PharmacyQueueScreen(),
        ),
        ShellTab(
          label: 'Rekam Medis',
          icon: Icons.medical_information_outlined,
          selectedIcon: Icons.medical_information_rounded,
          builder: (_) => const PharmacyMedicalRecordsPage(),
        ),
        ShellTab(
          label: 'Stok Obat',
          icon: Icons.medication_outlined,
          selectedIcon: Icons.medication_rounded,
          builder: (_) => const PharmacyStockAlertScreen(),
        ),
        _buildMoreTab(context),
      ];
    } else if (isPharmacist) {
      PharmacyService.instance.posTabIndex = 2;
      // 🧪 WORKSTATION APOTEKER & FARMASI KLINIS: Langsung buka Telaah Resep Dokter
      tabs = [
        ShellTab(
          label: 'Telaah Resep',
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment_rounded,
          builder: (_) => PharmacyPrescriptionReviewPage(
            onApprove: () => PharmacyService.instance.switchTab(1),
          ),
        ),
        ShellTab(
          label: 'Meja Racik',
          icon: Icons.science_outlined,
          selectedIcon: Icons.science_rounded,
          builder: (_) => const PharmacyCompoundingScreen(),
        ),
        ShellTab(
          label: 'Kasir',
          icon: Icons.point_of_sale_outlined,
          selectedIcon: Icons.point_of_sale_rounded,
          builder: (_) => PharmacyPosScreen(
            onLogout: () => context.read<AuthCubit>().logout(),
          ),
        ),
        ShellTab(
          label: 'Antrean',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long_rounded,
          builder: (_) => const PharmacyQueueScreen(),
        ),
        _buildMoreTab(context),
      ];
    } else if (isWarehouse) {
      PharmacyService.instance.posTabIndex = 0;
      // 📦 WORKSTATION GUDANG & LOGISTIK OBAT: Langsung buka Stok FEFO & Opname
      tabs = [
        ShellTab(
          label: 'Stok Obat & ED',
          icon: Icons.medication_outlined,
          selectedIcon: Icons.medication_rounded,
          builder: (_) => const PharmacyStockAlertScreen(),
        ),
        ShellTab(
          label: 'Stock Opname',
          icon: Icons.inventory_rounded,
          selectedIcon: Icons.inventory_rounded,
          builder: (_) => const PharmacyStockOpnameScreen(),
        ),
        ShellTab(
          label: 'Order PBF',
          icon: Icons.local_shipping_outlined,
          selectedIcon: Icons.local_shipping_rounded,
          builder: (_) => const PharmacyPbfOrderPage(),
        ),
        ShellTab(
          label: 'Retur',
          icon: Icons.assignment_return_outlined,
          selectedIcon: Icons.assignment_return_rounded,
          builder: (_) => const ReturnScreen(),
        ),
        _buildMoreTab(context),
      ];
    } else if (isOwnerOrAdmin) {
      PharmacyService.instance.posTabIndex = 1;
      // 📊 WORKSTATION OWNER & EKSEKUTIF KLINIK/APOTEK: Langsung buka Executive Analytics
      tabs = [
        ShellTab(
          label: 'Executive',
          icon: Icons.insights_rounded,
          selectedIcon: Icons.insights_rounded,
          builder: (_) => const PharmacyExecutiveAnalyticsScreen(),
        ),
        ShellTab(
          label: 'Kasir',
          icon: Icons.point_of_sale_outlined,
          selectedIcon: Icons.point_of_sale_rounded,
          builder: (_) => PharmacyPosScreen(
            onLogout: () => context.read<AuthCubit>().logout(),
          ),
        ),
        ShellTab(
          label: 'Antrean',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long_rounded,
          builder: (_) => const PharmacyQueueScreen(),
        ),
        ShellTab(
          label: 'Stok Obat',
          icon: Icons.medication_outlined,
          selectedIcon: Icons.medication_rounded,
          builder: (_) => const PharmacyStockAlertScreen(),
        ),
        _buildMoreTab(context),
      ];
    } else {
      PharmacyService.instance.posTabIndex = 0;
      // 🛒 WORKSTATION KASIR FARMASI (DEFAULT CASHIER)
      tabs = [
        ShellTab(
          label: 'Kasir',
          icon: Icons.point_of_sale_outlined,
          selectedIcon: Icons.point_of_sale_rounded,
          builder: (_) => PharmacyPosScreen(
            onLogout: () => context.read<AuthCubit>().logout(),
          ),
        ),
        ShellTab(
          label: 'Antrean',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long_rounded,
          builder: (_) => const PharmacyQueueScreen(),
        ),
        ShellTab(
          label: 'Stok Obat',
          icon: Icons.medication_outlined,
          selectedIcon: Icons.medication_rounded,
          builder: (_) => const PharmacyStockAlertScreen(),
        ),
        ShellTab(
          label: 'Laporan',
          icon: Icons.analytics_outlined,
          selectedIcon: Icons.analytics_rounded,
          builder: (_) => const PharmacyShiftReportScreen(),
        ),
        _buildMoreTab(context),
      ];
    }

    return AppShell(
      key: ValueKey('${locationName}_${user.role}_${user.roleDisplayName}'),
      tabControllerNotifier: PharmacyService.instance.activeTabNotifier,
      tabs: tabs,
    );
  }

  ShellTab _buildMoreTab(BuildContext context) {
    return ShellTab(
      label: 'Layanan',
      icon: Icons.dashboard_customize_outlined,
      selectedIcon: Icons.dashboard_customize_rounded,
      builder: (_) => PharmacyMoreScreen(
        user: user,
        locationName: locationName,
      ),
    );
  }
}
