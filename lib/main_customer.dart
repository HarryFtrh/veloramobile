import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'core/config/app_theme.dart';
import 'core/storage/session_storage.dart';
import 'core/network/api_client.dart';
import 'core/utils/app_locale.dart';
import 'features/fnb_customer/customer_login_screen.dart';
import 'features/fnb_customer/customer_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.initialize(
    AppConfig(
      flavor: AppFlavor.customer,
      appName: 'Velora Self-Order',
    ),
  );
  debugPrint('🚀 [ENTRY] main_customer.dart flavor=${AppConfig.instance.flavor.name} app=${AppConfig.instance.appName}');

  try {
    await initAppLocale();
    await SessionStorage.init();
    ApiClient.init();
  } catch (e) {
    debugPrint('Bootstrap customer app error: $e');
  }

  runApp(const CustomerSelfOrderApp());
}

class CustomerSelfOrderApp extends StatefulWidget {
  const CustomerSelfOrderApp({super.key});

  @override
  State<CustomerSelfOrderApp> createState() => _CustomerSelfOrderAppState();
}

class _CustomerSelfOrderAppState extends State<CustomerSelfOrderApp> {
  bool _isChecking = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    final token = await SessionStorage.instance.getAuthToken();
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null && token.isNotEmpty;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Velora Self-Order',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(AppFlavor.customer, Brightness.light),
      home: _isChecking
          ? const Scaffold(
              backgroundColor: Color(0xFF24150D),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFFD9822B)),
              ),
            )
          : (_isLoggedIn
              ? CustomerHomeScreen(
                  onLogout: () async {
                    await SessionStorage.instance.clearAuthToken();
                    if (mounted) setState(() => _isLoggedIn = false);
                  },
                )
              : CustomerLoginScreen(
                  onLoginSuccess: () => setState(() => _isLoggedIn = true),
                )),
    );
  }
}
