import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/design/tokens.dart';
import '../../core/storage/session_storage.dart';
import '../shared_pos/offline_sync_badge.dart';
import '../shared_pos/receipt_printer_service.dart';
import '../shared_pos/shift_badge.dart';

class ShellTab {
  const ShellTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final WidgetBuilder builder;
}

/// Kerangka navigasi utama. Tab disusun oleh pemanggil sesuai flavor.
/// Pada layar lebar (tablet landscape/desktop POS), menggunakan Top Header Bar
/// terpadu sesuai standar POS kasir modern (brand, shift, tabs, clock, quick actions).
/// Pada layar smartphone, menggunakan Bottom Navigation Bar.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
    this.tabControllerNotifier,
  }) : assert(tabs.length >= 2, 'Shell butuh minimal dua tab');

  final List<ShellTab> tabs;
  final int initialIndex;
  final ValueNotifier<int>? tabControllerNotifier;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const double _headerBreakpoint = 600;

  int _index = 0;
  late final Set<int> _visited = {_index};

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _visited.add(_index);
    widget.tabControllerNotifier?.addListener(_onTabControllerChanged);
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabControllerNotifier != widget.tabControllerNotifier) {
      oldWidget.tabControllerNotifier?.removeListener(_onTabControllerChanged);
      widget.tabControllerNotifier?.addListener(_onTabControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.tabControllerNotifier?.removeListener(_onTabControllerChanged);
    super.dispose();
  }

  void _onTabControllerChanged() {
    final newIdx = widget.tabControllerNotifier?.value;
    if (newIdx != null && newIdx >= 0 && newIdx < widget.tabs.length && newIdx != _index) {
      _select(newIdx);
    }
  }

  void _select(int i) {
    setState(() {
      _index = i;
      _visited.add(i);
    });
    if (widget.tabControllerNotifier != null && widget.tabControllerNotifier!.value != i) {
      widget.tabControllerNotifier!.value = i;
    }
  }

  Widget _buildTopHeader(BuildContext context) {
    final p = context.palette;
    final brandPrimary = Theme.of(context).colorScheme.primary;
    final tenant = SessionStorage.instance.getTenantName() ?? 'Velora POS';
    final location = SessionStorage.instance.getLocationName() ?? 'Terminal #01';
    final user = SessionStorage.instance.getUserName() ?? 'Kasir';
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final isCompact = w < 850;
        final isVeryCompact = w < 720;

        return Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border(bottom: BorderSide(color: p.line)),
          ),
          child: Row(
            children: [
              // Brand Logo + Store Name + Terminal
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: brandPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  AppConfig.instance.flavor == AppFlavor.pharmacy
                      ? Icons.local_pharmacy_rounded
                      : (AppConfig.instance.flavor == AppFlavor.sales
                          ? Icons.inventory_2_rounded
                          : Icons.coffee_maker_rounded),
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isVeryCompact ? 80 : (isCompact ? 110 : 160)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tenant,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: WarmPalette.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: WarmPalette.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        location,
                        style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: WarmPalette.secondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(height: 28, width: 1, color: p.line),
              const SizedBox(width: 6),

              // Kasir Shift Badge
              if (!isVeryCompact) ...[
                const CashierShiftBadge(),
                const SizedBox(width: 6),
                Container(height: 28, width: 1, color: p.line),
                const SizedBox(width: 6),
              ],

              // Center Navigation Tabs
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < widget.tabs.length; i++) ...[
                        Builder(builder: (ctx) {
                          final t = widget.tabs[i];
                          final isSelected = _index == i;
                          return InkWell(
                            onTap: () => _select(i),
                            child: Container(
                              height: 56,
                              padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: isSelected ? brandPrimary : Colors.transparent,
                                    width: 2.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isSelected ? t.selectedIcon : t.icon,
                                    size: 18,
                                    color: isSelected ? brandPrimary : p.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    t.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      color: isSelected ? brandPrimary : p.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(width: 2),
                      ],
                    ],
                  ),
                ),
              ),

              // Online Status & Clock & Offline Queue Badge
              OfflineSyncBadge(
                showClock: !isCompact,
                timeStr: timeStr,
              ),
              const SizedBox(width: 6),

              // Action Buttons: Buka Laci, Printer, Avatar
              if (!isCompact)
                OutlinedButton.icon(
                  onPressed: () async {
                    await ReceiptPrinterService.instance.openCashDrawer();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perintah buka laci kasir dikirim')));
                    }
                  },
                  icon: const Icon(Icons.lock_open_rounded, size: 14),
                  label: const Text('Buka Laci', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: WarmPalette.primary,
                    minimumSize: const Size(0, 32),
                    side: const BorderSide(color: WarmPalette.line),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                )
              else
                IconButton(
                  tooltip: 'Buka Laci Kasir',
                  icon: const Icon(Icons.lock_open_rounded, size: 18, color: WarmPalette.primary),
                  onPressed: () async {
                    await ReceiptPrinterService.instance.openCashDrawer();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perintah buka laci kasir dikirim')));
                    }
                  },
                ),
              const SizedBox(width: 2),
              IconButton(
                tooltip: 'Pengaturan Printer',
                icon: const Icon(Icons.print_outlined, size: 18),
                onPressed: () => ReceiptPrinterService.instance.openSettings(context),
              ),
              const SizedBox(width: 4),
              CircleAvatar(
                radius: 14,
                backgroundColor: WarmPalette.primary.withValues(alpha: 0.15),
                child: Text(
                  user.isNotEmpty ? user[0].toUpperCase() : 'K',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: WarmPalette.primary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPharmacyLeftDock(BuildContext context) {
    const dockBg = Color(0xFFFFFFFF);
    const borderColor = Color(0xFFE2E8F0);
    const emeraldPrimary = Color(0xFF006948);
    const activeBg = Color(0xFF86F2E4);
    const activeFg = Color(0xFF006F66);
    const inactiveFg = Color(0xFF6D7A72);
    final user = SessionStorage.instance.getUserName() ?? 'Siti Rahma';
    final initials = user.trim().split(' ').map((s) => s.isNotEmpty ? s[0].toUpperCase() : '').take(2).join();

    return Container(
      width: 76,
      decoration: const BoxDecoration(
        color: dockBg,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Brand Mark: Stitch Clinical Precision
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: emeraldPrimary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: emeraldPrimary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.local_hospital_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 28,
            height: 2,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),

          // Workstation Navigation Tabs
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(widget.tabs.length, (i) {
                  final t = widget.tabs[i];
                  final isSelected = _index == i;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Tooltip(
                      message: '${t.label} (F${i + 1})',
                      child: InkWell(
                        onTap: () => _select(i),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 58,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isSelected ? activeBg : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isSelected ? t.selectedIcon : t.icon,
                                    size: 22,
                                    color: isSelected ? activeFg : inactiveFg,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    t.label,
                                    style: TextStyle(
                                      fontFamily: 'JetBrains Mono',
                                      fontSize: 10,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? activeFg : inactiveFg,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              if (i == 1) // Notification dot for Antrean
                                Positioned(
                                  top: 6,
                                  right: 8,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFBA1A1A),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Bottom Utilities: Drawer, Settings, Cashier Avatar
          Tooltip(
            message: 'Buka Laci Kasir (Ctrl+O)',
            child: IconButton(
              icon: const Icon(Icons.savings_outlined, size: 22, color: inactiveFg),
              onPressed: () async {
                await ReceiptPrinterService.instance.openCashDrawer();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Perintah buka laci kasir dikirim')),
                  );
                }
              },
            ),
          ),
          Tooltip(
            message: 'Pengaturan Workstation',
            child: IconButton(
              icon: const Icon(Icons.settings_outlined, size: 22, color: inactiveFg),
              onPressed: () => ReceiptPrinterService.instance.openSettings(context),
            ),
          ),
          const SizedBox(height: 4),
          Tooltip(
            message: '$user (Kasir Aktif)',
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF85F8C4).withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(color: emeraldPrimary.withValues(alpha: 0.3)),
              ),
              alignment: Alignment.center,
              child: Text(
                initials.isNotEmpty ? initials : 'SR',
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF002114),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= _headerBreakpoint;

    final body = IndexedStack(
      index: _index,
      children: [
        for (var i = 0; i < widget.tabs.length; i++)
          _visited.contains(i) ? widget.tabs[i].builder(context) : const SizedBox.shrink(),
      ],
    );

    if (wide) {
      if (AppConfig.instance.flavor == AppFlavor.pharmacy) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: const Color(0xFFFAF8FF),
          body: SafeArea(
            child: Row(
              children: [
                _buildPharmacyLeftDock(context),
                Expanded(child: body),
              ],
            ),
          ),
        );
      }
      return Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildTopHeader(context),
              Expanded(child: body),
            ],
          ),
        ),
      );
    }

    final p = context.palette;
    final brandPrimary = Theme.of(context).colorScheme.primary;
    final isPharmacy = AppConfig.instance.flavor == AppFlavor.pharmacy;
    final pharmacyIndicator = const Color(0xFF86F2E4);
    final pharmacyActive = const Color(0xFF006F66);
    final pharmacyInactive = const Color(0xFF6D7A72);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: body,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: isPharmacy ? const Color(0xFFE2E8F0) : WarmPalette.line, width: 1.2),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 62,
            backgroundColor: Colors.white,
            elevation: 0,
            indicatorColor: isPharmacy ? pharmacyIndicator : brandPrimary.withValues(alpha: 0.12),
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return IconThemeData(color: isPharmacy ? pharmacyActive : brandPrimary, size: 22);
              }
              return IconThemeData(color: isPharmacy ? pharmacyInactive : p.textSecondary, size: 22);
            }),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return TextStyle(
                  fontFamily: isPharmacy ? 'JetBrains Mono' : null,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isPharmacy ? pharmacyActive : brandPrimary,
                  letterSpacing: -0.2,
                );
              }
              return TextStyle(
                fontFamily: isPharmacy ? 'JetBrains Mono' : null,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: isPharmacy ? pharmacyInactive : p.textSecondary,
                letterSpacing: -0.2,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _select,
            destinations: [
              for (final t in widget.tabs)
                NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.selectedIcon),
                  label: t.label,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
