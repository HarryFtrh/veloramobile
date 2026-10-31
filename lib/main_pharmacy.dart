import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/config/app_config.dart';
import 'core/config/app_theme.dart';
import 'core/storage/session_storage.dart';
import 'core/network/api_client.dart';
import 'core/utils/app_locale.dart';
import 'core/components/splash_screen.dart';
import 'core/utils/fallback_localizations.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/cubit/auth_state.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/finance/expenses_screen.dart';
import 'features/finance/return_screen.dart';
import 'features/pharmacy/pharmacy.dart';
import 'features/shared_pos/offline_sync_manager.dart';
import 'core/services/app_update_service.dart';
import 'features/shell/app_shell.dart';
import 'features/shell/more_screen.dart';
import 'features/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.initialize(
    AppConfig(
      flavor: AppFlavor.pharmacy,
      appName: 'Velora Pharmacy',
    ),
  );

  try {
    await initAppLocale();
    await SessionStorage.init();
    ApiClient.init();
    AppUpdateService.init();
    OfflineSyncManager.instance.startAutoSync();
  } catch (e) {
    debugPrint('Bootstrap initialization error: $e');
  }

  runApp(
    BlocProvider(
      create: (context) => AuthCubit()..checkAuthStatus(),
      child: const VeloraPharmacyApp(),
    ),
  );
}

class VeloraPharmacyApp extends StatelessWidget {
  const VeloraPharmacyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppUpdateService.navigatorKey,
      title: 'Velora Pharmacy',
      debugShowCheckedModeBanner: false,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        FallbackMaterialLocalizationsDelegate(),
        FallbackWidgetsLocalizationsDelegate(),
        FallbackCupertinoLocalizationsDelegate(),
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.ltr,
        child: child ?? const SizedBox.shrink(),
      ),
      theme: AppTheme.build(AppFlavor.pharmacy, Brightness.light),
      home: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthInitial || (state is AuthLoading && state.message != null)) {
            return SplashScreen(
              message: state is AuthLoading ? state.message : 'Memuat sesi...',
            );
          }
          if (state is Authenticated) {
            return AppShell(
              key: ValueKey(state.activeLocationName),
              tabControllerNotifier: PharmacyService.instance.activeTabNotifier,
              tabs: [
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
                  icon: Icons.people_outline_rounded,
                  selectedIcon: Icons.people_rounded,
                  builder: (_) => const PharmacyQueueScreen(),
                ),
                ShellTab(
                  label: 'Stok ED',
                  icon: Icons.warning_amber_rounded,
                  selectedIcon: Icons.warning_rounded,
                  builder: (_) => const PharmacyStockAlertScreen(),
                ),
                ShellTab(
                  label: 'Shift',
                  icon: Icons.analytics_outlined,
                  selectedIcon: Icons.analytics_rounded,
                  builder: (_) => const PharmacyShiftReportScreen(),
                ),
                ShellTab(
                  label: 'Lainnya',
                  icon: Icons.grid_view_outlined,
                  selectedIcon: Icons.grid_view_rounded,
                  builder: (_) => MoreScreen(
                    onLogout: () => context.read<AuthCubit>().logout(),
                    entries: [
                      MoreEntry(
                        icon: Icons.assignment_outlined,
                        title: 'Telaah Resep Dokter',
                        subtitle: 'Skrining 7 Benar & racikan pulveres',
                        builder: (_) => const PharmacyPrescriptionReviewPage(),
                      ),
                      MoreEntry(
                        icon: Icons.local_shipping_outlined,
                        title: 'Pengadaan Order PBF',
                        subtitle: 'Surat Pesanan (SP) & jatuh tempo faktur',
                        builder: (_) => const PharmacyPbfOrderPage(),
                      ),
                      MoreEntry(
                        icon: Icons.medical_information_outlined,
                        title: 'Rekam Medis & Riwayat Pasien',
                        subtitle: 'Histori obat, profil alergi, dan ulangi resep',
                        builder: (_) => const PharmacyMedicalRecordsPage(),
                      ),
                      MoreEntry(
                        icon: Icons.science_outlined,
                        title: 'Meja Racik & Etiket',
                        subtitle: 'Kalkulator DTD, mortar digital, cetak etiket',
                        builder: (_) => const PharmacyCompoundingScreen(),
                      ),
                      MoreEntry(
                        icon: Icons.tv_rounded,
                        title: 'Display Antrean Loket',
                        subtitle: 'Layar pemanggil nomor antrean publik',
                        builder: (_) => const PharmacyCallingDisplayScreen(),
                      ),
                      MoreEntry(
                        icon: Icons.bar_chart_rounded,
                        title: 'Analitik Apotek',
                        subtitle: 'Ringkasan omzet, laba kotor, dan tren',
                        builder: (_) => const DashboardScreen(),
                      ),
                      MoreEntry(
                        icon: Icons.payments_outlined,
                        title: 'Pengeluaran Kasir',
                        subtitle: 'Biaya operasional kas kecil apotek',
                        builder: (_) => const ExpensesScreen(),
                      ),
                      MoreEntry(
                        icon: Icons.assignment_return_outlined,
                        title: 'Retur Obat & Faktur',
                        subtitle: 'Retur obat dari invoice atau ke PBF',
                        builder: (_) => const ReturnScreen(),
                      ),
                      MoreEntry(
                        icon: Icons.settings_outlined,
                        title: 'Pengaturan & Printer',
                        subtitle: 'Akun, cabang, printer thermal, PIN',
                        builder: (_) => const SettingsScreen(),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return LoginScreen(
            onLoginSuccess: () => context.read<AuthCubit>().checkAuthStatus(),
          );
        },
      ),
    );
  }
}
