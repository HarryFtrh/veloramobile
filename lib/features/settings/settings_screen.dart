import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/design/components.dart';
import '../../core/design/tokens.dart';
import '../auth/auth_service.dart';
import '../auth/cubit/auth_cubit.dart';
import '../auth/cubit/auth_state.dart';
import '../shared_pos/printer_settings_modal.dart';
import '../subscription/subscription_model.dart';
import '../subscription/subscription_service.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/audio_helper.dart';
import 'settings_service.dart';

/// Pengaturan akun: profil, cabang aktif, printer, dan PIN cepat kasir.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool? _hasPin;
  TenantSubscription? _subscription;
  bool _loadingSubscription = true;

  @override
  void initState() {
    super.initState();
    _loadPin();
    _loadSubscription();
  }

  Future<void> _loadPin() async {
    final has = await AuthService.instance.hasQuickPin();
    if (mounted) setState(() => _hasPin = has);
  }

  Future<void> _loadSubscription({bool forceRefresh = false}) async {
    try {
      final sub = await SubscriptionService.instance.getSubscription(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _subscription = sub;
          _loadingSubscription = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSubscription = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickBranch(AuthUser user) async {
    final activeLocId = SessionStorage.instance.getLocationId();
    final isMobile = context.isMobile;
    final p = context.palette;

    final chosen = await showModalBottomSheet<BranchLocation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 540,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.75,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: p.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: p.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.storefront_rounded, color: p.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pilih Cabang Operasional',
                                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tentukan cabang kasir yang aktif bertugas',
                                style: TextStyle(fontSize: 12, color: p.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, size: 20, color: p.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Divider(height: 1, color: p.line),

                  // Branch list
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: user.locations.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final loc = user.locations[i];
                        final isActive = loc.id == activeLocId;
                        return Material(
                          color: isActive ? p.primary.withValues(alpha: 0.08) : p.canvas,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isActive ? p.primary : p.line,
                              width: isActive ? 1.8 : 1.0,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              AudioHelper.tapFeedback();
                              Navigator.pop(ctx, loc);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isActive ? p.primary : p.surfaceMuted,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.store_rounded,
                                      color: isActive ? Colors.white : p.textSecondary,
                                      size: 20,
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
                                                loc.name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 14,
                                                  color: isActive ? p.primary : p.textPrimary,
                                                ),
                                              ),
                                            ),
                                            if (loc.isMain) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: p.warning.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: p.warning.withValues(alpha: 0.4)),
                                                ),
                                                child: Text(
                                                  'UTAMA',
                                                  style: TextStyle(
                                                    color: p.warning,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          isActive ? 'Cabang kasir sedang aktif' : 'Ketuk untuk beralih ke cabang ini',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isActive ? p.primary : p.textSecondary,
                                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: p.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_rounded, color: Colors.white, size: 14),
                                          SizedBox(width: 4),
                                          Text(
                                            'AKTIF',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Icon(Icons.chevron_right_rounded, color: p.textTertiary, size: 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    if (chosen == null || !mounted) return;
    await context.read<AuthCubit>().selectBranch(user: user, location: chosen);
  }

  Future<void> _editPin() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _PinDialog(isUpdate: _hasPin == true),
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
        child: const _SessionsModal(),
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
        child: _SubscriptionModal(
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
                                        : const Color(0xFF7A431D))
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
                                      : const Color(0xFF7A431D),
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
                ? _Tile(
                    icon: Icons.storefront_outlined,
                    title: 'Cabang aktif',
                    subtitle: branch,
                    onTap: () => _pickBranch(user),
                  )
                : _Tile(
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
                            user.can(AppPermission.changeBranch) ? '1 Cabang' : 'Terkunci (${user.roleDisplayName})',
                            style: text.bodySmall?.copyWith(color: p.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
          _Tile(
            icon: Icons.print_outlined,
            title: 'Printer',
            subtitle: 'Atur printer struk dan tiket dapur',
            onTap: () => PrinterSettingsModal.show(context),
          ),
          const SizedBox(height: Gap.xl),
          const SectionHeader(title: 'Keamanan'),
          const SizedBox(height: Gap.sm),
          _Tile(
            icon: Icons.pin_outlined,
            title: _hasPin == true ? 'Ubah PIN cepat' : 'Atur PIN cepat',
            subtitle: 'PIN 4 digit, hanya tersimpan di perangkat ini',
            onTap: _hasPin == null ? null : _editPin,
          ),
          _Tile(
            icon: Icons.devices_outlined,
            title: 'Sesi & Perangkat Aktif',
            subtitle: 'Lihat dan kelola perangkat yang sedang login',
            onTap: () => _manageSessions(context),
          ),
          const SizedBox(height: Gap.xl),
          const SectionHeader(title: 'Langganan & Lisensi Toko'),
          const SizedBox(height: Gap.sm),
          _Tile(
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
        ],
      ),
    ),
  ),
);
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.subtitle, this.onTap, this.trailing});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.sm),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: Gap.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: text.bodySmall?.copyWith(color: p.textSecondary)),
                ],
              ),
            ),
            trailing ?? (onTap != null ? Icon(Icons.chevron_right, color: p.textTertiary) : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({required this.isUpdate});
  final bool isUpdate;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  static const _length = 4;
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_pin.text.length != _length) {
      setState(() => _error = 'PIN harus $_length digit');
      return;
    }
    if (_pin.text != _confirm.text) {
      setState(() => _error = 'Konfirmasi PIN tidak sama');
      return;
    }
    await AuthService.instance.setQuickPin(_pin.text);
    if (mounted) Navigator.pop(context, true);
  }

  Widget _field(TextEditingController c, String label) => TextField(
        controller: c,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: _length,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: label, counterText: ''),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.palette.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.lock_outline_rounded, color: context.palette.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.isUpdate ? 'Ubah PIN Cepat' : 'Atur PIN Cepat',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.dialogMaxWidth),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_pin, 'PIN baru'),
              const SizedBox(height: Gap.md),
              _field(_confirm, 'Ulangi PIN'),
              if (_error != null) ...[
                const SizedBox(height: Gap.sm),
                Text(_error!, style: TextStyle(color: context.palette.danger, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
        FilledButton(onPressed: _save, child: const Text('Simpan PIN')),
      ],
    );
  }
}

