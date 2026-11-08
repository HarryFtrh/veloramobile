import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/app_config.dart';
import '../../core/design/tokens.dart';
import '../../core/services/app_update_service.dart';
import '../auth/auth_service.dart';
import '../auth/cubit/auth_cubit.dart';
import '../auth/cubit/auth_state.dart';
import 'widgets/active_sessions_modal.dart';
import 'widgets/settings_pin_dialog.dart';
import 'widgets/settings_tile.dart';

export 'widgets/active_sessions_modal.dart';
export 'widgets/settings_pin_dialog.dart';
export 'widgets/settings_tile.dart';

/// Pengaturan Murni Akun Kasir: Profil, PIN Otorisasi 4-Digit, dan Sesi Login
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool? _hasPin;
  AppVersionInfo? _versionInfo;

  @override
  void initState() {
    super.initState();
    _loadPin();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    final v = await AppUpdateService.instance.getAppVersion();
    if (mounted) setState(() => _versionInfo = v);
  }

  Future<void> _loadPin() async {
    final has = await AuthService.instance.hasQuickPin();
    if (mounted) setState(() => _hasPin = has);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _editPin() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => SettingsPinDialog(isUpdate: _hasPin == true),
    );
    if (changed == true) {
      await _loadPin();
      _toast('PIN kasir berhasil disimpan di perangkat ini');
    }
  }

  Future<void> _manageSessions(BuildContext context) async {
    final isMobile = context.isMobile;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 540,
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
        ),
        child: const ActiveSessionsModal(),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Keluar Akun Kasir?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: const Text(
          'Anda harus login kembali dengan akun terdaftar untuk mengakses kasir dan data outlet ini.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      await context.read<AuthCubit>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primary = Theme.of(context).colorScheme.primary;
    final state = context.watch<AuthCubit>().state;
    final user = state is Authenticated ? state.user : null;
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return Scaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(
        title: Text(
          'Pengaturan Akun & Keamanan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: p.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: p.canvas,
        elevation: 0,
        leading: canPop
            ? IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: p.textPrimary),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            children: [
              // 1. Profil Pengguna Card
              if (user != null) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: p.line),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primary, primary.withValues(alpha: 0.75)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user.name,
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (user.isOwnerOrAdmin ? primary : p.secondary).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    user.roleDisplayName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: user.isOwnerOrAdmin ? primary : p.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (user.email.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(user.email, style: TextStyle(fontSize: 12, color: p.textSecondary)),
                            ],
                            if (user.tenantName.isNotEmpty) ...[
                              const SizedBox(height: 1),
                              Text(user.tenantName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.textTertiary)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
              ],

              // 2. Section: Keamanan Kasir
              SettingsGroup(
                title: 'Keamanan & Akses Kasir',
                items: [
                  SettingsTile(
                    icon: Icons.pin_rounded,
                    iconColor: const Color(0xFF059669),
                    title: _hasPin == true ? 'Ubah PIN Cepat Kasir' : 'Atur PIN Cepat Kasir',
                    subtitle: 'Kunci layar POS & otorisasi kasir 4 digit',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (_hasPin == true ? const Color(0xFF059669) : Colors.amber.shade800).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _hasPin == true ? 'AKTIF' : 'BELUM DIATUR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _hasPin == true ? const Color(0xFF059669) : Colors.amber.shade800,
                        ),
                      ),
                    ),
                    onTap: _hasPin == null ? null : _editPin,
                  ),
                  SettingsTile(
                    icon: Icons.devices_rounded,
                    iconColor: const Color(0xFF7C3AED),
                    title: 'Sesi & Perangkat Aktif',
                    subtitle: 'Pantau terminal kasir yang sedang login',
                    onTap: () => _manageSessions(context),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // 3. Section: Aplikasi & Pembaruan
              SettingsGroup(
                title: 'Aplikasi & Informasi Rilis',
                items: [
                  SettingsTile(
                    icon: Icons.system_update_rounded,
                    iconColor: const Color(0xFF0284C7),
                    title: 'Versi Aplikasi',
                    subtitle: _versionInfo != null
                        ? '${AppConfig.instance.appName} v${_versionInfo!.versionName} (Build ${_versionInfo!.versionCode})'
                        : 'Memeriksa status versi...',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 12, color: primary),
                          const SizedBox(width: 4),
                          Text(
                            'Play Store',
                            style: TextStyle(color: primary, fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    onTap: () => AppUpdateService.instance.checkAndPrompt(context, notifyIfUpToDate: true),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 4. Logout Action
              OutlinedButton.icon(
                onPressed: _confirmLogout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  backgroundColor: p.surface,
                ),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Keluar dari Akun Kasir', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
