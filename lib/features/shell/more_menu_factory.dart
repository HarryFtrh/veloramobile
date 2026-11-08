import 'package:flutter/material.dart';
import '../../core/config/business_vertical.dart';
import '../customers/customers_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../finance/expenses_screen.dart';
import '../finance/return_screen.dart';
import '../fnb/fnb_payment_split_screen.dart';
import '../fnb_customer/customer_home_screen.dart';
import '../settings/settings_screen.dart';
import '../shared_pos/printer_settings_screen.dart';
import '../subscription/subscription_screen.dart';
import 'more_entry.dart';

/// Centralized Factory for MoreScreen menu entries per business vertical.
/// Pecah menu secara terstruktur: Operasional, Hardware/Printer, Lisensi, dan Pengaturan Akun.
class MoreMenuFactory {
  static List<MoreEntry> entriesFor(BusinessVertical vertical) {
    switch (vertical) {
      case BusinessVertical.fnb:
        return [
          const MoreEntry(
            category: 'Analitik & CRM',
            icon: Icons.dashboard_rounded,
            title: 'Dashboard & Analitik Penjualan',
            subtitle: 'Ringkasan omzet harian, status pesanan, & tren',
            builder: _buildDashboard,
          ),
          const MoreEntry(
            category: 'Operasional Kasir',
            icon: Icons.coffee_rounded,
            title: 'Mode Pelanggan (Customer Self-Order)',
            subtitle: 'Layar eksplorasi menu meja & live tracking pesanan',
            builder: _buildCustomerHome,
          ),
          const MoreEntry(
            category: 'Operasional Kasir',
            icon: Icons.call_split_rounded,
            title: 'Kasir Split Bill & Pecahan Uang',
            subtitle: 'Pembayaran bagi tagihan, numpad, & kalkulator kembalian',
            builder: _buildSplitBill,
          ),
          const MoreEntry(
            category: 'Analitik & CRM',
            icon: Icons.people_outline_rounded,
            title: 'Pelanggan & CRM',
            subtitle: 'Daftar pelanggan loyalitas dan riwayat pesanan',
            builder: _buildCustomers,
          ),
          const MoreEntry(
            category: 'Perangkat Keras',
            icon: Icons.print_rounded,
            title: 'Printer Struk & Hardware Kasir',
            subtitle: 'Konfigurasi Bluetooth, LAN port 9100, & laci kas',
            builder: _buildPrinter,
          ),
          const MoreEntry(
            category: 'Bisnis & Lisensi',
            icon: Icons.workspace_premium_rounded,
            title: 'Paket & Langganan Toko',
            subtitle: 'Status paket Velora Pro, kuota outlet, & masa aktif',
            builder: _buildSubscription,
          ),
          const MoreEntry(
            category: 'Pengaturan & Akun',
            icon: Icons.settings_outlined,
            title: 'Pengaturan Akun & Keamanan',
            subtitle: 'Profil pengguna, PIN 4 digit kasir, & sesi login',
            builder: _buildSettings,
          ),
        ];

      case BusinessVertical.retail:
      default:
        return [
          const MoreEntry(
            category: 'Analitik & CRM',
            icon: Icons.dashboard_rounded,
            title: 'Dashboard & Analitik Penjualan',
            subtitle: 'Ringkasan omzet harian, status penjualan, & tren',
            builder: _buildDashboard,
          ),
          const MoreEntry(
            category: 'Analitik & CRM',
            icon: Icons.people_outline_rounded,
            title: 'Pelanggan & CRM',
            subtitle: 'Member, poin loyalitas, riwayat, dan buku kasbon',
            builder: _buildCustomers,
          ),
          const MoreEntry(
            category: 'Operasional Toko',
            icon: Icons.assignment_return_outlined,
            title: 'Retur Penjualan & Faktur',
            subtitle: 'Retur barang invoice transaksi atau ke supplier',
            builder: _buildReturn,
          ),
          const MoreEntry(
            category: 'Operasional Toko',
            icon: Icons.payments_outlined,
            title: 'Pengeluaran Kasir (Petty Cash)',
            subtitle: 'Pencatatan kas operasional toko harian',
            builder: _buildExpenses,
          ),
          const MoreEntry(
            category: 'Perangkat Keras',
            icon: Icons.print_rounded,
            title: 'Printer Struk & Hardware Kasir',
            subtitle: 'Konfigurasi Bluetooth, LAN port 9100, & laci kas',
            builder: _buildPrinter,
          ),
          const MoreEntry(
            category: 'Bisnis & Lisensi',
            icon: Icons.workspace_premium_rounded,
            title: 'Paket & Langganan Toko',
            subtitle: 'Status paket Velora Pro, kuota outlet, & masa aktif',
            builder: _buildSubscription,
          ),
          const MoreEntry(
            category: 'Pengaturan & Akun',
            icon: Icons.settings_outlined,
            title: 'Pengaturan Akun & Keamanan',
            subtitle: 'Profil pengguna, PIN 4 digit kasir, & sesi login',
            builder: _buildSettings,
          ),
        ];
    }
  }

  static Widget _buildDashboard(BuildContext _) => const DashboardScreen();
  static Widget _buildCustomerHome(BuildContext _) => const CustomerHomeScreen();
  static Widget _buildSplitBill(BuildContext _) => const FnbPaymentSplitScreen();
  static Widget _buildCustomers(BuildContext _) => const CustomersScreen();
  static Widget _buildReturn(BuildContext _) => const ReturnScreen();
  static Widget _buildExpenses(BuildContext _) => const ExpensesScreen();
  static Widget _buildPrinter(BuildContext _) => const PrinterSettingsScreen();
  static Widget _buildSubscription(BuildContext _) => const SubscriptionScreen();
  static Widget _buildSettings(BuildContext _) => const SettingsScreen();
}
