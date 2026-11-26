import 'package:material_ui/material_ui.dart';

import '../../core/design/tokens.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/audio_helper.dart';
import '../shared_pos/services/receipt_printer_service.dart';
import '../shared_pos/widgets/shift_badge.dart';
import 'menu_service.dart';
import 'more_entry.dart';

export 'more_entry.dart';

/// Hub Menu "Lainnya" dengan desain modern airy-minimalis (terinspirasi
/// Solstice / @dailyflutterui_2001): kartu soft-surface ber-radius besar,
/// bento quick actions dengan tactile bounce, dan daftar grup inset bersih.
class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key, required this.entries, this.onLogout});

  final List<MoreEntry> entries;
  final VoidCallback? onLogout;

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  List<MoreEntry>? _serverEntries;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _serverEntries = MenuService.instance.cachedEntries;
    _fetchServerMenu();
  }

  Future<void> _fetchServerMenu({bool force = false}) async {
    if (_serverEntries == null || force) {
      setState(() => _isLoading = true);
    }
    try {
      final items = await MenuService.instance.fetchMyMenu(forceRefresh: force);
      if (mounted && items.isNotEmpty) {
        setState(() {
          _serverEntries = items;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await AppConfirmDialog.show(
      context,
      title: 'Keluar dari Akun Kasir?',
      message:
          'Pastikan seluruh pesanan dan transaksi telah tersimpan sebelum keluar dari aplikasi.',
      confirmLabel: 'Keluar',
      isDestructive: true,
      icon: Icons.logout_rounded,
    );
    if (ok == true) widget.onLogout?.call();
  }

  /// Cek apakah modul ini sudah menjadi tab navigasi utama di shell
  /// sehingga tidak pernah muncul dobel di menu "Lainnya".
  bool _isPrimaryTab(MoreEntry entry) {
    final t = entry.title.toLowerCase().trim();
    final cat = (entry.category ?? '').toLowerCase().trim();

    if (t.contains('dashboard') ||
        t.contains('analytic') ||
        t.contains('analitik') ||
        t.contains('omzet') ||
        t.contains('laporan') ||
        t.contains('ringkasan') ||
        cat.contains('analitik') ||
        cat.contains('dashboard')) {
      return true;
    }

    if (t.contains('pelanggan') ||
        t.contains('customer') ||
        t.contains('crm') ||
        t.contains('member') ||
        cat.contains('pelanggan') ||
        cat.contains('crm')) {
      return true;
    }

    if (t.contains('meja') ||
        t.contains('table') ||
        t.contains('dine-in') ||
        t.contains('dine in') ||
        cat.contains('meja') ||
        cat.contains('dine-in')) {
      return true;
    }

    if (t.contains('dapur') ||
        t.contains('kitchen') ||
        t.contains('kds') ||
        t.contains('barista') ||
        cat.contains('dapur') ||
        cat.contains('kds')) {
      return true;
    }

    if (t == 'kasir' ||
        t == 'pos' ||
        t.contains('kasir register') ||
        t.contains('register f&b') ||
        t.contains('pos f&b') ||
        t.contains('f&b pos')) {
      return true;
    }

    return false;
  }

  List<MoreEntry> _resolveEffectiveEntries() {
    if (_serverEntries != null && _serverEntries!.isNotEmpty) {
      final seenTitles = <String>{};
      final merged = <MoreEntry>[];

      for (final s in _serverEntries!) {
        final t = s.title.toLowerCase().trim();
        if (_isPrimaryTab(s) || seenTitles.contains(t)) continue;
        seenTitles.add(t);
        merged.add(s);
      }

      for (final base in widget.entries) {
        final t = base.title.toLowerCase().trim();
        if (!_isPrimaryTab(base) && !seenTitles.contains(t)) {
          seenTitles.add(t);
          merged.add(base);
        }
      }
      return merged;
    }
    return widget.entries.where((e) => !_isPrimaryTab(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= 720;
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandPrimary = Theme.of(context).colorScheme.primary;

    final userName = SessionStorage.instance.getUserName() ?? 'Kasir Bertugas';
    final roleName = SessionStorage.instance.getUserRole() ?? 'Staff';
    final tenantName = SessionStorage.instance.getTenantName() ?? 'Velora POS';
    final locationName = SessionStorage.instance.getLocationName() ?? 'Outlet Utama';
    final effectiveEntries = _resolveEffectiveEntries();

    return Scaffold(
      backgroundColor: p.canvas,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _fetchServerMenu(force: true),
          color: brandPrimary,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isTablet ? 1040 : 620),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  isTablet ? 24 : 18,
                  isTablet ? 20 : 12,
                  isTablet ? 24 : 18,
                  32,
                ),
                children: [
                  // 1. Editorial Floating Header (tanpa AppBar kaku bergaris)
                  if (!isTablet || canPop) ...[
                    _buildEditorialHeader(
                      context: context,
                      p: p,
                      isDark: isDark,
                      canPop: canPop,
                      brandPrimary: brandPrimary,
                    ),
                    const SizedBox(height: 18),
                  ],

                  // 2. Hero Profile + Integrated Shift Strip + Bento Quick Actions (Mobile)
                  if (!isTablet) ...[
                    RepaintBoundary(
                      child: _buildProfileBentoCard(
                        p: p,
                        isDark: isDark,
                        userName: userName,
                        roleName: roleName,
                        tenantName: tenantName,
                        locationName: locationName,
                        brandPrimary: brandPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    RepaintBoundary(
                      child: _buildQuickActionsBento(
                        p: p,
                        isDark: isDark,
                        brandPrimary: brandPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 3. Grouped Menu Sections
                  if (isTablet)
                    _buildTabletSplitLayout(effectiveEntries, brandPrimary, isDark)
                  else
                    _buildMobileVerticalLayout(effectiveEntries, brandPrimary, isDark),

                  // 4. Full-Width Stadium Pill Logout CTA
                  if (widget.onLogout != null) ...[
                    const SizedBox(height: 8),
                    _TactilePressScale(
                      scaleOnPress: 0.97,
                      onTap: () => _confirmLogout(context),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: p.danger.withValues(alpha: isDark ? 0.16 : 0.09),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: p.danger.withValues(alpha: isDark ? 0.28 : 0.18),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, size: 18, color: p.danger),
                            const SizedBox(width: 8),
                            Text(
                              'Keluar dari Akun Kasir',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: p.danger,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 5. Subtle App Version Footer
                  Center(
                    child: Text(
                      'Velora POS • v2.0 Cloud',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: p.textTertiary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditorialHeader({
    required BuildContext context,
    required AppPalette p,
    required bool isDark,
    required bool canPop,
    required Color brandPrimary,
  }) {
    return Row(
      children: [
        if (canPop) ...[
          _buildCircleHeaderButton(
            p: p,
            isDark: isDark,
            icon: Icons.chevron_left_rounded,
            tooltip: 'Kembali',
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lainnya',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                  letterSpacing: -0.7,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Operasional, perangkat & pengaturan',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: p.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _buildCircleHeaderButton(
          p: p,
          isDark: isDark,
          tooltip: 'Sinkronkan Menu Server',
          onTap: () {
            AudioHelper.tapFeedback();
            _fetchServerMenu(force: true);
          },
          child: _isLoading
              ? VeloraOrbitLoader.inline(size: 18, color: brandPrimary)
              : Icon(Icons.refresh_rounded, size: 19, color: p.textPrimary),
        ),
      ],
    );
  }

  Widget _buildCircleHeaderButton({
    required AppPalette p,
    required bool isDark,
    IconData? icon,
    Widget? child,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: _TactilePressScale(
        scaleOnPress: 0.90,
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: p.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : p.line.withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: child ?? Icon(icon, size: 22, color: p.textPrimary),
        ),
      ),
    );
  }

  /// Unified Airy Profile & Shift Status Bento Card (Solstice style)
  Widget _buildProfileBentoCard({
    required AppPalette p,
    required bool isDark,
    required String userName,
    required String roleName,
    required String tenantName,
    required String locationName,
    required Color brandPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _softCardDecoration(p: p, isDark: isDark, radius: 26),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      brandPrimary,
                      Color.lerp(brandPrimary, Colors.black, 0.18)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: brandPrimary.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'K',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: p.textPrimary,
                        letterSpacing: -0.35,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$tenantName • $locationName',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: p.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: p.success.withValues(alpha: isDark ? 0.20 : 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: p.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Online',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: p.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    roleName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: p.textTertiary,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Nested Shift Status Pill Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: p.surfaceMuted,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(Icons.point_of_sale_rounded, size: 17, color: brandPrimary),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Shift Kasir',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: p.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const CashierShiftBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 4-Tile Tactile Bento Quick Actions Strip
  Widget _buildQuickActionsBento({
    required AppPalette p,
    required bool isDark,
    required Color brandPrimary,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildBentoTile(
            p: p,
            isDark: isDark,
            icon: Icons.lock_open_rounded,
            label: 'Buka Laci',
            color: brandPrimary,
            onTap: () async {
              await ReceiptPrinterService.instance.openCashDrawer();
              if (mounted) {
                context.showSuccessToast('Perintah buka laci kasir dikirim');
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildBentoTile(
            p: p,
            isDark: isDark,
            icon: Icons.print_rounded,
            label: 'Printer',
            color: const Color(0xFF0284C7),
            onTap: () => ReceiptPrinterService.instance.openSettings(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildBentoTile(
            p: p,
            isDark: isDark,
            icon: Icons.sync_rounded,
            label: 'Sinkron',
            color: const Color(0xFF059669),
            onTap: () => _fetchServerMenu(force: true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildBentoTile(
            p: p,
            isDark: isDark,
            icon: Icons.receipt_long_rounded,
            label: 'Test Print',
            color: const Color(0xFFD97706),
            onTap: () async {
              final ok = await ReceiptPrinterService.instance.printReceipt(
                ReceiptData(
                  storeName: SessionStorage.instance.getTenantName() ?? 'Velora POS',
                  invoiceNumber: 'TEST-PRINT',
                  cashierName: SessionStorage.instance.getUserName() ?? 'Kasir',
                  timestamp: DateTime.now(),
                  items: const [],
                  subtotal: 0,
                  grandTotal: 0,
                  paidAmount: 0,
                  changeAmount: 0,
                  paymentMethod: 'TEST',
                  note: 'Tes koneksi printer berhasil',
                ),
              );
              if (mounted) {
                context.showSuccessToast(
                  ok
                      ? 'Tes cetak struk berhasil dikirim'
                      : 'Printer belum terhubung — buka Pengaturan Printer',
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBentoTile({
    required AppPalette p,
    required bool isDark,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _TactilePressScale(
      scaleOnPress: 0.93,
      onTap: () {
        AudioHelper.tapFeedback();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: _softCardDecoration(p: p, isDark: isDark, radius: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.22 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 19, color: color),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletSplitLayout(
    List<MoreEntry> entries,
    Color brandPrimary,
    bool isDark,
  ) {
    final grouped = _groupEntries(entries);
    final allGroups = grouped.entries.toList();

    final leftGroups = <MapEntry<String, List<MoreEntry>>>[];
    final rightGroups = <MapEntry<String, List<MoreEntry>>>[];

    for (final group in allGroups) {
      final keyLower = group.key.toLowerCase();
      if (keyLower.contains('operasional') || keyLower.contains('pos')) {
        leftGroups.add(group);
      } else {
        rightGroups.add(group);
      }
    }

    if (leftGroups.isEmpty && rightGroups.isNotEmpty) {
      final mid = (rightGroups.length / 2).ceil();
      leftGroups.addAll(rightGroups.sublist(0, mid));
      rightGroups.removeRange(0, mid);
    } else if (rightGroups.isEmpty && leftGroups.isNotEmpty) {
      final mid = (leftGroups.length / 2).ceil();
      rightGroups.addAll(leftGroups.sublist(mid));
      leftGroups.removeRange(mid, leftGroups.length);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final group in leftGroups) ...[
                RepaintBoundary(
                  child: _buildCategoryGroup(
                    group.key,
                    group.value,
                    brandPrimary,
                    isDark,
                  ),
                ),
                const SizedBox(height: 22),
              ],
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final group in rightGroups) ...[
                RepaintBoundary(
                  child: _buildCategoryGroup(
                    group.key,
                    group.value,
                    brandPrimary,
                    isDark,
                  ),
                ),
                const SizedBox(height: 22),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileVerticalLayout(
    List<MoreEntry> entries,
    Color brandPrimary,
    bool isDark,
  ) {
    final grouped = _groupEntries(entries);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in grouped.entries) ...[
          RepaintBoundary(
            child: _buildCategoryGroup(
              group.key,
              group.value,
              brandPrimary,
              isDark,
            ),
          ),
          const SizedBox(height: 22),
        ],
      ],
    );
  }

  Map<String, List<MoreEntry>> _groupEntries(List<MoreEntry> entries) {
    final Map<String, List<MoreEntry>> grouped = {};
    for (final entry in entries) {
      String cat = entry.category?.trim() ?? 'Operasional Kasir';
      if (cat == 'Fitur & Menu Toko' ||
          cat == 'Fitur & Pengaturan Toko' ||
          cat == 'Fitur & Menu Lainnya') {
        final t = entry.title.toLowerCase();
        if (t.contains('split') ||
            t.contains('order') ||
            t.contains('petty') ||
            t.contains('kasir') ||
            t.contains('retur') ||
            t.contains('expens')) {
          cat = 'Operasional Kasir';
        } else if (t.contains('printer') || t.contains('hardware')) {
          cat = 'Perangkat Keras';
        } else if (t.contains('subscription') ||
            t.contains('paket') ||
            t.contains('langganan') ||
            t.contains('lisensi')) {
          cat = 'Bisnis & Lisensi';
        } else if (t.contains('setting') ||
            t.contains('pengaturan') ||
            t.contains('pin') ||
            t.contains('akun') ||
            t.contains('keamanan')) {
          cat = 'Pengaturan & Akun';
        } else {
          cat = 'Operasional Kasir';
        }
      }
      grouped.putIfAbsent(cat, () => []).add(entry);
    }
    return grouped;
  }

  Widget _buildCategoryGroup(
    String categoryName,
    List<MoreEntry> groupEntries,
    Color brandPrimary,
    bool isDark,
  ) {
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 10),
          child: Text(
            categoryName.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: p.textTertiary,
            ),
          ),
        ),
        Container(
          decoration: _softCardDecoration(p: p, isDark: isDark, radius: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                for (var i = 0; i < groupEntries.length; i++) ...[
                  _buildMenuItemTile(groupEntries[i], brandPrimary, isDark),
                  if (i < groupEntries.length - 1)
                    Divider(
                      height: 1,
                      indent: 72,
                      endIndent: 18,
                      color: p.line.withValues(alpha: isDark ? 0.55 : 0.65),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItemTile(
    MoreEntry entry,
    Color brandPrimary,
    bool isDark,
  ) {
    final p = context.palette;
    final iconColor = entry.iconColor ?? brandPrimary;
    final iconBg = entry.iconBg ??
        iconColor.withValues(alpha: isDark ? 0.20 : 0.11);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AudioHelper.tapFeedback();
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: entry.builder),
          );
        },
        splashColor: brandPrimary.withValues(alpha: 0.06),
        highlightColor: p.surfaceMuted.withValues(alpha: 0.55),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(entry.icon, color: iconColor, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: p.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: p.textSecondary,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (entry.badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: entry.badgeColor ?? p.surfaceMuted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    entry.badge!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: entry.badgeTextColor ?? p.textSecondary,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: p.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: p.textSecondary,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _softCardDecoration({
    required AppPalette p,
    required bool isDark,
    required double radius,
  }) {
    return BoxDecoration(
      color: p.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : p.line.withValues(alpha: 0.45),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.04),
          blurRadius: 18,
          spreadRadius: -3,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}

/// Lightweight tactile press-scale wrapper for bento tiles and circular buttons.
class _TactilePressScale extends StatefulWidget {
  const _TactilePressScale({
    required this.child,
    required this.onTap,
    this.scaleOnPress = 0.95,
  });

  final Widget child;
  final VoidCallback onTap;
  final double scaleOnPress;

  @override
  State<_TactilePressScale> createState() => _TactilePressScaleState();
}

class _TactilePressScaleState extends State<_TactilePressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.scaleOnPress : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
