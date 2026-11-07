import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/config/app_config.dart';
import '../../core/design/components.dart';
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
    final text = Theme.of(context).textTheme;
    final state = context.watch<AuthCubit>().state;
    final user = state is Authenticated ? state.user : null;
    final branch = state is Authenticated ? state.activeLocationName : null;
    final isWide = MediaQuery.sizeOf(context).width >= 600;
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return Scaffold(
      appBar: (!isWide || canPop) ? AppBar(title: const Text('Pengaturan')) : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(Gap.lg),
            children: [
              if (user != null)
                AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        child: Text(user.name.isEmpty ? '?' : user.name[0].toUpperCase()),
                      ),
                      const SizedBox(width: Gap.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user.name,
                                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (user.isOwnerOrAdmin
                                            ? Theme.of(context).colorScheme.primary
                                            : p.secondary)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    user.roleDisplayName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: user.isOwnerOrAdmin
                                        ? Theme.of(context).colorScheme.primary
                                        : p.secondary,
                                    ),
                                  ),
                                ),
                                if (_subscription != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: p.info.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _subscription!.planName.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: p.info,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (user.email.isNotEmpty)
                              Text(user.email, style: text.bodySmall?.copyWith(color: p.textSecondary)),
                            if (user.tenantName.isNotEmpty)
                              Text(user.tenantName, style: text.bodySmall?.copyWith(color: p.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: Gap.xl),
              const SectionHeader(title: 'Operasional'),
              const SizedBox(height: Gap.sm),
              if (user != null && branch != null)
                user.can(AppPermission.changeBranch) && user.locations.length > 1
                    ? SettingsTile(
                        icon: Icons.storefront_outlined,
                        title: 'Cabang aktif',
                        subtitle: branch,
                        onTap: () => _pickBranch(user),
                      )
                    : SettingsTile(
                        icon: Icons.storefront_outlined,
                        title: 'Cabang bertugas',
                        subtitle: branch,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: p.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline, size: 12, color: p.textTertiary),
                              const SizedBox(width: 4),
                              Text(
                                user.can(AppPermission.changeBranch)
                                    ? '1 Cabang'
                                    : 'Terkunci (${user.roleDisplayName})',
                                style: text.bodySmall?.copyWith(color: p.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
              SettingsTile(
                icon: Icons.print_outlined,
                title: 'Printer',
                subtitle: 'Atur printer struk dan tiket dapur',
                onTap: () => PrinterSettingsModal.show(context),
              ),
              const SizedBox(height: Gap.xl),
              const SectionHeader(title: 'Keamanan'),
              const SizedBox(height: Gap.sm),
              SettingsTile(
                icon: Icons.pin_outlined,
                title: _hasPin == true ? 'Ubah PIN cepat' : 'Atur PIN cepat',
                subtitle: 'PIN 4 digit, hanya tersimpan di perangkat ini',
                onTap: _hasPin == null ? null : _editPin,
              ),
              SettingsTile(
                icon: Icons.devices_outlined,
                title: 'Sesi & Perangkat Aktif',
                subtitle: 'Lihat dan kelola perangkat yang sedang login',
                onTap: () => _manageSessions(context),
              ),
              const SizedBox(height: Gap.xl),
              const SectionHeader(title: 'Langganan & Lisensi Toko'),
              const SizedBox(height: Gap.sm),
              SettingsTile(
                icon: Icons.workspace_premium_outlined,
                title: _subscription?.planName ?? 'Paket Langganan',
                subtitle: _subscription != null
                    ? 'Status: ${_subscription!.statusDisplayName}${_subscription!.daysRemaining != null ? " • Sisa ${_subscription!.daysRemaining} hari" : ""}'
                    : (_loadingSubscription ? 'Memuat status lisensi...' : 'Belum ada data lisensi'),
                trailing: _subscription != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (_subscription!.isActive ? p.success : p.danger).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _subscription!.statusDisplayName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _subscription!.isActive ? p.success : p.danger,
                          ),
                        ),
                      )
                    : (_loadingSubscription
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: p.primary),
                          )
                        : null),
                onTap: () => _manageSubscription(context),
              ),
              const SizedBox(height: Gap.xl),
              const SectionHeader(title: 'Aplikasi & Pembaruan'),
              const SizedBox(height: Gap.sm),
              SettingsTile(
                icon: Icons.system_update_rounded,
                title: 'Periksa Pembaruan di Play Store',
                subtitle: _versionInfo != null
                    ? '${AppConfig.instance.appName} v${_versionInfo!.versionName} (Build ${_versionInfo!.versionCode})'
                    : 'Memeriksa status versi...',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: p.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 12, color: p.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Play Store',
                        style: text.bodySmall?.copyWith(color: p.primary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                onTap: () => AppUpdateService.instance.checkAndPrompt(context, notifyIfUpToDate: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
