import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/safe_json.dart';
import '../fnb/fnb_catalog_service.dart';
import '../fnb/modifiers.dart';
import '../pharmacy/services/pharmacy_catalog_service.dart';
import 'retail_catalog_service.dart';

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

  factory PosProduct.fromJson(Map<String, dynamic>? json, {String? businessType}) {
    if (json == null) {
      return PosProduct(id: '', name: '', category: '', price: 0, stock: 0, sku: '', barcode: '');
    }
    final vertical = businessType ?? ProductCatalogService.activeVertical();
    switch (vertical) {
      case 'pharmacy':
        return PharmacyCatalogService.parsePharmacyProduct(json);
      case 'fnb':
        return FnbCatalogService.parseFnbProduct(json);
      default:
        return RetailCatalogService.parseRetailProduct(json);
    }
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

/// Router Katalog Produk yang mendelegasikan operasi ke layanan per-bisnis:
/// - `pharmacy` -> [PharmacyCatalogService]
/// - `fnb`      -> [FnbCatalogService]
/// - `retail`   -> [RetailCatalogService]
/// Setiap vertikal bisnis memiliki endpoint, parser JSON, aturan stok, dan cache terpisah.
class ProductCatalogService {
  static final ProductCatalogService instance = ProductCatalogService._();
  ProductCatalogService._();

  /// Normalisasi URL gambar produk dari backend (mendukung URL penuh S3/CDN maupun path relatif storage Laravel)
  static String? resolveImageUrl(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty ||
        trimmed == '-' ||
        trimmed.toLowerCase() == 'null' ||
        trimmed.toLowerCase() == 'undefined') {
      return null;
    }

    final lower = trimmed.toLowerCase();
    if (lower.contains('ui-avatars') ||
        lower.contains('placeholder') ||
        lower.contains('dummyimage') ||
        lower.contains('dicebear') ||
        lower.contains('default-avatar') ||
        lower.contains('no-image') ||
        lower.contains('no_image') ||
        lower.contains('default_drug')) {
      return null;
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('//')) {
      return 'https:$trimmed';
    }

    String origin = 'https://velora.co.id';
    try {
      final uri = Uri.parse(AppConfig.instance.apiBaseUrl);
      if (uri.hasScheme && uri.host.isNotEmpty) {
        origin = '${uri.scheme}://${uri.host}${uri.hasPort && uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
      }
    } catch (_) {}

    final cleanPath = trimmed.replaceFirst(RegExp(r'^/+'), '');
    if (cleanPath.startsWith('storage/') ||
        cleanPath.startsWith('images/') ||
        cleanPath.startsWith('uploads/') ||
        cleanPath.startsWith('assets/')) {
      return '$origin/$cleanPath';
    }
    return '$origin/storage/$cleanPath';
  }

  static String activeVertical() {
    final raw = (SessionStorage.instance.getBusinessType() ?? '').toLowerCase().trim();
    if (raw.contains('pharm') || raw.contains('apotek') || raw.contains('klinik') || raw.contains('med')) {
      return 'pharmacy';
    }
    if (raw.contains('fnb') || raw.contains('cafe') || raw.contains('resto') || raw.contains('food')) {
      return 'fnb';
    }
    try {
      if (AppConfig.instance.isPharmacy) return 'pharmacy';
      if (AppConfig.instance.isFnb) return 'fnb';
    } catch (_) {}
    return 'retail';
  }

  PosCatalogData? get cachedCatalog {
    switch (activeVertical()) {
      case 'pharmacy':
        return PharmacyCatalogService.instance.cachedCatalog;
      case 'fnb':
        return FnbCatalogService.instance.cachedCatalog;
      default:
        return RetailCatalogService.instance.cachedCatalog;
    }
  }

  /// Bersihkan semua cache memori di ketiga layanan bisnis (dipanggil saat logout / ganti cabang)
  void clearMemoryCache() {
    PharmacyCatalogService.instance.clearMemoryCache();
    FnbCatalogService.instance.clearMemoryCache();
    RetailCatalogService.instance.clearMemoryCache();
  }

  PosProduct? findByBarcode(String barcode) {
    switch (activeVertical()) {
      case 'pharmacy':
        return PharmacyCatalogService.instance.findByBarcode(barcode);
      case 'fnb':
        return FnbCatalogService.instance.findByBarcode(barcode);
      default:
        return RetailCatalogService.instance.findByBarcode(barcode);
    }
  }

  PosProduct? findBySku(String sku) {
    switch (activeVertical()) {
      case 'pharmacy':
        return PharmacyCatalogService.instance.findBySku(sku);
      case 'fnb':
        return FnbCatalogService.instance.findBySku(sku);
      default:
        return RetailCatalogService.instance.findBySku(sku);
    }
  }

  PosProduct? findById(String id) {
    switch (activeVertical()) {
      case 'pharmacy':
        return PharmacyCatalogService.instance.findById(id);
      case 'fnb':
        return FnbCatalogService.instance.findById(id);
      default:
        return RetailCatalogService.instance.findById(id);
    }
  }

  List<PosProduct> searchFast(String query) {
    switch (activeVertical()) {
      case 'pharmacy':
        return PharmacyCatalogService.instance.searchFast(query);
      case 'fnb':
        return FnbCatalogService.instance.searchFast(query);
      default:
        return RetailCatalogService.instance.searchFast(query);
    }
  }

  Future<List<PosProduct>> searchProductsRemote(
    String query, {
    int limit = 50,
  }) {
    switch (activeVertical()) {
      case 'pharmacy':
        return PharmacyCatalogService.instance.searchProductsRemote(query, limit: limit);
      case 'fnb':
        return FnbCatalogService.instance.searchProductsRemote(query, limit: limit);
      default:
        return RetailCatalogService.instance.searchProductsRemote(query, limit: limit);
    }
  }

  Future<PosProduct?> scanBarcodeRemote(String barcode) async {
    switch (activeVertical()) {
      case 'pharmacy':
        return PharmacyCatalogService.instance.scanBarcodeRemote(barcode);
      case 'fnb':
        final matches = await FnbCatalogService.instance.searchProductsRemote(barcode, limit: 5);
        return matches.isNotEmpty ? matches.first : null;
      default:
        final matches = await RetailCatalogService.instance.searchProductsRemote(barcode, limit: 5);
        return matches.isNotEmpty ? matches.first : null;
    }
  }

  Future<PosCatalogData> fetchCatalog({
    String? search,
    String? categoryId,
    int? sinceVersion,
    int limit = 100,
  }) {
    switch (activeVertical()) {
      case 'pharmacy':
        return PharmacyCatalogService.instance.fetchCatalog(
          search: search,
          categoryId: categoryId,
          sinceVersion: sinceVersion,
          limit: limit,
        );
      case 'fnb':
        return FnbCatalogService.instance.fetchCatalog(
          search: search,
          categoryId: categoryId,
          sinceVersion: sinceVersion,
          limit: limit,
        );
      default:
        return RetailCatalogService.instance.fetchCatalog(
          search: search,
          categoryId: categoryId,
          sinceVersion: sinceVersion,
          limit: limit,
        );
    }
  }
}
