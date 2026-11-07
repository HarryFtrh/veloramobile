import 'package:flutter/material.dart';
import '../../../core/utils/safe_json.dart';
import '../../fnb/modifiers.dart';

class PosProductBatch {
  final String id;
  final String batchNumber;
  final String expiryDate;
  final double stock;

  PosProductBatch({
    required this.id,
    required this.batchNumber,
    required this.expiryDate,
    required this.stock,
  });

  factory PosProductBatch.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return PosProductBatch(id: '', batchNumber: '-', expiryDate: '-', stock: 0);
    }
    String bNo = json.getString('batch_number');
    if (bNo.isEmpty || bNo == '-') bNo = json.getString('batch_no');
    if (bNo.isEmpty || bNo == '-') bNo = json.getString('no_batch');
    if (bNo.isEmpty || bNo == '-') bNo = json.getString('nomor_batch');
    if (bNo.isEmpty || bNo == '-') bNo = json.getString('kode_batch');
    if (bNo.isEmpty || bNo == '-') bNo = json.getString('lot_number');
    if (bNo.isEmpty || bNo == '-') bNo = json.getString('lot_no');
    if (bNo.isEmpty || bNo == '-') bNo = json.getString('batch', fallback: '-');

    String exp = json.getString('expiry_date');
    if (exp.isEmpty || exp == '-') exp = json.getString('exp_date');
    if (exp.isEmpty || exp == '-') exp = json.getString('expired_date');
    if (exp.isEmpty || exp == '-') exp = json.getString('kadaluwarsa');
    if (exp.isEmpty || exp == '-') exp = json.getString('tgl_kadaluarsa');
    if (exp.isEmpty || exp == '-') exp = json.getString('tanggal_kadaluwarsa');
    if (exp.isEmpty || exp == '-') exp = json.getString('expired_at');
    if (exp.isEmpty || exp == '-') exp = json.getString('exp', fallback: '-');

    return PosProductBatch(
      id: json.getString('id'),
      batchNumber: bNo,
      expiryDate: exp,
      stock: json.getDouble(
        'stock',
        fallback: json.getDouble(
          'stock_qty',
          fallback: json.getDouble('stok', fallback: json.getDouble('qty')),
        ),
      ),
    );
  }
}

class PosProductUnit {
  final String name;
  final num price;
  final num conversion;
  final String? barcode;
  final bool isDefault;

  PosProductUnit({
    required this.name,
    required this.price,
    this.conversion = 1,
    this.barcode,
    this.isDefault = false,
  });

  factory PosProductUnit.fromJson(Map<String, dynamic> json, {num defaultPrice = 0}) {
    String unitName = json.getString('name');
    if (unitName.isEmpty) unitName = json.getString('unit');
    if (unitName.isEmpty) unitName = json.getString('satuan');
    if (unitName.isEmpty) unitName = json.getString('uom');
    if (unitName.isEmpty) unitName = json.getString('unit_name');
    if (unitName.isEmpty) unitName = json.getString('packaging');
    if (unitName.isEmpty) unitName = json.getString('package_unit');
    if (unitName.isEmpty) unitName = 'PCS';

    num p = json.getDouble('price');
    if (p <= 0) p = json.getDouble('selling_price');
    if (p <= 0) p = json.getDouble('harga');
    if (p <= 0) p = json.getDouble('harga_jual');
    if (p <= 0) p = json.getDouble('unit_price');
    if (p <= 0) p = json.getDouble('amount');
    if (p <= 0) p = defaultPrice;

    num c = json.getDouble('conversion');
    if (c <= 0) c = json.getDouble('conversion_factor');
    if (c <= 0) c = json.getDouble('multiplier');
    if (c <= 0) c = json.getDouble('isi');
    if (c <= 0) c = json.getDouble('qty');
    if (c <= 0) c = json.getDouble('quantity');
    if (c <= 0) c = json.getDouble('qty_conversion');
    if (c <= 0) c = 1;

    return PosProductUnit(
      name: unitName.toUpperCase(),
      price: p,
      conversion: c,
      isDefault: json.getBool('is_default') || json.getBool('is_primary'),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'conversion': conversion,
        'is_default': isDefault,
      };
}

class PosProduct {
  final String id;
  final String name;
  final String category;
  final String? categoryId;
  final double price;
  final double stock;
  final String sku;
  final String barcode;
  final String? imageUrl;
  final String? tag;
  final String? description;
  final String? fungsi;
  final String? kandungan;
  final String? klasifikasi;
  final String? sediaan;
  final String? unit;
  final bool isPrescriptionOnly;
  final List<PosProductBatch> batches;
  final List<PosProductUnit> units;
  final List<ModifierGroup> modifierGroups;

  PosProduct({
    required this.id,
    required this.name,
    required this.category,
    this.categoryId,
    required this.price,
    required this.stock,
    required this.sku,
    required this.barcode,
    this.imageUrl,
    this.tag,
    this.description,
    this.fungsi,
    this.kandungan,
    this.klasifikasi,
    this.sediaan,
    this.unit,
    this.isPrescriptionOnly = false,
    this.batches = const [],
    this.units = const [],
    this.modifierGroups = const [],
  });

