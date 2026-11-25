/// Kumpulan ekspresi reguler (RegExp) terpusat, pre-compiled, dan anti-crash.
/// Mencegah kompilasi berulang RegExp(...) saat pengetikan keyboard atau perenderan frame,
/// serta melindungi aplikasi dari FormatException saat menangani input null / karakter liar.
abstract final class AppRegex {
  /// Karakter selain angka
  static final RegExp nonDigits = RegExp(r'\D');

  /// Hanya angka (0-9) dari awal hingga akhir
  static final RegExp digitsOnly = RegExp(r'^\d+$');

  /// Spasi tunggal maupun beruntun (termasuk tab dan newline)
  static final RegExp whitespace = RegExp(r'\s+');

  /// Prefix tanda pagar '#' pada awal string tiket/invoice
  static final RegExp hashPrefix = RegExp(r'^#');

  /// Garis miring di awal string URL/path
  static final RegExp leadingSlashes = RegExp(r'^/+');

  /// Format nomor handphone Indonesia (+62, 62, atau 08...)
  static final RegExp indonesianPhone = RegExp(r'^(?:\+62|62|0)8[0-9]{8,12}$');

  /// Format email standar internasional (RFC-5322 compliant)
  static final RegExp email = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
  );

  /// Kode / nomor meja kafe (misal: "01", "A2", "Meja 10")
  static final RegExp tableCode = RegExp(r'^[a-zA-Z]?\d+$');

  /// Pola pencarian kata kunci multi-token
  static final RegExp searchTokens = RegExp(r'\s+');
}

/// Ekstensi string yang aman dari null (*null-safe*) dan anti-crash
extension SafeStringRegexExtension on String? {
  /// Mengambil hanya digit angka (0-9) dari string.
  /// Contoh: "Rp 50.000,00" -> "5000000" (atau gunakan CurrencyFormatter.parse untuk uang)
  String cleanDigits() {
    if (this == null) return '';
    return this!.replaceAll(AppRegex.nonDigits, '');
  }

  /// Memeriksa apakah teks hanya terdiri dari angka (1 atau lebih digit)
  bool get isDigitsOnly {
    if (this == null || this!.isEmpty) return false;
    return AppRegex.digitsOnly.hasMatch(this!.trim());
  }

  /// Memeriksa apakah format surel valid
  bool get isValidEmail {
    if (this == null || this!.trim().isEmpty) return false;
    return AppRegex.email.hasMatch(this!.trim());
  }

  /// Memeriksa apakah format nomor handphone Indonesia valid
  bool get isValidPhone {
    if (this == null || this!.trim().isEmpty) return false;
    final digits = cleanDigits();
    return digits.length >= 10 && digits.length <= 15 && AppRegex.indonesianPhone.hasMatch(this!.trim());
  }

  /// Memotong prefix '#' di awal nomor nota/pesanan
  String stripHashPrefix() {
    if (this == null) return '';
    return this!.trim().replaceFirst(AppRegex.hashPrefix, '');
  }

  /// Memotong garis miring di awal path URL
  String stripLeadingSlashes() {
    if (this == null) return '';
    return this!.trim().replaceFirst(AppRegex.leadingSlashes, '');
  }

  /// Memecah teks pencarian menjadi token kata bersih
  List<String> toSearchTokens() {
    if (this == null || this!.trim().isEmpty) return const [];
    return this!.trim().toLowerCase().split(AppRegex.whitespace).where((t) => t.isNotEmpty).toList();
  }
}
