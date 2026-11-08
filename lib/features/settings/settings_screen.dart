import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/app_config.dart';
import '../../core/design/tokens.dart';
import '../../core/services/app_update_service.dart';
import '../../core/storage/session_storage.dart';
import '../auth/auth_service.dart';
import '../auth/cubit/auth_cubit.dart';
import '../auth/cubit/auth_state.dart';
import 'widgets/active_sessions_modal.dart';
import 'widgets/branch_picker_sheet.dart';
import 'widgets/settings_pin_dialog.dart';
import 'widgets/settings_tile.dart';

export 'widgets/active_sessions_modal.dart';
export 'widgets/branch_picker_sheet.dart';
export 'widgets/settings_pin_dialog.dart';
export 'widgets/settings_tile.dart';

/// Pengaturan Akun, Keamanan Kasir, dan Konfigurasi Toko Velora
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

  Future<void> _pickBranch(AuthUser user) async {
    final chosen = await BranchPickerSheet.show(context, user);
    if (chosen == null || !mounted) return;
    await context.read<AuthCubit>().selectBranch(user: user, location: chosen);
    setState(() {});
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Keluar Akun?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
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
              elevation: 0,
            ),
            child: const Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.w800)),
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
    final primary = Theme.of(context).colorScheme.primary;
    final state = context.watch<AuthCubit>().state;
    final user = state is Authenticated ? state.user : null;
    final branch = state is Authenticated ? state.activeLocationName : SessionStorage.instance.getLocationName();
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Pengaturan Akun',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            children: [
              // 1. Profil Pengguna Card (Hero)
              if (user != null) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 14,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primary, primary.withValues(alpha: 0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: primary.withValues(alpha: 0.2)),
                                  ),
                                  child: Text(
                                    user.roleDisplayName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (user.email.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(user.email, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ],
                            if (user.tenantName.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${user.tenantName} • ${branch ?? "Outlet Utama"}',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
              ],

              // 2. Section: Cabang & Outlet
              if (user != null && branch != null) ...[
                SettingsGroup(
                  title: 'Cabang & Outlet',
                  headerIcon: Icons.storefront_rounded,
                  items: [
                    SettingsTile(
                      icon: Icons.store_rounded,
                      iconColor: const Color(0xFFD97706),
                      iconBgColor: const Color(0xFFFEF3C7),
                      title: 'Cabang Bertugas',
                      subtitle: branch,
                      trailing: user.can(AppPermission.changeBranch) && user.locations.length > 1
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Ganti',
                                style: TextStyle(color: primary, fontWeight: FontWeight.w800, fontSize: 11),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.lock_outline_rounded, size: 12, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 4),
                                  Text(
                                    user.can(AppPermission.changeBranch) ? '1 Cabang' : 'Terkunci (${user.roleDisplayName})',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                      onTap: user.can(AppPermission.changeBranch) && user.locations.length > 1 ? () => _pickBranch(user) : null,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // 3. Section: Keamanan & Akses Kasir
              SettingsGroup(
                title: 'Keamanan & Akses Kasir',
                headerIcon: Icons.security_rounded,
                items: [
                  SettingsTile(
                    icon: Icons.pin_rounded,
                    iconColor: const Color(0xFF059669),
                    iconBgColor: const Color(0xFFD1FAE5),
                    title: _hasPin == true ? 'Ubah PIN Cepat Kasir' : 'Atur PIN Cepat Kasir',
                    subtitle: 'Kunci layar POS & otorisasi kasir 4 digit',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (_hasPin == true ? const Color(0xFF059669) : const Color(0xFFD97706)).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _hasPin == true ? 'AKTIF' : 'BELUM DIATUR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _hasPin == true ? const Color(0xFF059669) : const Color(0xFFD97706),
                        ),
                      ),
                    ),
                    onTap: _hasPin == null ? null : _editPin,
                  ),
                  SettingsTile(
                    icon: Icons.devices_rounded,
                    iconColor: const Color(0xFF7C3AED),
                    iconBgColor: const Color(0xFFEDE9FE),
                    title: 'Sesi & Perangkat Aktif',
                    subtitle: 'Pantau terminal kasir yang sedang login',
                    onTap: () => _manageSessions(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 4. Section: Sistem & Informasi Versi
              SettingsGroup(
                title: 'Sistem & Pembaruan',
                headerIcon: Icons.info_outline_rounded,
                items: [
                  SettingsTile(
                    icon: Icons.system_update_rounded,
                    iconColor: const Color(0xFF0284C7),
                    iconBgColor: const Color(0xFFE0F2FE),
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
              const SizedBox(height: 26),

              // 5. Tombol Logout
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _confirmLogout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text('Keluar dari Akun Kasir', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
