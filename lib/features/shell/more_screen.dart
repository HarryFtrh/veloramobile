import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';
import '../../core/storage/session_storage.dart';
import '../shared_pos/receipt_printer_service.dart';
import '../shared_pos/shift_badge.dart';

class MoreEntry {
  const MoreEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;
}

/// Menu Hub "Lainnya" untuk operasional kasir, profil outlet, dan fitur sekunder.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.entries, this.onLogout});

  final List<MoreEntry> entries;
  final VoidCallback? onLogout;

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.logout_rounded, color: Theme.of(ctx).colorScheme.error, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Keluar dari Akun?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        content: const Text(
          'Anda perlu masuk kembali dengan akun toko untuk menggunakan aplikasi kasir ini.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok == true) onLogout?.call();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isWide = MediaQuery.sizeOf(context).width >= 600;
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    final userName = SessionStorage.instance.getUserName() ?? 'Kasir Bertugas';
    final tenantName = SessionStorage.instance.getTenantName() ?? 'Velora POS';
    final locationName = SessionStorage.instance.getLocationName() ?? 'Outlet Utama';

    return Scaffold(
      backgroundColor: WarmPalette.canvas,
      appBar: (!isWide || canPop)
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'Menu & Lainnya',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: WarmPalette.textPrimary),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(color: WarmPalette.line, height: 1),
              ),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            children: [
              // 1. Profile / Store Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: WarmPalette.line, width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: WarmPalette.primary.withValues(alpha: 0.12),
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'K',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: WarmPalette.primary,
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
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: WarmPalette.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$tenantName • $locationName',
                            style: const TextStyle(
                              fontSize: 12,
                              color: WarmPalette.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: WarmPalette.tertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: WarmPalette.tertiary.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 7, color: WarmPalette.tertiary),
                          SizedBox(width: 4),
                          Text(
                            'ONLINE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: WarmPalette.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Section: Operasional Register & Kasir
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  'OPERASIONAL KASIR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: WarmPalette.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: WarmPalette.line),
                ),
                child: Column(
                  children: [
                    // Row 1: Shift Kasir Status & Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lock_clock_outlined, size: 18, color: WarmPalette.primary),
                            SizedBox(width: 8),
                            Text(
                              'Shift Register',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: WarmPalette.textPrimary),
                            ),
                          ],
                        ),
                        const CashierShiftBadge(),
                      ],
                    ),
                    const Divider(height: 20, color: WarmPalette.line),
                    // Row 2: Quick buttons: Buka laci & Printer
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await ReceiptPrinterService.instance.openCashDrawer();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Perintah buka laci kasir dikirim')),
                                );
                              }
                            },
                            icon: const Icon(Icons.point_of_sale_outlined, size: 16),
                            label: const Text(
                              'Buka Laci',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: WarmPalette.primary,
                              side: const BorderSide(color: WarmPalette.line),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => ReceiptPrinterService.instance.openSettings(context),
                            icon: const Icon(Icons.print_outlined, size: 16),
                            label: const Text(
                              'Printer',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: WarmPalette.textPrimary,
                              side: const BorderSide(color: WarmPalette.line),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Section: Fitur & Pengaturan
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  'FITUR & PENGATURAN TOKO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: WarmPalette.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: WarmPalette.line),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < entries.length; i++) ...[
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.vertical(
                            top: i == 0 ? const Radius.circular(16) : Radius.zero,
                            bottom: i == entries.length - 1 ? const Radius.circular(16) : Radius.zero,
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: entries[i].builder),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: WarmPalette.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(entries[i].icon, color: WarmPalette.primary, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entries[i].title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5,
                                          color: WarmPalette.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        entries[i].subtitle,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: WarmPalette.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: WarmPalette.textTertiary, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (i < entries.length - 1)
                        const Divider(height: 1, indent: 56, endIndent: 16, color: WarmPalette.line),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 4. Logout Button
              if (onLogout != null) ...[
                OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: WarmPalette.danger,
                    side: BorderSide(color: WarmPalette.danger.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Keluar dari Akun', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
                const SizedBox(height: 16),
              ],

              // Version Tag
              Center(
                child: Text(
                  'Velora POS • v1.0.0',
                  style: TextStyle(fontSize: 11, color: p.textTertiary, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
