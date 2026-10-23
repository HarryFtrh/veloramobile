import 'package:intl/date_symbol_data_local.dart';

/// Locale tanggal yang dipakai seluruh aplikasi.
const appLocale = 'id_ID';

/// Wajib dipanggil sebelum `runApp`; tanpa ini `DateFormat(..., 'id_ID')`
/// melempar `LocaleDataException`.
Future<void> initAppLocale() => initializeDateFormatting(appLocale);
