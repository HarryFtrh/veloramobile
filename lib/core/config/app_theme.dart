import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design/tokens.dart';
import 'app_config.dart';

class AppTheme {
  // ── Konstanta lama (tema gelap) ─────────────────────────────────────────
  // Masih dipakai layar yang belum dimigrasi ke `context.palette`.
  // Hapus setelah semua layar pindah.
  static const Color background = Color(0xFF090A0F);
  static const Color surface = Color(0xFF131722);
  static const Color surfaceLight = Color(0xFF1A1F2E);
  static const Color border = Color(0xFF23293B);
  static const Color borderSubtle = Color(0xFF1B202E);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);

  static Color getAccentColor(AppFlavor flavor) {
    switch (flavor) {
      case AppFlavor.fnb:
      case AppFlavor.customer:
        return const Color(0xFF7A431D);
      case AppFlavor.pharmacy:
        return const Color(0xFF0F9D6E);
      case AppFlavor.sales:
        return const Color(0xFF4F46E5);
      case AppFlavor.marketplace:
        return const Color(0xFF0284C7);
    }
  }

  /// Tema baru. Satu aksen per flavor, permukaan solid, tanpa blur/gradient.
  static ThemeData build(AppFlavor flavor, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final isWarm = (flavor == AppFlavor.fnb || flavor == AppFlavor.customer) && !isDark;
    final palette = isDark ? AppPalette.dark : (isWarm ? AppPalette.warm : AppPalette.light);
    final accent = isWarm ? palette.primary : getAccentColor(flavor);
    final onAccent = accent.computeLuminance() > 0.4 ? Colors.black : Colors.white;
    final buttonShape = isWarm ? const StadiumBorder() : RoundedRectangleBorder(borderRadius: Corner.medium);
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    final fontFamily = GoogleFonts.plusJakartaSans().fontFamily;
    final textTheme = base.textTheme.apply(
      fontFamily: fontFamily,
      bodyColor: palette.textPrimary,
      displayColor: palette.textPrimary,
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: Corner.medium,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: palette.canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: brightness,
      ).copyWith(
        primary: palette.primary,
        secondary: palette.secondary,
        tertiary: palette.tertiary,
        onPrimary: onAccent,
        surface: palette.surface,
        onSurface: palette.textPrimary,
        outline: palette.line,
        error: palette.danger,
      ),
      extensions: [palette],
      dividerTheme: DividerThemeData(color: palette.line, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: palette.canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: palette.textPrimary,
        titleTextStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: Corner.medium,
          side: BorderSide(color: palette.line),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: accent,
          foregroundColor: onAccent,
          minimumSize: const Size(64, 48),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          shape: buttonShape,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          minimumSize: const Size(64, 44),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.textPrimary,
          minimumSize: const Size(64, 48),
          side: BorderSide(color: palette.line),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          shape: buttonShape,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isWarm ? palette.surfaceMuted : palette.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.md),
        hintStyle: TextStyle(color: palette.textSecondary, fontSize: 14),
        border: inputBorder(isWarm ? Colors.transparent : palette.line),
        enabledBorder: inputBorder(isWarm ? Colors.transparent : palette.line),
        focusedBorder: inputBorder(accent, 1.5),
        errorBorder: inputBorder(palette.danger),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 0,
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: isWarm ? palette.primary : accent.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: isWarm ? Colors.white : accent);
          }
          return IconThemeData(color: palette.textSecondary);
        }),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: Corner.small),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Corner.lg)),
        ),
      ),
    );
  }

  static ThemeData getLinearDarkTheme(AppFlavor flavor) =>
      build(flavor, Brightness.dark);

  // Layar lama masih dirancang untuk tema gelap. Setelah migrasi selesai,
  // ganti ke ThemeMode.system di MaterialApp dan hapus method ini.
  static ThemeData getTheme(AppFlavor flavor, {bool isDark = true}) =>
      build(flavor, isDark ? Brightness.dark : Brightness.light);
}
