/// Membersihkan string display name / kategori / label dari stringified Map atau JSON mentah
/// Contoh: "{id: 1, name: Coffee}" -> "Coffee"
///         "{\"id\": 1, \"name\": \"Coffee\"}" -> "Coffee"
String sanitizeDisplayName(dynamic input) {
  if (input == null) return '';
  if (input is Map) {
    final val = input['name'] ??
        input['category_name'] ??
        input['title'] ??
        input['label'] ??
        input['name_main'] ??
        input['table_number'] ??
        input['id'];
    if (val != null) return sanitizeDisplayName(val);
    return '';
  }
  final str = input.toString().trim();
  if (str.isEmpty || str.toLowerCase() == 'undefined' || str.toLowerCase() == 'null') {
    return '';
  }
  if (str.startsWith('{') && str.endsWith('}')) {
    // Coba ekstrak name
    final nameMatch = RegExp(r'''['"]?(?:name|category_name|title|label|name_main)['"]?\s*[:=]\s*['"]?([^,}\"\']+)['"]?''').firstMatch(str);
    if (nameMatch != null && nameMatch.group(1) != null) {
      return nameMatch.group(1)!.trim();
    }
    // Coba ekstrak table_number / id
    final idMatch = RegExp(r'''['"]?(?:table_number|number|id)['"]?\s*[:=]\s*['"]?([^,}\"\']+)['"]?''').firstMatch(str);
    if (idMatch != null && idMatch.group(1) != null) {
      return idMatch.group(1)!.trim();
    }
  }
  return str;
}

/// Utility extension for 100% crash-proof JSON parsing.
/// Guarantees that schema drift, null values, or unexpected types from API
/// will NEVER throw a runtime TypeError or crash the Flutter application.
extension SafeMap on Map<String, dynamic>? {
  /// Safely extracts a String, converting numbers or booleans if necessary.
  String getString(String key, {String fallback = ''}) {
    if (this == null) return fallback;
    final val = this![key];
    if (val == null) return fallback;
    if (val is Map) {
      final sanitized = sanitizeDisplayName(val);
      return sanitized.isNotEmpty ? sanitized : fallback;
    }
    final sanitized = sanitizeDisplayName(val);
    if (sanitized.isEmpty) return fallback;
    return sanitized;
  }

  /// Safely extracts an integer, parsing string numbers if necessary.
  int getInt(String key, {int fallback = 0}) {
    if (this == null) return fallback;
    final val = this![key];
    if (val == null) return fallback;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) {
      final str = val.trim().toLowerCase();
      if (str.isEmpty || str == 'undefined' || str == 'null') return fallback;
      return int.tryParse(val) ?? fallback;
    }
    return fallback;
  }

  /// Safely extracts a double/num, parsing strings if necessary.
  double getDouble(String key, {double fallback = 0.0}) {
    if (this == null) return fallback;
    final val = this![key];
    if (val == null) return fallback;
    if (val is double) return val;
    if (val is num) return val.toDouble();
    if (val is String) {
      final str = val.trim().toLowerCase();
      if (str.isEmpty || str == 'undefined' || str == 'null') return fallback;
      return double.tryParse(val) ?? fallback;
    }
    return fallback;
  }

  /// Safely extracts a general number (int/double).
  num getNum(String key, {num fallback = 0}) {
    return getDouble(key, fallback: fallback.toDouble());
  }

  /// Safely extracts a boolean, parsing '1', 1, 'true', 'yes' gracefully.
  bool getBool(String key, {bool fallback = false}) {
    if (this == null) return fallback;
    final val = this![key];
    if (val == null) return fallback;
    if (val is bool) return val;
    if (val is int || val is num) return val == 1;
    if (val is String) {
      final lower = val.toLowerCase().trim();
      return lower == 'true' || lower == '1' || lower == 'yes';
    }
    return fallback;
  }

  /// Safely extracts a nested Map without casting exceptions.
  Map<String, dynamic> getMap(String key) {
    if (this == null) return <String, dynamic>{};
    final val = this![key];
    if (val is Map<String, dynamic>) return val;
    if (val is Map) {
      return val.map((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{};
  }

  /// Safely extracts a list with element-level error suppression.
  List<T> getList<T>(String key, T Function(dynamic item) mapper) {
    if (this == null) return <T>[];
    final val = this![key];
    if (val is List) {
      final results = <T>[];
      for (final item in val) {
        try {
          final mapped = mapper(item);
          results.add(mapped);
        } catch (_) {
          // Skip corrupted individual items rather than crashing the whole list
        }
      }
      return results;
    }
    return <T>[];
  }
}
