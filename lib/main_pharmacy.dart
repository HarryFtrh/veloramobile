import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/config/app_config.dart';
import 'core/config/app_theme.dart';
import 'core/storage/session_storage.dart';
import 'core/network/api_client.dart';
import 'core/utils/app_locale.dart';
import 'core/components/splash_screen.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/cubit/auth_state.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/finance/expenses_screen.dart';
import 'features/finance/return_screen.dart';
import 'features/pharmacy/pharmacy_pos_screen.dart';
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
      title: 'Velora Pharmacy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(AppFlavor.pharmacy),
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
              tabs: [
                ShellTab(
                  label: 'Kasir',
                  icon: Icons.point_of_sale_outlined,
                  selectedIcon: Icons.point_of_sale,
                  builder: (_) => PharmacyPosScreen(
                    onLogout: () => context.read<AuthCubit>().logout(),
                  ),
                ),
                ShellTab(
                  label: 'Ringkasan',
                  icon: Icons.bar_chart_outlined,
                  selectedIcon: Icons.bar_chart,
                  builder: (_) => const DashboardScreen(),
                ),
                ShellTab(
                  label: 'Lainnya',
                  icon: Icons.grid_view_outlined,
                  selectedIcon: Icons.grid_view_rounded,
                  builder: (_) => MoreScreen(
                    onLogout: () => context.read<AuthCubit>().logout(),
                    entries: [
                      MoreEntry(
                        icon: Icons.settings_outlined,
                        title: 'Pengaturan',
                        subtitle: 'Akun, cabang, printer, PIN, perangkat',
                        builder: (_) => const SettingsScreen(),
                      ),
                      MoreEntry(
                        icon: Icons.payments_outlined,
                        title: 'Pengeluaran',
                        subtitle: 'Catat biaya operasional bulanan',
                        builder: (_) => const ExpensesScreen(),
                      ),
                      MoreEntry(
                        icon: Icons.assignment_return_outlined,
                        title: 'Retur penjualan',
                        subtitle: 'Kembalikan barang dari invoice',
                        builder: (_) => const ReturnScreen(),
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
