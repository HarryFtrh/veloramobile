import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/config/app_config.dart';
import 'core/config/app_theme.dart';
import 'core/config/business_vertical.dart';
import 'core/storage/session_storage.dart';
import 'core/network/api_client.dart';
import 'core/utils/app_locale.dart';
import 'core/components/splash_screen.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/cubit/auth_state.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/fnb/fnb_register_screen.dart';
import 'features/tables/tables_screen.dart';
import 'features/kitchen/kitchen_screen.dart';
import 'features/pharmacy/pharmacy.dart';
import 'features/sales/sales_dashboard_screen.dart';
import 'features/marketplace/marketplace_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/shell/more_screen.dart';
import 'features/shell/more_menu_factory.dart';
import 'features/fnb_customer/customer_home_screen.dart';
import 'features/shared_pos/offline_sync_manager.dart';
import 'features/shared_pos/printer_settings_modal.dart';
import 'features/shared_pos/receipt_printer_service.dart';
import 'core/services/app_update_service.dart';
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
    AppUpdateService.init();
    ReceiptPrinterService.onOpenSettings = PrinterSettingsModal.show;
    OfflineSyncManager.instance.startAutoSync();
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
      navigatorKey: AppUpdateService.navigatorKey,
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
            switch (user.vertical) {
              case BusinessVertical.pharmacy:
                return PharmacyAppShell(
                  user: user,
                  locationName: state.activeLocationName ?? 'Outlet Utama',
                );

              case BusinessVertical.customer:
                return CustomerHomeScreen(
                  onLogout: () => context.read<AuthCubit>().logout(),
                );

              case BusinessVertical.sales:
                return SalesDashboardScreen(
                  onLogout: () => context.read<AuthCubit>().logout(),
                );

              case BusinessVertical.marketplace:
                return MarketplaceScreen(
                  onLogout: () => context.read<AuthCubit>().logout(),
                );

              case BusinessVertical.fnb:
                return _buildFnbAppShell(context, state, user);

              case BusinessVertical.retail:
                return _buildRetailAppShell(context, state, user);
            }
          }

          return LoginScreen(
            onLoginSuccess: () => context.read<AuthCubit>().checkAuthStatus(),
          );
        },
      ),
    );
  }

  Widget _buildFnbAppShell(BuildContext context, Authenticated state, AuthUser user) {
    final kasirTab = ShellTab(
      label: 'Kasir',
      icon: Icons.point_of_sale_outlined,
      selectedIcon: Icons.point_of_sale,
      builder: (_) => const FnbRegisterScreen(),
    );
    final mejaTab = ShellTab(
      label: 'Meja',
      icon: Icons.table_restaurant_outlined,
      selectedIcon: Icons.table_restaurant,
      builder: (ctx) => TablesScreen(
        onOpenTable: (t) => Navigator.of(ctx).push(
          MaterialPageRoute<void>(builder: (_) => FnbRegisterScreen(initialTable: t)),
        ),
      ),
    );
    final dapurTab = ShellTab(
      label: 'Dapur',
      icon: Icons.soup_kitchen_outlined,
      selectedIcon: Icons.soup_kitchen,
      builder: (_) => const KitchenScreen(),
    );
    final dashboardTab = ShellTab(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      builder: (_) => const DashboardScreen(),
    );
    final lainnyaTab = ShellTab(
      label: 'Lainnya',
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
      builder: (_) => MoreScreen(
        onLogout: () => context.read<AuthCubit>().logout(),
        entries: MoreMenuFactory.entriesFor(BusinessVertical.fnb),
      ),
    );

    final List<ShellTab> tabs;
    if (user.isKitchen) {
      tabs = [dapurTab, mejaTab, kasirTab, lainnyaTab];
    } else if (user.isWaiter) {
      tabs = [mejaTab, kasirTab, dapurTab, lainnyaTab];
    } else {
      tabs = [
        kasirTab,
        if (user.can(AppPermission.manageTables)) mejaTab,
        if (user.can(AppPermission.viewKitchen)) dapurTab,
        if (user.can(AppPermission.viewDashboard)) dashboardTab,
        lainnyaTab,
      ];
    }

    return AppShell(
      key: ValueKey('${state.activeLocationName}_${user.role}_fnb'),
      tabs: tabs,
    );
  }

  Widget _buildRetailAppShell(BuildContext context, Authenticated state, AuthUser user) {
    final kasirTab = ShellTab(
      label: 'Kasir',
      icon: Icons.point_of_sale_outlined,
      selectedIcon: Icons.point_of_sale,
      builder: (_) => const FnbRegisterScreen(),
    );
    final dashboardTab = ShellTab(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      builder: (_) => const DashboardScreen(),
    );
    final lainnyaTab = ShellTab(
      label: 'Lainnya',
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
      builder: (_) => MoreScreen(
        onLogout: () => context.read<AuthCubit>().logout(),
        entries: MoreMenuFactory.entriesFor(BusinessVertical.retail),
      ),
    );

    final tabs = [
      kasirTab,
      if (user.can(AppPermission.viewDashboard)) dashboardTab,
      lainnyaTab,
    ];

    return AppShell(
      key: ValueKey('${state.activeLocationName}_${user.role}_retail'),
      tabs: tabs,
    );
  }
}

