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
import 'features/pharmacy/pharmacy.dart';
import 'features/shared_pos/offline_sync_manager.dart';
import 'core/services/app_update_service.dart';
import 'features/shared_pos/printer_settings_modal.dart';
import 'features/shared_pos/receipt_printer_service.dart';

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
    ReceiptPrinterService.onOpenSettings = PrinterSettingsModal.show;
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
            return PharmacyAppShell(
              user: state.user,
              locationName: state.activeLocationName ?? 'Outlet Utama',
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
