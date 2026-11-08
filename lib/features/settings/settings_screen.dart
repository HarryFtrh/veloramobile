import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/app_config.dart';
import '../../core/design/tokens.dart';
import '../../core/services/app_update_service.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/audio_helper.dart';
import '../auth/auth_service.dart';
import '../auth/cubit/auth_cubit.dart';
import '../auth/cubit/auth_state.dart';
import '../shared_pos/pos_checkout_service.dart';
import '../shared_pos/printer_settings_modal.dart';
import '../shared_pos/receipt_printer_service.dart';
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

/// Pengaturan Enterprise: Profil, Cabang, Printer Thermal, Keamanan PIN, dan Lisensi
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedTabIndex = 0;
  bool? _hasPin;
  TenantSubscription? _subscription;
  bool _loadingSubscription = false;
  AppVersionInfo? _versionInfo;
  bool _isTestingPrinter = false;

  final List<Map<String, dynamic>> _tabs = [
    {
      'icon': Icons.storefront_rounded,
      'color': Color(0xFFD97706),
      'title': 'Profil & Cabang',
      'sub': 'Identitas outlet & lokasi',
    },
    {
      'icon': Icons.print_rounded,
      'color': Color(0xFF4F46E5),
      'title': 'Printer & Struk',
      'sub': 'Bluetooth, LAN & laci kas',
    },
    {
      'icon': Icons.security_rounded,
      'color': Color(0xFF059669),
      'title': 'Keamanan & PIN',
      'sub': 'PIN kasir & sesi aktif',
    },
    {
      'icon': Icons.workspace_premium_rounded,
      'color': Color(0xFFEA580C),
      'title': 'Paket & Lisensi',
      'sub': 'Langganan & fitur aktif',
    },
    {
      'icon': Icons.info_outline_rounded,
      'color': Color(0xFF0284C7),
      'title': 'Sistem & Info',
      'sub': 'Versi aplikasi & pembaruan',
    },
  ];

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

  Future<void> _quickTestPrint() async {
    AudioHelper.actionFeedback();
    setState(() => _isTestingPrinter = true);

    final is80mm = SessionStorage.instance.isPrinter80mm();
    final testData = ReceiptData(
      storeName: SessionStorage.instance.getTenantName() ?? 'VELORA POS',
      storeAddress: SessionStorage.instance.getStoreAddress() ?? (SessionStorage.instance.getLocationName() ?? 'Outlet Kasir'),
      storePhone: SessionStorage.instance.getStorePhone() ?? '',
      invoiceNumber: 'TEST-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      cashierName: SessionStorage.instance.getUserName() ?? 'Kasir',
      timestamp: DateTime.now(),
      items: [
        PosCartItem(productId: 'T1', name: 'Tes Cetak Printer Thermal', price: 15000, quantity: 1),
        PosCartItem(productId: 'T2', name: 'Uji Potong Kertas Otomatis', price: 25000, quantity: 1),
      ],
      subtotal: 40000,
      tax: 4000,
      grandTotal: 44000,
      paidAmount: 50000,
      changeAmount: 6000,
      paymentMethod: 'CASH',
      qrData: 'https://velora.co.id/verify-test',
    );

    final success = await ReceiptPrinterService.instance.printReceipt(testData, is80mm: is80mm);
    AudioHelper.successFeedback();

    if (mounted) {
      setState(() => _isTestingPrinter = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(success ? Icons.check_circle_rounded : Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  success ? 'Perintah cetak uji coba berhasil dikirim!' : 'Gagal mengirim data ke printer.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: success ? const Color(0xFF10B981) : Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
    final branch = state is Authenticated ? state.activeLocationName : null;
    final width = MediaQuery.sizeOf(context).width;
    final isTabletLandscape = width >= 800;
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    if (!isTabletLandscape) {
      // Mobile Single-Column Layout
      return Scaffold(
        backgroundColor: p.canvas,
        appBar: AppBar(
          title: Text(
            'Pengaturan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.textPrimary),
          ),
          backgroundColor: p.canvas,
          elevation: 0,
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
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            if (user != null) ...[
              _buildProfileSummaryCard(user, p, primary),
              const SizedBox(height: 18),
            ],
            _buildOperationalGroup(user, branch, p, primary),
            const SizedBox(height: 18),
            _buildSecurityGroup(p, primary),
            const SizedBox(height: 18),
            _buildSubscriptionGroup(p, primary),
            const SizedBox(height: 18),
            _buildAppUpdateGroup(p, primary),
            const SizedBox(height: 24),
            _buildLogoutButton(p),
            const SizedBox(height: 36),
          ],
        ),
      );
    }

    // World-Class Master-Detail Tablet Split View
    return Scaffold(
      backgroundColor: p.canvas,
      body: Row(
        children: [
          // Left Sidebar (Navigation Master)
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: p.surface,
              border: Border(right: BorderSide(color: p.line)),
            ),
            child: Column(
              children: [
                // Top Sidebar Header
                SafeArea(
                  bottom: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: p.line)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (canPop) ...[
                              IconButton.filledTonal(
                                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                                style: IconButton.styleFrom(
                                  backgroundColor: p.surfaceMuted,
                                  foregroundColor: p.textPrimary,
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () => Navigator.maybePop(context),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                'Pengaturan Sistem',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: p.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.refresh_rounded, size: 20, color: p.textSecondary),
                              tooltip: 'Segarkan',
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                _loadPin();
                                _loadSubscription(forceRefresh: true);
                                _loadVersionInfo();
                              },
                            ),
                          ],
                        ),
                        if (user != null) ...[
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
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
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: p.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      user.tenantName.isNotEmpty ? user.tenantName : (branch ?? 'Outlet Utama'),
                                      style: TextStyle(fontSize: 11, color: p.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Navigation Tabs
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    itemCount: _tabs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (ctx, index) {
                      final item = _tabs[index];
                      final isSelected = _selectedTabIndex == index;
                      final tabColor = item['color'] as Color;

                      return InkWell(
                        onTap: () => setState(() => _selectedTabIndex = index),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? primary.withValues(alpha: 0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? primary.withValues(alpha: 0.25) : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isSelected ? primary : tabColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  item['icon'] as IconData,
                                  color: isSelected ? Colors.white : tabColor,
                                  size: 19,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] as String,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isSelected ? primary : p.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      item['sub'] as String,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isSelected ? primary.withValues(alpha: 0.8) : p.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Logout Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: p.surfaceMuted.withValues(alpha: 0.4),
                    border: Border(top: BorderSide(color: p.line)),
                  ),
                  child: OutlinedButton.icon(
                    onPressed: _confirmLogout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 42),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Keluar Akun Kasir', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),

          // Right Workspace (Detail View)
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: _buildDetailWorkspace(user, branch, p, primary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailWorkspace(AuthUser? user, String? branch, AppPalette p, Color primary) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildProfileAndBranchDetail(user, branch, p, primary);
      case 1:
        return _buildPrinterDetail(p, primary);
      case 2:
        return _buildSecurityDetail(p, primary);
      case 3:
        return _buildSubscriptionDetail(p, primary);
      case 4:
      default:
        return _buildSystemDetail(p, primary);
    }
  }

  // --- TAB DETAIL WORKSPACES ---

  Widget _buildProfileAndBranchDetail(AuthUser? user, String? branch, AppPalette p, Color primary) {
    if (user == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWorkspaceHeader(
          icon: Icons.storefront_rounded,
          color: const Color(0xFFD97706),
          title: 'Profil Toko & Cabang',
          subtitle: 'Kelola informasi outlet dan beralih cabang kasir yang aktif.',
        ),
        const SizedBox(height: 20),

        // Store identity card
        _buildProfileSummaryCard(user, p, primary),
        const SizedBox(height: 20),

        // Branch status card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.location_on_rounded, color: Color(0xFFD97706), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cabang Bertugas Saat Ini', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.textPrimary)),
                          Text(branch ?? 'Cabang Utama', style: TextStyle(fontSize: 12, color: p.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  if (user.can(AppPermission.changeBranch) && user.locations.length > 1)
                    ElevatedButton.icon(
                      onPressed: () => _pickBranch(user),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.sync_alt_rounded, size: 16),
                      label: const Text('Ganti Cabang', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: p.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 13, color: p.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            user.can(AppPermission.changeBranch) ? '1 Cabang Tersedia' : 'Terkunci (${user.roleDisplayName})',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.textSecondary),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: p.line),
              const SizedBox(height: 16),
              Text(
                'Daftar Akses Cabang (${user.locations.length}):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: user.locations.map((loc) {
                  final isCurrent = loc.name.toLowerCase() == (branch ?? '').toLowerCase();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCurrent ? primary.withValues(alpha: 0.1) : p.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isCurrent ? primary : p.line),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isCurrent ? Icons.check_circle_rounded : Icons.store_rounded, size: 16, color: isCurrent ? primary : p.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          loc.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                            color: isCurrent ? primary : p.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrinterDetail(AppPalette p, Color primary) {
    final connType = SessionStorage.instance.getPrinterConnectionType();
    final address = SessionStorage.instance.getPrinterAddress();
    final is80mm = SessionStorage.instance.isPrinter80mm();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWorkspaceHeader(
          icon: Icons.print_rounded,
          color: const Color(0xFF4F46E5),
          title: 'Printer Struk & Hardware Kasir',
          subtitle: 'Konfigurasi printer thermal struk, pesanan dapur, dan laci kas RJ11.',
        ),
        const SizedBox(height: 20),

        // Active printer status
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF4F46E5), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Printer Struk Utama', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.textPrimary)),
                          const SizedBox(height: 2),
                          Text(
                            'Jalur: $connType • ${address != null && address.isNotEmpty ? address : "Belum diatur"}',
                            style: TextStyle(fontSize: 12, color: p.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => PrinterSettingsModal.show(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.settings_rounded, size: 16),
                    label: const Text('Atur Printer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: p.line),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: p.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.aspect_ratio_rounded, size: 18, color: p.textSecondary),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Lebar Kertas', style: TextStyle(fontSize: 10, color: p.textTertiary, fontWeight: FontWeight.w700)),
                              Text(is80mm ? '80 mm (48 Kolom)' : '58 mm (32 Kolom)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: p.textPrimary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: p.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.archive_outlined, size: 18, color: p.textSecondary),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Laci Kasir (RJ11)', style: TextStyle(fontSize: 10, color: p.textTertiary, fontWeight: FontWeight.w700)),
                              Text('Pulse Auto-Kick', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: p.textPrimary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Testing & Actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isTestingPrinter ? null : _quickTestPrint,
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  backgroundColor: p.surface,
                ),
                icon: _isTestingPrinter
                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: primary))
                    : const Icon(Icons.print_rounded, size: 20),
                label: Text(
                  _isTestingPrinter ? 'Mengirim Data...' : 'Cetak Struk Uji Coba',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  AudioHelper.actionFeedback();
                  final ok = await ReceiptPrinterService.instance.openCashDrawer();
                  AudioHelper.successFeedback();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok ? 'Sinyal pulse buka laci kasir terkirim!' : 'Gagal membuka laci kasir.'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.archive_outlined, size: 20),
                label: const Text('Buka Laci Kas (RJ11)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecurityDetail(AppPalette p, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWorkspaceHeader(
          icon: Icons.security_rounded,
          color: const Color(0xFF059669),
          title: 'Keamanan & Hak Akses Kasir',
          subtitle: 'Konfigurasi otorisasi PIN cepat dan pemantauan sesi perangkat.',
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.pin_rounded, color: Color(0xFF059669), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PIN Cepat Kasir (4-Digit)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.textPrimary)),
                          const SizedBox(height: 2),
                          Text(
                            _hasPin == true ? 'Status: PIN Aktif & Terlindungi' : 'Status: Belum Mengatur PIN',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _hasPin == true ? const Color(0xFF059669) : Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _hasPin == null ? null : _editPin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      elevation: 0,
                    ),
                    child: Text(_hasPin == true ? 'Ubah PIN' : 'Atur PIN Sekarang', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'PIN cepat digunakan kasir untuk membuka kunci layar kasir POS saat ditinggalkan dan mengonfirmasi otorisasi diskon / void struk.',
                style: TextStyle(fontSize: 12, color: p.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.devices_rounded, color: Color(0xFF7C3AED), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sesi & Perangkat Aktif', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.textPrimary)),
                      const SizedBox(height: 2),
                      Text('Pantau perangkat POS & kasir yang sedang login', style: TextStyle(fontSize: 12, color: p.textSecondary)),
                    ],
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: () => _manageSessions(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('Kelola Sesi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionDetail(AppPalette p, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWorkspaceHeader(
          icon: Icons.workspace_premium_rounded,
          color: const Color(0xFFEA580C),
          title: 'Langganan & Lisensi Outlet',
          subtitle: 'Status paket lisensi cloud dan masa berlaku operasional toko.',
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, primary.withValues(alpha: 0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _subscription?.planName.toUpperCase() ?? 'VELORA PRO',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _subscription?.statusDisplayName.toUpperCase() ?? 'AKTIF',
                      style: TextStyle(color: primary, fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Paket Layanan Cloud Enterprise',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                _subscription?.daysRemaining != null
                    ? 'Masa aktif tersisa ${_subscription!.daysRemaining} hari ke depan.'
                    : 'Lisensi aktif untuk seluruh terminal kasir outlet ini.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => _manageSubscription(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  elevation: 0,
                ),
                icon: const Icon(Icons.verified_user_rounded, size: 16),
                label: const Text('Kelola Tagihan & Lisensi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSystemDetail(AppPalette p, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWorkspaceHeader(
          icon: Icons.info_outline_rounded,
          color: const Color(0xFF0284C7),
          title: 'Sistem & Pembaruan Aplikasi',
          subtitle: 'Informasi rilis, arsitektur backend, dan ketersediaan versi Play Store.',
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.devices_other_rounded, color: primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppConfig.instance.appName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.textPrimary)),
                        const SizedBox(height: 2),
                        Text(
                          _versionInfo != null
                              ? 'Versi ${_versionInfo!.versionName} (Build ${_versionInfo!.versionCode}) • Produksi'
                              : 'Memeriksa versi aplikasi...',
                          style: TextStyle(fontSize: 12, color: p.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Divider(height: 1, color: p.line),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pembaruan Google Play Store', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ElevatedButton.icon(
                    onPressed: () => AppUpdateService.instance.checkAndPrompt(context, notifyIfUpToDate: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.sync_rounded, size: 16),
                    label: const Text('Periksa Update', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkspaceHeader({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    final p = context.palette;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.textPrimary, letterSpacing: -0.3)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12, color: p.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  // --- MOBILE COMPONENTS ---

  Widget _buildProfileSummaryCard(AuthUser user, AppPalette p, Color primary) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.line),
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
    );
  }

  Widget _buildOperationalGroup(AuthUser? user, String? branch, AppPalette p, Color primary) {
    return SettingsGroup(
      title: 'Operasional Kasir',
      items: [
        if (user != null && branch != null)
          SettingsTile(
            icon: Icons.storefront_rounded,
            iconColor: const Color(0xFFD97706),
            title: 'Cabang Bertugas',
            subtitle: branch,
            onTap: user.can(AppPermission.changeBranch) && user.locations.length > 1 ? () => _pickBranch(user) : null,
          ),
        SettingsTile(
          icon: Icons.print_rounded,
          iconColor: const Color(0xFF4F46E5),
          title: 'Printer Thermal & Laci Kas',
          subtitle: 'Konfigurasi Bluetooth, LAN port 9100 & ukuran kertas',
          onTap: () => PrinterSettingsModal.show(context),
        ),
      ],
    );
  }

  Widget _buildSecurityGroup(AppPalette p, Color primary) {
    return SettingsGroup(
      title: 'Keamanan & Akses',
      items: [
        SettingsTile(
          icon: Icons.pin_rounded,
          iconColor: const Color(0xFF059669),
          title: _hasPin == true ? 'Ubah PIN Cepat Kasir' : 'Atur PIN Cepat Kasir',
          subtitle: 'Kunci layar POS & otorisasi kasir 4 digit',
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
    );
  }

  Widget _buildSubscriptionGroup(AppPalette p, Color primary) {
    return SettingsGroup(
      title: 'Langganan & Lisensi Outlet',
      items: [
        SettingsTile(
          icon: Icons.workspace_premium_rounded,
          iconColor: const Color(0xFFEA580C),
          title: _subscription?.planName ?? 'Paket Lisensi',
          subtitle: _subscription != null
              ? 'Status: ${_subscription!.statusDisplayName}${_subscription!.daysRemaining != null ? " • Sisa ${_subscription!.daysRemaining} hari" : ""}'
              : (_loadingSubscription ? 'Memuat lisensi...' : 'Belum ada data lisensi'),
          onTap: () => _manageSubscription(context),
        ),
      ],
    );
  }

  Widget _buildAppUpdateGroup(AppPalette p, Color primary) {
    return SettingsGroup(
      title: 'Sistem & Pembaruan',
      items: [
        SettingsTile(
          icon: Icons.system_update_rounded,
          iconColor: const Color(0xFF0284C7),
          title: 'Pembaruan Aplikasi',
          subtitle: _versionInfo != null
              ? '${AppConfig.instance.appName} v${_versionInfo!.versionName} (Build ${_versionInfo!.versionCode})'
              : 'Memeriksa status versi...',
          onTap: () => AppUpdateService.instance.checkAndPrompt(context, notifyIfUpToDate: true),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(AppPalette p) {
    return OutlinedButton.icon(
      onPressed: _confirmLogout,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red.shade700,
        side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Icons.logout_rounded, size: 20),
      label: const Text('Keluar Akun Kasir', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}
