class DateTimeFormatter {
  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  static const List<String> _fullMonthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  /// Format waktu 24-jam: "14:05"
  static String time(DateTime? dt) {
    if (dt == null) return '-';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Format waktu dengan detik: "14:05:30"
  static String timeWithSeconds(DateTime? dt) {
    if (dt == null) return '-';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Format tanggal pendek Indonesia: "11 Nov 2026"
  static String date(DateTime? dt) {
    if (dt == null) return '-';
    final monthIdx = (dt.month >= 1 && dt.month <= 12) ? dt.month - 1 : 0;
    return '${dt.day} ${_monthNames[monthIdx]} ${dt.year}';
  }

  /// Format tanggal lengkap Indonesia: "11 November 2026"
  static String fullDate(DateTime? dt) {
    if (dt == null) return '-';
    final monthIdx = (dt.month >= 1 && dt.month <= 12) ? dt.month - 1 : 0;
    return '${dt.day} ${_fullMonthNames[monthIdx]} ${dt.year}';
  }

  /// Format tanggal numerik: "11/11/2026" atau "11/11" (bila includeYear = false)
  static String numericDate(DateTime? dt, {bool includeYear = true}) {
    if (dt == null) return '-';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return includeYear ? '$d/$m/${dt.year}' : '$d/$m';
  }

  /// Format tanggal dan waktu lengkap: "11 Nov 2026, 14:05 WIB"
  static String dateTime(DateTime? dt, {bool withWib = true}) {
    if (dt == null) return '-';
    final d = date(dt);
    final t = time(dt);
    final suffix = withWib ? ' WIB' : '';
    return '$d, $t$suffix';
  }

  /// Format tanggal dan jam numerik: "11/11/2026 14:05" atau "11/11 14:05"
  static String numericDateTime(DateTime? dt, {bool includeYear = true}) {
    if (dt == null) return '-';
    return '${numericDate(dt, includeYear: includeYear)} ${time(dt)}';
  }

  /// Format rentang waktu: "11/11/2026 08:00 - 11/11/2026 17:00"
  static String range(DateTime? start, DateTime? end) {
    if (start == null && end == null) return '-';
    if (start != null && end == null) return 'Buka: ${numericDateTime(start)}';
    return '${numericDateTime(start)} - ${numericDateTime(end)}';
  }

  /// Format deskriptif relatif: "Hari ini, 14:05" atau "Kemarin, 14:05" atau "11 Nov 2026, 14:05"
  static String relative(DateTime? dt) {
    if (dt == null) return '-';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diffDays = today.difference(target).inDays;

    if (diffDays == 0) {
      return 'Hari ini, ${time(dt)}';
    } else if (diffDays == 1) {
      return 'Kemarin, ${time(dt)}';
    } else {
      return dateTime(dt, withWib: false);
    }
  }
}

/// Ekstensi praktis pada [DateTime]
extension DateTimeExtension on DateTime? {
  String toTimeString() => DateTimeFormatter.time(this);
  String toDateString() => DateTimeFormatter.date(this);
  String toNumericDateString({bool includeYear = true}) => DateTimeFormatter.numericDate(this, includeYear: includeYear);
  String toDateTimeString({bool withWib = true}) => DateTimeFormatter.dateTime(this, withWib: withWib);
  String toNumericDateTimeString({bool includeYear = true}) => DateTimeFormatter.numericDateTime(this, includeYear: includeYear);
  String toRelativeString() => DateTimeFormatter.relative(this);
}
