import 'package:material_ui/material_ui.dart';

/// Palet warna terpusat untuk modul Farmasi & Klinik ("Clinical Precision").
/// Menghindari deklarasi ulang literal `Color(0xFF...)` di setiap layar/widget.
abstract final class PharmacyColors {
  static const Color primary = Color(0xFF059669);
  static const Color primaryDark = Color(0xFF047857);
  static const Color tealAccent = Color(0xFF0D9488);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF6D7A72);
  static const Color slateMuted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color surfaceTint = Color(0xFFF8FAFC);
  static const Color surfaceSubtle = Color(0xFFF1F5F9);
  static const Color canvas = Color(0xFFFAF8FF);
  static const Color danger = Color(0xFFBA1A1A);
  static const Color dangerBright = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);
}
