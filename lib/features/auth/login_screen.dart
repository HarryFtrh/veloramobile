import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/config/app_config.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/audio_helper.dart';
import 'auth_service.dart';
import 'widgets/branch_selector_dialog.dart';
import 'widgets/forgot_password_dialog.dart';
import 'widgets/login_branding.dart';
import 'widgets/register_tenant_dialog.dart';
import 'widgets/velora_animated_login_view.dart';

export 'widgets/branch_selector_dialog.dart';
export 'widgets/forgot_password_dialog.dart';
export 'widgets/login_branding.dart';
export 'widgets/register_tenant_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
  });

  final VoidCallback onLoginSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isLoginSuccess = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  String? _errorMessage;

  LoginBranding get _branding => LoginBranding.of(AppConfig.instance.flavor);

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return 'Selamat Pagi';
    if (hour >= 11 && hour < 15) return 'Selamat Siang';
    if (hour >= 15 && hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  void _loadRememberedCredentials() {
    final remember = SessionStorage.instance.getRememberMe();
    final savedId = SessionStorage.instance.getSavedLoginIdentifier();
    setState(() {
      _rememberMe = remember;
      if (remember && savedId != null && savedId.isNotEmpty) {
        _emailController.text = savedId;
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Email atau username dan kata sandi wajib diisi');
      AudioHelper.errorFeedback();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.instance.login(
        email: email,
        password: password,
      );

      // Simpan preferensi Ingat Saya dan kredensial login
      await SessionStorage.instance.saveRememberMe(
        rememberMe: _rememberMe,
        identifier: _rememberMe ? email : null,
      );

      AudioHelper.successFeedback();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoginSuccess = true;
        });
        await Future<void>.delayed(const Duration(milliseconds: 480));
        if (!mounted) return;
        if (user.locations.length > 1) {
          setState(() => _isLoginSuccess = false);
          _showBranchSelectorDialog(user.locations);
        } else {
          widget.onLoginSuccess();
        }
      }
    } on DioException catch (e) {
      AudioHelper.errorFeedback();
      String? msg;
      final resData = e.response?.data;
      if (resData is Map) {
        msg = resData['message']?.toString();
      } else if (resData is String && resData.isNotEmpty) {
        msg = resData;
      }
      if (mounted) {
        setState(() => _errorMessage = msg ?? 'Login gagal. Periksa koneksi internet atau kredensial Anda.');
      }
    } catch (e) {
      AudioHelper.errorFeedback();
      final errText = e.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        setState(() => _errorMessage = errText.isNotEmpty ? errText : 'Terjadi kesalahan tidak terduga.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.instance.loginWithGoogle();
      if (user == null) {
        // Pengguna membatalkan dialog pemilihan akun Google
        return;
      }

      AudioHelper.successFeedback();

      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
          _isLoginSuccess = true;
        });
        await Future<void>.delayed(const Duration(milliseconds: 480));
        if (!mounted) return;
        if (user.locations.length > 1) {
          setState(() => _isLoginSuccess = false);
          _showBranchSelectorDialog(user.locations);
        } else {
          widget.onLoginSuccess();
        }
      }
    } on DioException catch (e) {
      AudioHelper.errorFeedback();
      String? msg;
      final resData = e.response?.data;
      if (resData is Map) {
        msg = resData['message']?.toString();
      } else if (resData is String && resData.isNotEmpty) {
        msg = resData;
      }
      if (mounted) {
        setState(() => _errorMessage = msg ?? 'Login Google gagal. Periksa koneksi internet Anda.');
      }
    } catch (e) {
      AudioHelper.errorFeedback();
      final errText = e.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        setState(() => _errorMessage = errText.isNotEmpty ? errText : 'Login Google gagal. Gunakan email & kata sandi.');
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  void _showBranchSelectorDialog(List<BranchLocation> locations) {
    showBranchSelectorDialog(
      context,
      locations: locations,
      branchTitle: _branding.branchTitle,
      onBranchSelected: () {
        if (mounted) widget.onLoginSuccess();
      },
    );
  }

  void _showForgotPasswordDialog() {
    showForgotPasswordDialog(
      context,
      initialEmail: _emailController.text.trim(),
    );
  }

  void _showRegisterDialog() {
    showRegisterTenantSheet(
      context,
      onRegistered: (user) {
        if (mounted) {
          if (user.locations.length > 1) {
            _showBranchSelectorDialog(user.locations);
          } else {
            widget.onLoginSuccess();
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return VeloraAnimatedLoginView(
      branding: _branding,
      emailController: _emailController,
      passwordController: _passwordController,
      obscurePassword: _obscurePassword,
      rememberMe: _rememberMe,
      errorMessage: _errorMessage,
      isLoading: _isLoading,
      isGoogleLoading: _isGoogleLoading,
      isLoginSuccess: _isLoginSuccess,
      greetingText: _greetingText(),
      onToggleObscurePassword: () => setState(() => _obscurePassword = !_obscurePassword),
      onToggleRememberMe: (v) => setState(() => _rememberMe = v),
      onLogin: _handleLogin,
      onGoogleLogin: _handleGoogleLogin,
      onForgotPassword: _showForgotPasswordDialog,
      onRegister: _showRegisterDialog,
    );
  }
}
