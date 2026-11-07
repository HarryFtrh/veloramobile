import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/app_config.dart';
import '../../core/design/tokens.dart';
import '../../core/services/app_update_service.dart';
import '../auth/auth_service.dart';
import '../auth/cubit/auth_cubit.dart';
import '../auth/cubit/auth_state.dart';
import '../shared_pos/printer_settings_modal.dart';
import '../subscription/subscription_model.dart';
import '../subscription/subscription_service.dart';
import 'widgets/active_sessions_modal.dart';
import 'widgets/branch_picker_sheet.dart';
import 'widgets/settings_pin_dialog.dart';
import 'widgets/settings_tile.dart';
import 'widgets/tenant_subscription_modal.dart';

export 'widgets/active_sessions_modal.dart';
export 'widgets/branch_picker_sheet.dart';
export 'widgets/settings_pin_dialog.dart';
export 'widgets/settings_tile.dart';
export 'widgets/tenant_subscription_modal.dart';

/// Pengaturan akun: profil, cabang aktif, printer, dan PIN cepat kasir.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool? _hasPin;
  TenantSubscription? _subscription;
  bool _loadingSubscription = false;
  AppVersionInfo? _versionInfo;

  @override
  void initState() {
    super.initState();
    _loadPin();
    _loadSubscription();
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

  Future<void> _loadSubscription({bool forceRefresh = false}) async {
    setState(() => _loadingSubscription = true);
    try {
      final sub = await SubscriptionService.instance.getSubscription(forceRefresh: forceRefresh);
      if (mounted) setState(() => _subscription = sub);
    } catch (e) {
      debugPrint('[SettingsScreen] Gagal memuat status langganan: $e');
    } finally {
      if (mounted) setState(() => _loadingSubscription = false);
    }
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
  }

  Future<void> _editPin() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => SettingsPinDialog(isUpdate: _hasPin == true),
    );
    if (changed == true) {
      await _loadPin();
      _toast('PIN disimpan di perangkat ini');
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

  Future<void> _manageSubscription(BuildContext context) async {
    if (_subscription == null) return;
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
        child: TenantSubscriptionModal(
          subscription: _subscription!,
          onRefresh: () => _loadSubscription(forceRefresh: true),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primary = Theme.of(context).colorScheme.primary;
    final state = context.watch<AuthCubit>().state;
    final user = state is Authenticated ? state.user : null;
    final branch = state is Authenticated ? state.activeLocationName : null;
    final width = MediaQuery.sizeOf(context).width;
    final isTabletLandscape = width >= 860;
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return Scaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(
        title: Text(
          'Pengaturan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: p.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        elevation: 0,
        backgroundColor: p.canvas,
        leading: canPop
            ? IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: p.textPrimary),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: p.textSecondary),
            tooltip: 'Segarkan',
            onPressed: () {
              _loadPin();
              _loadSubscription(forceRefresh: true);
              _loadVersionInfo();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTabletLandscape ? 980 : 680),
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isTabletLandscape ? 24 : 16,
              vertical: 16,
            ),
            children: [
              // User Profile Banner Card
              if (user != null) ...[
                _buildProfileCard(context, user, p, primary),
                const SizedBox(height: 24),
              ],

              // Tablet 2-column or Mobile stacked layout
              if (isTabletLandscape)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column
                    Expanded(
                      child: Column(
                        children: [
                          _buildOperationalGroup(context, user, branch, p, primary),
                          const SizedBox(height: 20),
                          _buildSecurityGroup(context, p, primary),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Right Column
                    Expanded(
                      child: Column(
                        children: [
                          _buildSubscriptionGroup(context, p, primary),
                          const SizedBox(height: 20),
                          _buildAppUpdateGroup(context, p, primary),
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                _buildOperationalGroup(context, user, branch, p, primary),
                const SizedBox(height: 20),
                _buildSecurityGroup(context, p, primary),
                const SizedBox(height: 20),
                _buildSubscriptionGroup(context, p, primary),
                const SizedBox(height: 20),
                _buildAppUpdateGroup(context, p, primary),
              ],
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AuthUser user, AppPalette p, Color primary) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, primary.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: p.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (user.isOwnerOrAdmin ? primary : p.secondary).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (user.isOwnerOrAdmin ? primary : p.secondary).withValues(alpha: 0.2),
                        ),
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
                    if (_subscription != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: p.tertiary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: p.tertiary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium_rounded, size: 12, color: p.tertiary),
                            const SizedBox(width: 4),
                            Text(
                              _subscription!.planName.toUpperCase(),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: p.tertiary),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (user.email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(user.email, style: TextStyle(fontSize: 12, color: p.textSecondary)),
                ],
                if (user.tenantName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.tenantName,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.textTertiary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalGroup(BuildContext context, AuthUser? user, String? branch, AppPalette p, Color primary) {
    return SettingsGroup(
      title: 'Operasional Kasir',
      items: [
        if (user != null && branch != null)
          user.can(AppPermission.changeBranch) && user.locations.length > 1
              ? SettingsTile(
                  icon: Icons.storefront_rounded,
                  iconColor: const Color(0xFFD97706),
                  title: 'Cabang Aktif',
                  subtitle: branch,
                  onTap: () => _pickBranch(user),
                )
              : SettingsTile(
                  icon: Icons.storefront_rounded,
                  iconColor: const Color(0xFFD97706),
                  title: 'Cabang Bertugas',
                  subtitle: branch,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: p.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 12, color: p.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          user.can(AppPermission.changeBranch)
                              ? '1 Cabang'
                              : 'Terkunci (${user.roleDisplayName})',
                          style: TextStyle(color: p.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
        SettingsTile(
          icon: Icons.print_rounded,
          iconColor: const Color(0xFF4F46E5),
          title: 'Printer Thermal',
          subtitle: 'Konfigurasi printer struk, lebar kertas & laci kas',
          onTap: () => PrinterSettingsModal.show(context),
        ),
      ],
    );
  }

  Widget _buildSecurityGroup(BuildContext context, AppPalette p, Color primary) {
    return SettingsGroup(
      title: 'Keamanan & Akses',
      items: [
        SettingsTile(
          icon: Icons.pin_rounded,
          iconColor: const Color(0xFF059669),
          title: _hasPin == true ? 'Ubah PIN Cepat Kasir' : 'Atur PIN Cepat Kasir',
          subtitle: 'PIN 4 digit kasir, hanya tersimpan di perangkat ini',
          onTap: _hasPin == null ? null : _editPin,
        ),
        SettingsTile(
          icon: Icons.devices_rounded,
          iconColor: const Color(0xFF7C3AED),
          title: 'Sesi & Perangkat Aktif',
          subtitle: 'Pantau dan kelola perangkat POS yang sedang login',
          onTap: () => _manageSessions(context),
        ),
      ],
    );
  }

  Widget _buildSubscriptionGroup(BuildContext context, AppPalette p, Color primary) {
    return SettingsGroup(
      title: 'Langganan & Lisensi Outlet',
      items: [
        SettingsTile(
          icon: Icons.workspace_premium_rounded,
          iconColor: const Color(0xFFD97706),
          title: _subscription?.planName ?? 'Paket Langganan',
          subtitle: _subscription != null
              ? 'Status: ${_subscription!.statusDisplayName}${_subscription!.daysRemaining != null ? " • Sisa ${_subscription!.daysRemaining} hari" : ""}'
              : (_loadingSubscription ? 'Memuat status lisensi...' : 'Belum ada data lisensi'),
          trailing: _subscription != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (_subscription!.isActive ? const Color(0xFF059669) : p.danger).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (_subscription!.isActive ? const Color(0xFF059669) : p.danger).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    _subscription!.statusDisplayName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _subscription!.isActive ? const Color(0xFF059669) : p.danger,
                    ),
                  ),
                )
              : (_loadingSubscription
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: primary),
                    )
                  : null),
          onTap: () => _manageSubscription(context),
        ),
      ],
    );
  }

  Widget _buildAppUpdateGroup(BuildContext context, AppPalette p, Color primary) {
    return SettingsGroup(
      title: 'Aplikasi & Pembaruan',
      items: [
        SettingsTile(
          icon: Icons.system_update_rounded,
          iconColor: const Color(0xFF0284C7),
          title: 'Versi Aplikasi & Play Store',
          subtitle: _versionInfo != null
              ? '${AppConfig.instance.appName} v${_versionInfo!.versionName} (Build ${_versionInfo!.versionCode})'
              : 'Memeriksa status versi...',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primary.withValues(alpha: 0.2)),
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
    );
  }
}
