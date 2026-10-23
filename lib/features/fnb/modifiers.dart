import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/safe_json.dart';

class ModifierOption {
  const ModifierOption({required this.id, required this.name, required this.price});

  final String id;
  final String name;

  /// Harga tambahan per item (sudah memakai harga khusus cabang bila ada).
  final num price;

  factory ModifierOption.fromJson(Map<String, dynamic> json) {
    final priceVal = json.getNum('effective_price',
        fallback: json.getNum('additional_price',
            fallback: json.getNum('price', fallback: 0)));
    return ModifierOption(
      id: json.getString('id'),
      name: json.getString('name', fallback: '-'),
      price: priceVal,
    );
  }
}

class ModifierGroup {
  const ModifierGroup({
    required this.id,
    required this.name,
    required this.isRequired,
    required this.minSelect,
    required this.maxSelect,
    required this.categories,
    this.categoryIds = const {},
    required this.options,
  });

  final String id;
  final String name;
  final bool isRequired;
  final int minSelect;
  final int maxSelect;

  /// Nama kategori produk tempat grup ini berlaku. Kosong = berlaku untuk semua.
  final Set<String> categories;

  /// ID kategori produk tempat grup ini berlaku dari backend API.
  final Set<String> categoryIds;

  final List<ModifierOption> options;

  bool get isSingleChoice => maxSelect <= 1;

  /// Jumlah minimal pilihan: grup wajib minimal memilih satu.
  int get requiredCount => minSelect > 0 ? minSelect : (isRequired ? 1 : 0);

  bool appliesTo(String category, [String? categoryId]) {
    // Jika tidak ada batasan kategori, grup modifier berlaku untuk semua produk
    if (categories.isEmpty && categoryIds.isEmpty) return true;

    if (categoryId != null && categoryId.isNotEmpty && categoryIds.contains(categoryId)) {
      return true;
    }

    final clean = sanitizeDisplayName(category).toLowerCase().trim();
    if (categories.any((c) => c.toLowerCase().trim() == clean)) {
      return true;
    }

    return false;
  }

  factory ModifierGroup.fromJson(Map<String, dynamic> json) {
    final max = json.getInt('max_select', fallback: 1);
    final rawCatIds = json['category_ids'] ?? json['categories'];
    final Set<String> catIds = {};
    if (rawCatIds is List) {
      for (final e in rawCatIds) {
        if (e is num || (e is String && int.tryParse(e) != null)) {
          catIds.add(e.toString());
        }
      }
    }

    return ModifierGroup(
      id: json.getString('id'),
      name: json.getString('name', fallback: '-'),
      isRequired: json.getBool('is_required'),
      minSelect: json.getInt('min_select'),
      maxSelect: max < 1 ? 1 : max,
      categoryIds: catIds,
      categories: json
          .getList<String>('categories', (e) {
            if (e is Map) {
              return sanitizeDisplayName(e['name'] ?? e['category_name'] ?? e);
            }
            if (e is String && int.tryParse(e) == null) {
              return sanitizeDisplayName(e);
            }
            return '';
          })
          .where((n) => n.isNotEmpty)
          .toSet(),
      options: json
          .getList<ModifierOption>('options', (e) {
            if (e is! Map) throw const FormatException('not a map');
            final m = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e);
            if (m.containsKey('is_active') && !m.getBool('is_active', fallback: true)) {
              throw const FormatException('inactive option');
            }
            return ModifierOption.fromJson(m);
          }),
    );
  }
}

class ModifierService {
  static final ModifierService instance = ModifierService._();
  ModifierService._();

  Future<List<ModifierGroup>> groups() async {
    try {
      final id = SessionStorage.instance.getLocationId();
      final q = {if (id != null && id.isNotEmpty) 'location_id': id};
      dynamic body;
      try {
        final res = await ApiClient.instance.dio.get('/v1/pos/modifiers', queryParameters: q);
        body = res.data;
      } catch (_) {
        final res = await ApiClient.instance.dio.get('/cafe/menu/modifiers', queryParameters: q);
        body = res.data;
      }
      final raw = body is Map<String, dynamic> ? body['data'] : body;
      if (raw is! List) return const [];
      return [
        for (final e in raw)
          if (e is Map<String, dynamic>) ModifierGroup.fromJson(e),
      ].where((g) => g.options.isNotEmpty).toList();
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}
