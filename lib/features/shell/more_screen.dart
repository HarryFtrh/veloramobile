import 'package:flutter/material.dart';
import '../../core/storage/session_storage.dart';
import '../shared_pos/receipt_printer_service.dart';
import '../shared_pos/shift_badge.dart';
import 'menu_service.dart';
import 'more_entry.dart';

export 'more_entry.dart';

/// Hub Menu "Lainnya" untuk modul sekunder kasir, hardware printer, lisensi, dan profil toko.
/// Bebas dari duplikasi modul yang sudah menjadi tab navigasi utama (Kasir, Meja, Dapur, Dashboard, Pelanggan).
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
    if (_serverEntries == null) {
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Keluar dari Akun Kasir?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: const Text(
          'Pastikan seluruh pesanan dan transaksi telah tersimpan sebelum keluar dari aplikasi.',
          style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (ok == true) widget.onLogout?.call();
  }

  /// Cek apakah modul ini sudah menjadi tab navigasi utama di shell
  bool _isPrimaryTab(MoreEntry entry) {
    final t = entry.title.toLowerCase().trim();
    return t == 'kasir' ||
        t == 'meja' ||
        t == 'dapur' ||
        t == 'dashboard' ||
        t == 'pelanggan' ||
        t == 'dashboards' ||
        t == 'analytics' ||
        t == 'active tables' ||
        t == 'manajemen meja' ||
        t == 'kitchen display (kds)' ||
        t == 'kitchen display' ||
        t == 'kds' ||
        t == 'crm & customers' ||
        t == 'pelanggan & crm' ||
        t.contains('analitik penjualan') ||
        t.startsWith('kasir register');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= 720;
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final brandPrimary = Theme.of(context).colorScheme.primary;

    final userName = SessionStorage.instance.getUserName() ?? 'Kasir Bertugas';
    final roleName = SessionStorage.instance.getUserRole() ?? 'Staff';
    final tenantName = SessionStorage.instance.getTenantName() ?? 'Velora POS';
    final locationName = SessionStorage.instance.getLocationName() ?? 'Outlet Utama';

    // Filter agar fitur yang sudah jadi tab utama (Meja, Dapur, Dashboard, Pelanggan) TIDAK tampil dobel di menu Lainnya!
    final List<MoreEntry> effectiveEntries;
    if (_serverEntries != null && _serverEntries!.isNotEmpty) {
      final seenTitles = <String>{};
      final merged = <MoreEntry>[];

      for (final s in _serverEntries!) {
        final t = s.title.toLowerCase().trim();
        if (_isPrimaryTab(s) || seenTitles.contains(t)) {
          continue;
        }
        seenTitles.add(t);
        merged.add(s);
      }

      // Pastikan modul pendukung dasar (Hardware Printer, Subscription, Settings, Split Bill, Petty Cash) tidak hilang
      for (final base in widget.entries) {
        final t = base.title.toLowerCase().trim();
        if (!_isPrimaryTab(base) && !seenTitles.contains(t)) {
          seenTitles.add(t);
          merged.add(base);
        }
      }
      effectiveEntries = merged;
    } else {
      effectiveEntries = widget.entries.where((e) => !_isPrimaryTab(e)).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: (!isTablet || canPop)
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              foregroundColor: const Color(0xFF0F172A),
              iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
              title: const Text(
                'Menu & Lainnya',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A), letterSpacing: -0.3),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Sinkronkan Menu Server',
                  onPressed: () => _fetchServerMenu(force: true),
                ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: _isLoading
                    ? LinearProgressIndicator(minHeight: 2, color: brandPrimary, backgroundColor: const Color(0xFFE2E8F0))
                    : Container(color: const Color(0xFFE2E8F0), height: 1),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => _fetchServerMenu(force: true),
        color: brandPrimary,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 1040 : 640),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 16,
                vertical: isTablet ? 24 : 18,
              ),
              children: [
                // 1. Profil & Outlet Hero Card (Hanya di mobile, karena layar tablet sudah memiliki AppShell Top Header lengkap!)
                if (!isTablet) ...[
                  _buildProfileHero(
                    userName: userName,
                    roleName: roleName,
                    tenantName: tenantName,
                    locationName: locationName,
                    brandPrimary: brandPrimary,
                    isTablet: isTablet,
                  ),
                  const SizedBox(height: 16),
                  _buildQuickOperationalCard(brandPrimary),
                  const SizedBox(height: 20),
                ],

                // 2. Categorized Sections (Responsive: 2-Column on Tablet, 1-Column on Mobile)
                if (isTablet)
                  _buildTabletSplitLayout(effectiveEntries, brandPrimary)
                else
                  _buildMobileVerticalLayout(effectiveEntries, brandPrimary),

                const SizedBox(height: 28),

                // 4. Tombol Logout Akun Kasir
                if (widget.onLogout != null) ...[
                  OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFECACA), width: 1.2),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text(
                      'Keluar dari Akun Kasir',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // Versi Aplikasi
                const Center(
                  child: Text(
                    'Velora POS • v2.0 Enterprise Cloud',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Top Profile & Outlet Hero Card
  Widget _buildProfileHero({
    required String userName,
    required String roleName,
    required String tenantName,
    required String locationName,
    required Color brandPrimary,
    required bool isTablet,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 3),
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
                colors: [brandPrimary, brandPrimary.withValues(alpha: 0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: brandPrimary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'K',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
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
                        userName,
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
                        color: brandPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: brandPrimary.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        roleName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: brandPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$tenantName • $locationName',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 7, color: Color(0xFF059669)),
                SizedBox(width: 5),
                Text(
                  'ONLINE',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF059669),
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Quick Shift & Cash Register Operation Card
  Widget _buildQuickOperationalCard(Color brandPrimary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: brandPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.point_of_sale_rounded, size: 18, color: brandPrimary),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shift Kasir Register',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Status pencatatan transaksi & uang laci kasir',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
              const CashierShiftBadge(),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ReceiptPrinterService.instance.openCashDrawer();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Perintah buka laci kasir berhasil dikirim'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  },
                  icon: Icon(Icons.lock_open_rounded, size: 17, color: brandPrimary),
                  label: Text(
                    'Buka Laci Kasir',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: brandPrimary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: brandPrimary.withValues(alpha: 0.25)),
                    backgroundColor: brandPrimary.withValues(alpha: 0.04),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ReceiptPrinterService.instance.openSettings(context),
                  icon: const Icon(Icons.print_outlined, size: 17, color: Color(0xFF334155)),
                  label: const Text(
                    'Pengaturan Printer',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    backgroundColor: const Color(0xFFF8FAFC),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Responsive Tablet: 2 Balanced Columns without duplication
  Widget _buildTabletSplitLayout(List<MoreEntry> entries, Color brandPrimary) {
    final Map<String, List<MoreEntry>> grouped = _groupEntries(entries);
    final allGroups = grouped.entries.toList();

    // Distribute groups across left and right cleanly
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

    // Safety balance if one side has 0 categories:
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
        // Left Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final group in leftGroups) ...[
                _buildCategoryGroup(group.key, group.value, brandPrimary),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
        const SizedBox(width: 20),
        // Right Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final group in rightGroups) ...[
                _buildCategoryGroup(group.key, group.value, brandPrimary),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Responsive Mobile: Single Column Stacked
  Widget _buildMobileVerticalLayout(List<MoreEntry> entries, Color brandPrimary) {
    final Map<String, List<MoreEntry>> grouped = _groupEntries(entries);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in grouped.entries) ...[
          _buildCategoryGroup(group.key, group.value, brandPrimary),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Map<String, List<MoreEntry>> _groupEntries(List<MoreEntry> entries) {
    final Map<String, List<MoreEntry>> grouped = {};
    for (final entry in entries) {
      String cat = entry.category?.trim() ?? 'Operasional Kasir';
      // Normalize generic or legacy categories into professional distinct sections
      if (cat == 'Fitur & Menu Toko' || cat == 'Fitur & Pengaturan Toko' || cat == 'Fitur & Menu Lainnya') {
        final t = entry.title.toLowerCase();
        if (t.contains('split') || t.contains('order') || t.contains('petty') || t.contains('kasir') || t.contains('retur') || t.contains('expens')) {
          cat = 'Operasional Kasir';
        } else if (t.contains('printer') || t.contains('hardware')) {
          cat = 'Perangkat Keras';
        } else if (t.contains('subscription') || t.contains('paket') || t.contains('langganan') || t.contains('lisensi')) {
          cat = 'Bisnis & Lisensi';
        } else if (t.contains('setting') || t.contains('pengaturan') || t.contains('pin') || t.contains('akun') || t.contains('keamanan')) {
          cat = 'Pengaturan & Akun';
        } else {
          cat = 'Operasional Kasir';
        }
      }
      grouped.putIfAbsent(cat, () => []).add(entry);
    }
    return grouped;
  }

  Widget _buildCategoryGroup(String categoryName, List<MoreEntry> groupEntries, Color brandPrimary) {
    final headerIcon = _resolveCategoryIcon(categoryName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(headerIcon, size: 16, color: const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                categoryName.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                for (var i = 0; i < groupEntries.length; i++) ...[
                  _buildMenuItemTile(groupEntries[i], brandPrimary),
                  if (i < groupEntries.length - 1)
                    const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItemTile(MoreEntry entry, Color brandPrimary) {
    final iconColor = entry.iconColor ?? brandPrimary;
    final iconBg = entry.iconBg ?? brandPrimary.withValues(alpha: 0.1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: entry.builder),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: entry.badgeColor ?? const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (entry.badgeColor ?? const Color(0xFFE2E8F0)).withValues(alpha: 0.8),
                    ),
                  ),
                  child: Text(
                    entry.badge!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: entry.badgeTextColor ?? const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  IconData _resolveCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('operasional') || lower.contains('pos') || lower.contains('kasir')) {
      return Icons.point_of_sale_rounded;
    }
    if (lower.contains('perangkat') || lower.contains('hardware') || lower.contains('printer')) {
      return Icons.print_rounded;
    }
    if (lower.contains('bisnis') || lower.contains('lisensi') || lower.contains('paket')) {
      return Icons.workspace_premium_rounded;
    }
    if (lower.contains('pengaturan') || lower.contains('akun') || lower.contains('keamanan')) {
      return Icons.tune_rounded;
    }
    return Icons.grid_view_rounded;
  }
}
