import 'package:flutter/material.dart';
import '../../core/config/business_vertical.dart';
import '../finance/expenses_screen.dart';
import '../finance/return_screen.dart';
import '../fnb/fnb_payment_split_screen.dart';
import '../fnb_customer/customer_home_screen.dart';
import '../settings/settings_screen.dart';
import '../shared_pos/printer_settings_screen.dart';
import '../subscription/subscription_screen.dart';
import 'more_entry.dart';

/// Centralized Factory for MoreScreen menu entries per business vertical.
/// Menyediakan modul sekunder & operasional pendukung (tanpa menduplikasi tab utama).
class MoreMenuFactory {
  static List<MoreEntry> entriesFor(BusinessVertical vertical) {
    switch (vertical) {
      case BusinessVertical.fnb:
        return [
          // 1. Operasional Tambahan Kasir
          const MoreEntry(
            category: 'Operasional Kasir',
            icon: Icons.coffee_rounded,
            iconColor: Color(0xFF059669),
            iconBg: Color(0xFFD1FAE5),
            badge: 'Self-Order',
            badgeColor: Color(0xFFD1FAE5),
            badgeTextColor: Color(0xFF047857),
            title: 'Mode Pelanggan (Customer Self-Order)',
            subtitle: 'Layar eksplorasi menu meja & live tracking pesanan',
            builder: _buildCustomerHome,
          ),
          const MoreEntry(
            category: 'Operasional Kasir',
            icon: Icons.call_split_rounded,
            iconColor: Color(0xFF0D9488),
            iconBg: Color(0xFFCCFBF1),
            badge: 'Numpad POS',
            badgeColor: Color(0xFFCCFBF1),
            badgeTextColor: Color(0xFF0F766E),
            title: 'Kasir Split Bill & Pecahan Uang',
            subtitle: 'Pembayaran bagi tagihan, numpad, & kalkulator kembalian',
            builder: _buildSplitBill,
          ),
          const MoreEntry(
            category: 'Operasional Kasir',
            icon: Icons.payments_outlined,
            iconColor: Color(0xFFD97706),
            iconBg: Color(0xFFFEF3C7),
            badge: 'Petty Cash',
            badgeColor: Color(0xFFFEF3C7),
            badgeTextColor: Color(0xFFB45309),
            title: 'Pengeluaran Kasir (Petty Cash)',
            subtitle: 'Pencatatan kas kecil & biaya operasional toko harian',
            builder: _buildExpenses,
          ),

          // 2. Perangkat Keras & Hardware
          const MoreEntry(
            category: 'Perangkat Keras',
            icon: Icons.print_rounded,
            iconColor: Color(0xFF4338CA),
            iconBg: Color(0xFFE0E7FF),
            badge: 'Bluetooth / LAN',
            badgeColor: Color(0xFFE0E7FF),
            badgeTextColor: Color(0xFF3730A3),
            title: 'Printer Struk & Hardware Kasir',
            subtitle: 'Konfigurasi Bluetooth, LAN port 9100, & laci kas',
            builder: _buildPrinter,
          ),

          // 3. Bisnis & Lisensi
          const MoreEntry(
            category: 'Bisnis & Lisensi',
            icon: Icons.workspace_premium_rounded,
            iconColor: Color(0xFF7C3AED),
            iconBg: Color(0xFFEDE9FE),
            badge: 'Velora Pro',
            badgeColor: Color(0xFFEDE9FE),
            badgeTextColor: Color(0xFF6D28D9),
            title: 'Paket & Langganan Toko',
            subtitle: 'Status paket Velora Pro, kuota outlet, & masa aktif',
            builder: _buildSubscription,
          ),

          // 4. Pengaturan & Akun
          const MoreEntry(
            category: 'Pengaturan & Akun',
            icon: Icons.settings_outlined,
            iconColor: Color(0xFF334155),
            iconBg: Color(0xFFF1F5F9),
            badge: 'Keamanan',
            badgeColor: Color(0xFFF1F5F9),
            badgeTextColor: Color(0xFF475569),
            title: 'Pengaturan Akun & Keamanan',
            subtitle: 'Profil pengguna, PIN 4 digit kasir, & sesi login',
            builder: _buildSettings,
          ),
        ];

      case BusinessVertical.retail:
      default:
        return [
          // 1. Operasional Tambahan Toko
          const MoreEntry(
            category: 'Operasional Kasir',
            icon: Icons.assignment_return_outlined,
            iconColor: Color(0xFFE11D48),
            iconBg: Color(0xFFFFE4E6),
            badge: 'Retur Faktur',
            badgeColor: Color(0xFFFFE4E6),
            badgeTextColor: Color(0xFFBE123C),
            title: 'Retur Penjualan & Faktur',
            subtitle: 'Retur barang invoice transaksi atau ke supplier',
            builder: _buildReturn,
          ),
          const MoreEntry(
            category: 'Operasional Kasir',
            icon: Icons.payments_outlined,
            iconColor: Color(0xFFD97706),
            iconBg: Color(0xFFFEF3C7),
            badge: 'Petty Cash',
            badgeColor: Color(0xFFFEF3C7),
            badgeTextColor: Color(0xFFB45309),
            title: 'Pengeluaran Kasir (Petty Cash)',
            subtitle: 'Pencatatan kas operasional toko harian',
            builder: _buildExpenses,
          ),

          // 2. Perangkat Keras
          const MoreEntry(
            category: 'Perangkat Keras',
            icon: Icons.print_rounded,
            iconColor: Color(0xFF4338CA),
            iconBg: Color(0xFFE0E7FF),
            badge: 'Bluetooth / LAN',
            badgeColor: Color(0xFFE0E7FF),
            badgeTextColor: Color(0xFF3730A3),
            title: 'Printer Struk & Hardware Kasir',
            subtitle: 'Konfigurasi Bluetooth, LAN port 9100, & laci kas',
            builder: _buildPrinter,
          ),

          // 3. Bisnis & Lisensi
          const MoreEntry(
            category: 'Bisnis & Lisensi',
            icon: Icons.workspace_premium_rounded,
            iconColor: Color(0xFF7C3AED),
            iconBg: Color(0xFFEDE9FE),
            badge: 'Velora Pro',
            badgeColor: Color(0xFFEDE9FE),
            badgeTextColor: Color(0xFF6D28D9),
            title: 'Paket & Langganan Toko',
            subtitle: 'Status paket Velora Pro, kuota outlet, & masa aktif',
            builder: _buildSubscription,
          ),

          // 4. Pengaturan & Akun
          const MoreEntry(
            category: 'Pengaturan & Akun',
            icon: Icons.settings_outlined,
            iconColor: Color(0xFF334155),
            iconBg: Color(0xFFF1F5F9),
            badge: 'Keamanan',
            badgeColor: Color(0xFFF1F5F9),
            badgeTextColor: Color(0xFF475569),
            title: 'Pengaturan Akun & Keamanan',
            subtitle: 'Profil pengguna, PIN 4 digit kasir, & sesi login',
            builder: _buildSettings,
          ),
        ];
    }
  }

  static Widget _buildCustomerHome(BuildContext _) => const CustomerHomeScreen();
  static Widget _buildSplitBill(BuildContext _) => const FnbPaymentSplitScreen();
  static Widget _buildReturn(BuildContext _) => const ReturnScreen();
  static Widget _buildExpenses(BuildContext _) => const ExpensesScreen();
  static Widget _buildPrinter(BuildContext _) => const PrinterSettingsScreen();
  static Widget _buildSubscription(BuildContext _) => const SubscriptionScreen();
  static Widget _buildSettings(BuildContext _) => const SettingsScreen();
}
