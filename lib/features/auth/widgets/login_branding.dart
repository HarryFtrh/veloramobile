import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';

/// Branding configurations per application flavor.
class LoginBranding {
  const LoginBranding({
    required this.badge,
    required this.icon,
    required this.subtitle,
    required this.buttonLabel,
    required this.idLabel,
    required this.branchTitle,
    this.showRegister = true,
  });

  final String badge;
  final IconData icon;
  final String subtitle;
  final String buttonLabel;
  final String idLabel;
  final String branchTitle;
  final bool showRegister;

  static LoginBranding of(AppFlavor flavor) {
    switch (flavor) {
      case AppFlavor.pharmacy:
        return const LoginBranding(
          badge: 'APOTEK',
          icon: Icons.medical_services_rounded,
          subtitle: 'Masuk untuk membuka kasir apotek & resep',
          buttonLabel: 'Masuk ke Apotek',
          idLabel: 'Email atau Username Apoteker',
          branchTitle: 'Pilih Cabang Apotek',
        );
      case AppFlavor.sales:
        return const LoginBranding(
          badge: 'SALES FIELD',
          icon: Icons.route_rounded,
          subtitle: 'Masuk untuk memulai absensi & kunjungan sales',
          buttonLabel: 'Masuk Sales',
          idLabel: 'Email atau Username Sales',
          branchTitle: 'Pilih Area / Cabang',
          showRegister: false,
        );
      case AppFlavor.marketplace:
        return const LoginBranding(
          badge: 'MARKETPLACE',
          icon: Icons.storefront_rounded,
          subtitle: 'Masuk untuk mengelola pesanan marketplace',
          buttonLabel: 'Masuk Marketplace',
          idLabel: 'Email atau Username Penjual',
          branchTitle: 'Pilih Toko',
        );
      case AppFlavor.customer:
        return const LoginBranding(
          badge: 'SELF-ORDER',
          icon: Icons.coffee_rounded,
          subtitle: 'Masuk untuk memesan langsung dari meja',
          buttonLabel: 'Masuk Self-Order',
          idLabel: 'Email atau Nomor HP',
          branchTitle: 'Pilih Outlet Kafe',
        );
      case AppFlavor.fnb:
        return const LoginBranding(
          badge: 'F&B',
          icon: Icons.coffee_rounded,
          subtitle: 'Masuk untuk mengelola pesanan & kafe',
          buttonLabel: 'Masuk Sekarang',
          idLabel: 'Email atau Username',
          branchTitle: 'Pilih Cabang',
        );
    }
  }
}
