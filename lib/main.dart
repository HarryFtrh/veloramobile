import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/config/app_config.dart';
import 'core/config/app_theme.dart';
import 'core/storage/session_storage.dart';
import 'core/network/api_client.dart';
import 'core/utils/app_locale.dart';
import 'core/components/splash_screen.dart';
import 'core/security/anti_tamper_service.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/cubit/auth_state.dart';
import 'features/auth/login_screen.dart';
import 'features/customers/customers_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/fnb/fnb_register_screen.dart';
import 'features/tables/tables_screen.dart';
import 'features/kitchen/kitchen_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/shell/more_screen.dart';
import 'features/fnb/fnb_payment_split_screen.dart';
import 'features/fnb_customer/customer_home_screen.dart';
import 'core/utils/fallback_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.initialize(
    AppConfig(
      flavor: AppFlavor.fnb,
      appName: 'Velora POS',
    ),
  );
  debugPrint('🚀 [ENTRY] main.dart flavor=${AppConfig.instance.flavor.name} app=${AppConfig.instance.appName}');

  try {
    await initAppLocale();
    await SessionStorage.init();
    ApiClient.init();
    final integrity = await AntiTamperService.instance.verifyRuntimeIntegrity();
    if (!integrity.isSecure) {
      debugPrint('⚠️ Peringatan Keamanan Runtime: $integrity');
    }
  } catch (e) {
    debugPrint('Bootstrap initialization error: $e');
  }

  runApp(
    BlocProvider(
      create: (context) => AuthCubit()..checkAuthStatus(),
      child: const VeloraApp(),
    ),
  );
}

class VeloraApp extends StatelessWidget {
  const VeloraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Velora POS',
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
      theme: AppTheme.build(AppFlavor.fnb, Brightness.light),
      darkTheme: AppTheme.build(AppFlavor.fnb, Brightness.dark),
      themeMode: ThemeMode.system,
      home: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthInitial || (state is AuthLoading && state.message != null)) {
            return SplashScreen(
              message: state is AuthLoading ? state.message : 'Memuat sesi...',
            );
          }
          if (state is Authenticated) {
            final user = state.user;
            return AppShell(
              key: ValueKey('${state.activeLocationName}_${user.role}_${user.permissions.length}'),
              tabs: [
                ShellTab(
                  label: 'Kasir',
                  icon: Icons.point_of_sale_outlined,
                  selectedIcon: Icons.point_of_sale,
                  builder: (_) => const FnbRegisterScreen(),
                ),
                if (user.can(AppPermission.manageTables))
                  ShellTab(
                    label: 'Meja',
                    icon: Icons.table_restaurant_outlined,
                    selectedIcon: Icons.table_restaurant,
                    builder: (ctx) => TablesScreen(
                      onOpenTable: (t) => Navigator.of(ctx).push(
                        MaterialPageRoute<void>(builder: (_) => FnbRegisterScreen(initialTable: t)),
                      ),
                    ),
                  ),
                if (user.can(AppPermission.viewKitchen))
                  ShellTab(
                    label: 'Dapur',
                    icon: Icons.soup_kitchen_outlined,
                    selectedIcon: Icons.soup_kitchen,
                    builder: (_) => const KitchenScreen(),
                  ),
                if (user.can(AppPermission.viewDashboard))
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
                        icon: Icons.coffee_rounded,
                        title: 'Mode Pelanggan (Customer Self-Order)',
                        subtitle: 'Layar eksplorasi menu, kustomisasi kopi, & live tracking',
                        builder: (_) => const CustomerHomeScreen(),
                      ),
                      MoreEntry(
                        icon: Icons.call_split_rounded,
                        title: 'Kasir Split Bill & Pecahan Uang',
                        subtitle: 'Pembayaran bagi tagihan, numpad, & kalkulator kembalian',
                        builder: (_) => const FnbPaymentSplitScreen(),
                      ),
                      MoreEntry(
                        icon: Icons.people_outline_rounded,
                        title: 'Pelanggan & CRM',
                        subtitle: 'Daftar pelanggan dan riwayat transaksi',
                        builder: (_) => const CustomersScreen(),
                      ),
                      MoreEntry(
                        icon: Icons.settings_outlined,
                        title: 'Pengaturan & Cabang',
                        subtitle: 'Pilih cabang aktif, printer kasir, dan sesi',
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

