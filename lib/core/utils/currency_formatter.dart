import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final _numberFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '',
    decimalDigits: 0,
  );

  static final RegExp _nonNumeric = RegExp(r'[^\d.,]');

  /// Format angka ke Rupiah dengan simbol ("Rp 50.000")
  static String format(num? amount) {
    if (amount == null) return 'Rp 0';
    return _formatter.format(amount);
  }

  static String formatRupiah(num? amount) => format(amount);

  /// Format angka tanpa simbol ("50.000")
  static String formatNumber(num? amount) {
    if (amount == null) return '0';
    return _numberFormatter.format(amount).trim();
  }

  /// Format dengan prefix kustom, e.g. "+Rp 50.000" atau "-Rp 10.000"
  static String formatWithPrefix(num? amount, {String prefix = 'Rp '}) {
    if (amount == null) return '${prefix}0';
    return '$prefix${formatNumber(amount)}';
  }

  /// Format kompak ("1.5 jt", "50 rb")
  static String formatCompact(num? amount) {
    if (amount == null) return '0';
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} jt';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} rb';
    }
    return amount.toString();
  }

  /// Mengonversi teks uang/angka (misal: "Rp 50.000", "50000", "Rp 1.500.000,00", "-Rp 10.000")
  /// menjadi [num] secara aman tanpa crash bila input null atau teks acak.
  static num parse(String? text, {num fallback = 0}) {
    if (text == null) return fallback;
    var clean = text.trim();
    if (clean.isEmpty) return fallback;

    // Cek tanda minus / negatif
    final isNegative = clean.startsWith('-') || (clean.startsWith('(') && clean.endsWith(')'));

    // Hapus simbol mata uang dan karakter non-angka/non-pemisah
    clean = clean.replaceAll(_nonNumeric, '');
    if (clean.isEmpty) return fallback;

    // Deteksi koma/titik desimal Indonesia vs Internasional
    if (clean.contains('.') && clean.contains(',')) {
      final lastDot = clean.lastIndexOf('.');
      final lastComma = clean.lastIndexOf(',');
      if (lastComma > lastDot) {
        // Format ID: titik ribuan, koma desimal
        clean = clean.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // Format US: koma ribuan, titik desimal
        clean = clean.replaceAll(',', '');
      }
    } else if (clean.contains(',')) {
      final parts = clean.split(',');
      if (parts.length == 2 && parts[1].length <= 2) {
        // Desimal, e.g. 50,00 atau 12500,5
        clean = '${parts[0]}.${parts[1]}';
      } else {
        clean = clean.replaceAll(',', '');
      }
    } else if (clean.contains('.')) {
      final parts = clean.split('.');
      if (parts.length == 2 && parts[1].length == 3) {
        clean = clean.replaceAll('.', '');
      } else if (parts.length > 2) {
        clean = clean.replaceAll('.', '');
      }
    }

    final parsed = num.tryParse(clean);
    if (parsed == null) return fallback;
    return isNegative ? -parsed : parsed;
  }

  /// Mengonversi teks uang ke [int] bulat secara aman
  static int parseInt(String? text, {int fallback = 0}) {
    return parse(text, fallback: fallback).round();
  }
}

/// Ekstensi mudah pada [num] untuk memformat mata uang langsung dari variabel angka
extension CurrencyNumExtension on num? {
  String toRupiah() => CurrencyFormatter.format(this);
  String toFormattedNumber() => CurrencyFormatter.formatNumber(this);
  String toRupiahCompact() => CurrencyFormatter.formatCompact(this);
}

/// Ekstensi mudah pada [String?] untuk parsing uang kembali ke angka numerik
extension CurrencyStringExtension on String? {
  num parseRupiah({num fallback = 0}) => CurrencyFormatter.parse(this, fallback: fallback);
  int parseRupiahInt({int fallback = 0}) => CurrencyFormatter.parseInt(this, fallback: fallback);
}
