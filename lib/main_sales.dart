import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/config/app_config.dart';
import 'core/config/app_theme.dart';
import 'core/storage/session_storage.dart';
import 'core/network/api_client.dart';
import 'core/services/app_update_service.dart';
import 'core/utils/app_locale.dart';
import 'core/components/splash_screen.dart';
import 'core/utils/fallback_localizations.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/cubit/auth_state.dart';
import 'features/auth/login_screen.dart';
import 'features/sales/sales_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.initialize(
    AppConfig(
      flavor: AppFlavor.sales,
      appName: 'Velora Sales',
    ),
  );

  try {
    await initAppLocale();
    await SessionStorage.init();
    ApiClient.init();
    AppUpdateService.init();
  } catch (e) {
    debugPrint('Bootstrap initialization error: $e');
  }

  runApp(
    BlocProvider(
      create: (context) => AuthCubit()..checkAuthStatus(),
      child: const VeloraSalesApp(),
    ),
  );
}

class VeloraSalesApp extends StatelessWidget {
  const VeloraSalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppUpdateService.navigatorKey,
      title: 'Velora Sales',
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
      theme: AppTheme.build(AppFlavor.sales, Brightness.light),
      home: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthInitial || (state is AuthLoading && state.message != null)) {
            return SplashScreen(
              message: state is AuthLoading ? state.message : 'Memuat sesi sales...',
            );
          }
          if (state is Authenticated) {
            return SalesDashboardScreen(
              onLogout: () => context.read<AuthCubit>().logout(),
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