class _SessionsModal extends StatefulWidget {
  const _SessionsModal();

  @override
  State<_SessionsModal> createState() => _SessionsModalState();
}

class _SessionsModalState extends State<_SessionsModal> {
  bool _loading = true;
  String? _error;
  List<ActiveSession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await SettingsService.instance.sessions();
      if (mounted) setState(() => _sessions = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _revoke(ActiveSession s) async {
    try {
      await SettingsService.instance.revoke(s.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sesi di "${s.deviceName}" berhasil dicabut')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mencabut sesi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sesi & Perangkat Aktif', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (_error != null)
              Center(child: Text(_error!, style: TextStyle(color: p.danger)))
            else if (_sessions.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Tidak ada sesi perangkat lain yang aktif')))
            else
              for (final s in _sessions)
                ListTile(
                  leading: Icon(s.isCurrent ? Icons.phone_android_rounded : Icons.laptop_rounded, color: s.isCurrent ? p.primary : p.textSecondary),
                  title: Row(
                    children: [
                      Text(s.deviceName, style: const TextStyle(fontWeight: FontWeight.w700)),
                      if (s.isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: p.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text('Perangkat Ini', style: TextStyle(fontSize: 10, color: p.primary, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    s.lastUsedAt != null ? 'Terakhir aktif: ${s.lastUsedAt!.day}/${s.lastUsedAt!.month}/${s.lastUsedAt!.year} ${s.lastUsedAt!.hour}:${s.lastUsedAt!.minute.toString().padLeft(2, '0')}' : 'Sesi aktif',
                    style: TextStyle(fontSize: 11, color: p.textSecondary),
                  ),
                  trailing: s.isCurrent
                      ? null
                      : IconButton(
                          icon: Icon(Icons.logout_rounded, color: p.danger, size: 20),
                          tooltip: 'Cabut sesi',
                          onPressed: () => _revoke(s),
                        ),
                ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionModal extends StatefulWidget {
  const _SubscriptionModal({required this.subscription, required this.onRefresh});

  final TenantSubscription subscription;
  final Future<void> Function() onRefresh;

  @override
  State<_SubscriptionModal> createState() => _SubscriptionModalState();
}

class _SubscriptionModalState extends State<_SubscriptionModal> {
  bool _refreshing = false;

  Future<void> _handleRefresh() async {
    setState(() => _refreshing = true);
    try {
      await widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status langganan berhasil diperbarui')),
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.subscription;
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Paket & Lisensi Toko',
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: _refreshing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                    tooltip: 'Perbarui Status',
                    onPressed: _refreshing ? null : _handleRefresh,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Hero Plan Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: p.canvas,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.line, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.workspace_premium_rounded, color: p.warning, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              sub.planName,
                              style: TextStyle(
                                color: p.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (sub.isActive ? p.success : p.danger).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (sub.isActive ? p.success : p.danger).withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            sub.statusDisplayName.toUpperCase(),
                            style: TextStyle(
                              color: sub.isActive ? p.success : p.danger,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Siklus: ${sub.billingCycleDisplayName}',
                      style: TextStyle(color: p.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sub.validUntil != null
                          ? 'Masa Aktif s/d: ${sub.validUntil!.day}/${sub.validUntil!.month}/${sub.validUntil!.year} (${sub.daysRemaining ?? 0} hari lagi)'
                          : 'Masa Aktif: Berlangganan Aktif',
                      style: TextStyle(
                        color: sub.isNearExpiry ? p.warning : p.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // Quota Cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: p.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: p.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.storefront_outlined, size: 20, color: p.primary),
                          const SizedBox(height: 6),
                          Text('Batas Cabang', style: TextStyle(fontSize: 11, color: p.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            sub.maxLocations == 0 ? 'Tanpa Batas' : '${sub.maxLocations} Cabang',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: p.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: p.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.point_of_sale_rounded, size: 20, color: p.primary),
                          const SizedBox(height: 6),
                          Text('Batas Kasir POS', style: TextStyle(fontSize: 11, color: p.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            sub.maxDevices == 0 ? 'Tanpa Batas' : '${sub.maxDevices} Terminal',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              if (sub.features.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Fitur Termasuk',
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final f in sub.features)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: p.surfaceMuted,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: p.line),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 14, color: p.success),
                            const SizedBox(width: 6),
                            Text(f, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: p.textPrimary)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: p.info.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: p.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Untuk upgrade paket, perpanjangan lisensi, atau penambahan kuota cabang, silakan akses Web Dashboard Backoffice Velora.',
                        style: TextStyle(fontSize: 12, color: p.textSecondary, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

