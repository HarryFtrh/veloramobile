import 'package:flutter/material.dart';

/// Skala jarak dan radius yang dipakai seluruh aplikasi.
/// Pakai konstanta ini, jangan menulis angka langsung di widget.
abstract final class Gap {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class Corner {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;

  static const double pill = 999;

  static BorderRadius get small => BorderRadius.circular(sm);
  static BorderRadius get medium => BorderRadius.circular(md);
  static BorderRadius get large => BorderRadius.circular(lg);
  static BorderRadius get full => BorderRadius.circular(pill);
}

/// Token warna paten "Warm Roasted Modernity" sesuai gambar referensi.
abstract final class WarmPalette {
  static const Color primary = Color(0xFF7A431D); // Rich Espresso
  static const Color secondary = Color(0xFFD9822B); // Warm Ochre
  static const Color tertiary = Color(0xFF4D6B53); // Forest Sage
  static const Color canvas = Color(0xFFFBF7F2); // Creamy Oat
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF3EDE2);
  static const Color line = Color(0xFFE8DDD1);
  static const Color textPrimary = Color(0xFF1E1510);
  static const Color textSecondary = Color(0xFF70655E);
  static const Color textTertiary = Color(0xFFA09389);
  static const Color danger = Color(0xFFBA1A1A);

  /// Alias semantik untuk surfaceMuted dan line
  static const Color surfaceDim = surfaceMuted;
  static const Color border = line;
}

/// Warna semantik di luar `ColorScheme` (status, teks sekunder, dsb).
/// Diakses lewat `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.line,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color canvas;
  final Color surface;
  final Color surfaceMuted;
  final Color line;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  /// Alias semantik untuk `line` (border/divider).
  Color get border => line;

  /// Alias semantik untuk `surfaceMuted` (permukaan redup).
  Color get surfaceDim => surfaceMuted;

  static const light = AppPalette(
    primary: Color(0xFF7A431D),
    secondary: Color(0xFFD9822B),
    tertiary: Color(0xFF4D6B53),
    canvas: Color(0xFFF6F7F9),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF0F2F5),
    line: Color(0xFFE3E6EB),
    textPrimary: Color(0xFF14181F),
    textSecondary: Color(0xFF566070),
    textTertiary: Color(0xFF8B94A3),
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    danger: Color(0xFFDC2626),
    info: Color(0xFF2563EB),
  );

  /// "Warm Roasted Modernity" — khusus F&B / Cafe (mode terang).
  /// Sesuai spesifikasi palet warna Velora F&B:
  /// Primary #7A431D, Secondary #D9822B, Tertiary #4D6B53, Neutral #FBF7F2.
  static const warm = AppPalette(
    primary: Color(0xFF7A431D),
    secondary: Color(0xFFD9822B),
    tertiary: Color(0xFF4D6B53),
    canvas: Color(0xFFFBF7F2),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF3EDE2),
    line: Color(0xFFE8DDD1),
    textPrimary: Color(0xFF1E1510),
    textSecondary: Color(0xFF70655E),
    textTertiary: Color(0xFFA09389),
    success: Color(0xFF4D6B53),
    warning: Color(0xFFD9822B),
    danger: Color(0xFFBA1A1A),
    info: Color(0xFF7A431D),
  );

  static const dark = AppPalette(
    primary: Color(0xFFFFDBC8),
    secondary: Color(0xFFFFB77B),
    tertiary: Color(0xFFA2D3AC),
    canvas: Color(0xFF0E1116),
    surface: Color(0xFF171B22),
    surfaceMuted: Color(0xFF1F242D),
    line: Color(0xFF2A303B),
    textPrimary: Color(0xFFF2F4F7),
    textSecondary: Color(0xFFA3ACBA),
    textTertiary: Color(0xFF6F7888),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    info: Color(0xFF60A5FA),
  );

  @override
  AppPalette copyWith({
    Color? primary,
    Color? secondary,
    Color? tertiary,
    Color? canvas,
    Color? surface,
    Color? surfaceMuted,
    Color? line,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
  }) {
    return AppPalette(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      line: line ?? this.line,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      line: Color.lerp(line, other.line, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

extension PaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

abstract final class AppBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double compactHeight = 500;
}

abstract final class ModalConstraints {
  static const double dialogMaxWidth = 440;
  static const double sheetMaxWidth = 540;
  static const double drawerMaxWidth = 600;
  static const double contentMaxWidth = 860;
}

extension ResponsiveContext on BuildContext {
  /// Ukuran layar saat ini
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  /// Orientasi layar
  Orientation get screenOrientation => MediaQuery.orientationOf(this);
  bool get isLandscape => screenOrientation == Orientation.landscape;

  /// Perangkat smartphone (mobile layout).
  /// Mendeteksi secara akurat di portrait (width < 600) maupun smartphone yang diputar landscape (height < 500).
  bool get isMobile => screenWidth < AppBreakpoints.mobile || screenHeight < AppBreakpoints.compactHeight;

  /// Tablet / POS terminal layar sedang (600px - 1024px)
  bool get isTablet => !isMobile && screenWidth < AppBreakpoints.tablet;

  /// Layar desktop / register lebar (>= 1024px)
  bool get isDesktop => screenWidth >= AppBreakpoints.tablet;

  /// Batasan dinamis lebar dialog modal: full width di HP sempit, dibatasi pada tablet
  double get dialogMaxWidth => isMobile ? double.infinity : ModalConstraints.dialogMaxWidth;

  /// Batasan dinamis lebar modal sheet: full width di HP sempit, dibatasi pada tablet
  double get sheetMaxWidth => isMobile ? double.infinity : ModalConstraints.sheetMaxWidth;

  /// Helper untuk memilih nilai berdasarkan breakpoint
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }
}
