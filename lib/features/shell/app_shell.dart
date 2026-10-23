import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';
import '../../core/storage/session_storage.dart';
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
  const AppShell({super.key, required this.tabs})
      : assert(tabs.length >= 2, 'Shell butuh minimal dua tab');

  final List<ShellTab> tabs;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const double _headerBreakpoint = 600;

  int _index = 0;
  late final Set<int> _visited = {0};

  void _select(int i) => setState(() {
        _index = i;
        _visited.add(i);
      });

  Widget _buildTopHeader(BuildContext context) {
    final p = context.palette;
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
                  color: WarmPalette.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.coffee_maker_rounded, color: Colors.white, size: 18),
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
                                    color: isSelected ? WarmPalette.primary : Colors.transparent,
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
                                    color: isSelected ? WarmPalette.primary : p.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    t.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      color: isSelected ? WarmPalette.primary : p.textSecondary,
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

              // Online Status & Clock
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: p.surfaceMuted,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: p.line),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, size: 6, color: WarmPalette.tertiary),
                    const SizedBox(width: 4),
                    const Text(
                      'ONLINE',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: WarmPalette.tertiary),
                    ),
                    if (!isCompact) ...[
                      const SizedBox(width: 6),
                      Text(
                        timeStr,
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: p.textSecondary),
                      ),
                    ],
                  ],
                ),
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

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: body,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: WarmPalette.line, width: 1.2),
          ),
          boxShadow: [
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
            indicatorColor: WarmPalette.primary.withValues(alpha: 0.12),
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: WarmPalette.primary, size: 22);
              }
              return IconThemeData(color: p.textSecondary, size: 22);
            }),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: WarmPalette.primary,
                  letterSpacing: -0.2,
                );
              }
              return TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: p.textSecondary,
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