  PosProduct copyWith({
    String? id,
    String? name,
    String? category,
    String? categoryId,
    double? price,
    double? stock,
    String? sku,
    String? barcode,
    String? imageUrl,
    String? tag,
    String? description,
    String? fungsi,
    String? kandungan,
    String? klasifikasi,
    String? sediaan,
    String? unit,
    bool? isPrescriptionOnly,
    List<PosProductBatch>? batches,
    List<PosProductUnit>? units,
    List<ModifierGroup>? modifierGroups,
  }) =>
      PosProduct(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        categoryId: categoryId ?? this.categoryId,
        price: price ?? this.price,
        stock: stock ?? this.stock,
        sku: sku ?? this.sku,
        barcode: barcode ?? this.barcode,
        imageUrl: imageUrl ?? this.imageUrl,
        tag: tag ?? this.tag,
        description: description ?? this.description,
        fungsi: fungsi ?? this.fungsi,
        kandungan: kandungan ?? this.kandungan,
        klasifikasi: klasifikasi ?? this.klasifikasi,
        sediaan: sediaan ?? this.sediaan,
        unit: unit ?? this.unit,
        isPrescriptionOnly: isPrescriptionOnly ?? this.isPrescriptionOnly,
        batches: batches ?? this.batches,
        units: units ?? this.units,
        modifierGroups: modifierGroups ?? this.modifierGroups,
      );

  /// Cek kecocokan pencarian lokal (nama, SKU, barcode, golongan, kandungan, fungsi/indikasi, klasifikasi, sediaan)
  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        sku.toLowerCase().contains(q) ||
        barcode.toLowerCase().contains(q) ||
        category.toLowerCase().contains(q) ||
        (description ?? '').toLowerCase().contains(q) ||
        (fungsi ?? '').toLowerCase().contains(q) ||
        (kandungan ?? '').toLowerCase().contains(q) ||
        (klasifikasi ?? '').toLowerCase().contains(q) ||
        (sediaan ?? '').toLowerCase().contains(q) ||
        (tag ?? '').toLowerCase().contains(q);
  }

  /// Cek kecocokan jika salah satu variasi kata kunci / sinonim klinis cocok
  bool matchesAnyQuery(List<String> terms) {
    if (terms.isEmpty) return true;
    for (final term in terms) {
      if (matchesQuery(term)) return true;
    }
    return false;
  }

  IconData get defaultIcon {
    final lower = category.toLowerCase();
    if (lower.contains('kopi') || lower.contains('coffee') || lower.contains('espresso')) {
      return Icons.coffee_rounded;
    }
    if (lower.contains('pastry') || lower.contains('roti') || lower.contains('bakery')) {
      return Icons.bakery_dining_rounded;
    }
    if (lower.contains('makanan') || lower.contains('food')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('obat') || lower.contains('farmasi') || lower.contains('resep') || isPrescriptionOnly) {
      return Icons.medication_rounded;
    }
    return Icons.local_mall_outlined;
  }

  /// Menormalisasi dan memvalidasi URL gambar produk dari backend/S3.
  /// - Mengabaikan URL placeholder seperti `ui-avatars.com` agar komponen UI menampilkan ikon hanya jika gambar benar-benar tidak ada.
  static String? resolveImageUrl(String? raw) {
    if (raw == null) return null;
    var trimmed = raw.trim();
    if (trimmed.isEmpty ||
        trimmed == '-' ||
        trimmed.toLowerCase() == 'null' ||
        trimmed.toLowerCase() == 'undefined' ||
        trimmed.startsWith('/tmp/')) {
      return null;
    }

    final lower = trimmed.toLowerCase();
    if (lower.contains('ui-avatars.com') ||
        lower.contains('ui-avatars') ||
        lower.contains('placeholder') ||
        lower.contains('dummyimage') ||
        lower.contains('dicebear') ||
        lower.contains('default-avatar') ||
        lower.contains('no-image') ||
        lower.contains('no_image') ||
        lower.contains('default_drug')) {
      return null;
    }

    trimmed = trimmed.replaceAll('storage.veloratest.web.id', 'storage.velora.co.id');

    if (trimmed.startsWith('//')) {
      trimmed = 'https:$trimmed';
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      // Jika Storage::url() di backend menghasilkan https://velora.co.id/storage/<key>
      // padahal file disimpan di disk S3 (https://storage.velora.co.id/<key>), arahkan ke storage.velora.co.id
      final storageMatch = RegExp(r'^https?://(?:www\.)?velora\.co\.id/storage/(.+)$').firstMatch(trimmed);
      if (storageMatch != null && storageMatch.group(1) != null) {
        return 'https://storage.velora.co.id/${storageMatch.group(1)!}';
      }
      return trimmed;
    }

    // Path relatif dari DB (misal: "pharmacy/products/xxx.webp", "products/xxx.jpg", atau "/storage/pharmacy/products/xxx.webp")
    var cleanKey = trimmed.replaceFirst(RegExp(r'^/+'), '');
    if (cleanKey.startsWith('storage/')) {
      cleanKey = cleanKey.substring('storage/'.length);
    }
    return 'https://storage.velora.co.id/$cleanKey';
  }

  /// URL cadangan ke `/storage/` lokal apabila file tidak ditemukan di S3 `storage.velora.co.id`
  static String? resolveImageFallbackUrl(String? primaryUrl) {
    if (primaryUrl == null || primaryUrl.isEmpty) return null;
    final s3Match = RegExp(r'^https?://storage\.velora\.co\.id/(.+)$').firstMatch(primaryUrl);
    if (s3Match != null && s3Match.group(1) != null) {
      return 'https://velora.co.id/storage/${s3Match.group(1)!}';
    }
    return null;
  }
}

class PosCatalogData {
  final List<PosProduct> products;
  final List<String> categories;
  final List<ModifierGroup> modifiers;
  final int catalogVersion;
  final String businessType;

  PosCatalogData({
    required this.products,
    required this.categories,
    this.modifiers = const [],
    required this.catalogVersion,
    required this.businessType,
  });
}
