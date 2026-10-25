import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../../../core/storage/session_storage.dart';

/// Navigation drawer for the patron customer self-order screen.
class CustomerNavDrawer extends StatelessWidget {
  const CustomerNavDrawer({
    super.key,
    this.onSwitchToStaffPos,
    required this.onSyncMenu,
    this.onLogout,
  });

  final VoidCallback? onSwitchToStaffPos;
  final VoidCallback onSyncMenu;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: WarmPalette.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.coffee_rounded, size: 36, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  SessionStorage.instance.getTenantName() ?? SessionStorage.instance.getLocationName() ?? 'Velora Kafe',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'Patron Customer Self-Order',
                  style: TextStyle(color: WarmPalette.surfaceMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (onSwitchToStaffPos != null)
            ListTile(
              leading: const Icon(
                Icons.storefront_rounded,
                color: WarmPalette.primary,
              ),
              title: const Text(
                'Buka Kasir POS & Operasional',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('Terminal — ${SessionStorage.instance.getLocationName() ?? "Outlet Utama"}'),
              onTap: () {
                Navigator.of(context).pop();
                onSwitchToStaffPos!();
              },
            ),
          ListTile(
            leading: const Icon(Icons.refresh_rounded),
            title: const Text('Sinkronkan Menu dari Server'),
            onTap: () {
              Navigator.of(context).pop();
              onSyncMenu();
            },
          ),
          if (onLogout != null) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text(
                'Keluar Akun',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                onLogout!();
              },
            ),
          ],
        ],
      ),
    );
  }
}
