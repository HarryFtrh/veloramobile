import 'package:flutter/material.dart';
import '../../core/config/business_vertical.dart';
import '../customers/customers_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../finance/expenses_screen.dart';
import '../finance/return_screen.dart';
import '../fnb/fnb_payment_split_screen.dart';
import '../fnb_customer/customer_home_screen.dart';
import '../settings/settings_screen.dart';
import 'more_entry.dart';

/// Centralized Factory for MoreScreen menu entries per business vertical.
/// Eliminates redundant inline hardcoded menu declarations.
class MoreMenuFactory {
  static List<MoreEntry> entriesFor(BusinessVertical vertical) {
    switch (vertical) {
      case BusinessVertical.fnb:
        return [
          MoreEntry(
            icon: Icons.dashboard_rounded,
            title: 'Dashboard & Analitik Penjualan',
            subtitle: 'Ringkasan omzet harian, status pesanan, & tren',
            builder: (_) => const DashboardScreen(),
          ),
          MoreEntry(
            icon: Icons.coffee_rounded,
            title: 'Mode Pelanggan (Customer Self-Order)',
            subtitle: 'Layar eksplorasi menu, kustomisasi pesanan, & live tracking',
            builder: (_) => const CustomerHomeScreen(),
          ),
          MoreEntry(
            icon: Icons.call_split_rounded,
            title: 'Kasir Split Bill & Pecahan Uang',
            subtitle: 'Pembayaran bagi tagihan, numpad, & kalkulator kembalian',
            builder: (_) => const FnbPaymentSplitScreen(),
          ),
          MoreEntry(
            icon: Icons.people_outline_rounded,
            title: 'Pelanggan & CRM',
            subtitle: 'Daftar pelanggan dan riwayat transaksi',
            builder: (_) => const CustomersScreen(),
          ),
          MoreEntry(
            icon: Icons.settings_outlined,
            title: 'Pengaturan & Cabang',
            subtitle: 'Pilih cabang aktif, printer kasir, dan sesi',
            builder: (_) => const SettingsScreen(),
          ),
        ];

      case BusinessVertical.retail:
      default:
        return [
          MoreEntry(
            icon: Icons.dashboard_rounded,
            title: 'Dashboard & Analitik Penjualan',
            subtitle: 'Ringkasan omzet harian, status penjualan, & tren',
            builder: (_) => const DashboardScreen(),
          ),
          MoreEntry(
            icon: Icons.people_outline_rounded,
            title: 'Pelanggan & CRM',
            subtitle: 'Member, poin loyalitas, riwayat, dan buku kasbon',
            builder: (_) => const CustomersScreen(),
          ),
          MoreEntry(
            icon: Icons.assignment_return_outlined,
            title: 'Retur Penjualan & Faktur',
            subtitle: 'Retur barang invoice transaksi atau ke supplier',
            builder: (_) => const ReturnScreen(),
          ),
          MoreEntry(
            icon: Icons.payments_outlined,
            title: 'Pengeluaran Kasir (Petty Cash)',
            subtitle: 'Pencatatan kas operasional toko harian',
            builder: (_) => const ExpensesScreen(),
          ),
          MoreEntry(
            icon: Icons.settings_outlined,
            title: 'Pengaturan & Cabang',
            subtitle: 'Pilih cabang aktif, printer kasir, dan sesi',
            builder: (_) => const SettingsScreen(),
          ),
        ];
    }
  }
}
