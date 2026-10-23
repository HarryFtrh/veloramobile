import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/config/app_config.dart';
import 'core/config/app_theme.dart';
import 'core/storage/session_storage.dart';
import 'core/network/api_client.dart';
import 'core/components/splash_screen.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/cubit/auth_state.dart';
import 'features/auth/login_screen.dart';
import 'features/marketplace/marketplace_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.initialize(
    AppConfig(
      flavor: AppFlavor.marketplace,
      appName: 'Velora Marketplace',
    ),
  );

  try {
    await SessionStorage.init();
    ApiClient.init();
  } catch (e) {
    debugPrint('Bootstrap initialization error: $e');
  }

  runApp(
    BlocProvider(
      create: (context) => AuthCubit()..checkAuthStatus(),
      child: const VeloraMarketplaceApp(),
    ),
  );
}

class VeloraMarketplaceApp extends StatelessWidget {
  const VeloraMarketplaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Velora Marketplace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(AppFlavor.marketplace),
      home: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthInitial || (state is AuthLoading && state.message != null)) {
            return SplashScreen(
              message: state is AuthLoading ? state.message : 'Memuat sesi pembelian...',
            );
          }
          if (state is Authenticated) {
            return MarketplaceScreen(
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
