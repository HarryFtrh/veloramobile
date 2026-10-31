import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/safe_json.dart';
import '../fnb/modifiers.dart';

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
      stock: json.getDouble('stock',
          fallback: json.getDouble('stock_qty',
              fallback: json.getDouble('stok', fallback: json.getDouble('qty')))),
    );
  }
}

class PosProductUnit {
  final String name;
  final num price;
  final num conversion;
  final bool isDefault;

  PosProductUnit({
    required this.name,
    required this.price,
    this.conversion = 1,
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
    if (unitName.isEmpty) unitName = 'TAB';

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
    this.unit,
    this.isPrescriptionOnly = false,
    this.batches = const [],
    this.units = const [],
    this.modifierGroups = const [],
  });

  factory PosProduct.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return PosProduct(id: '', name: '', category: '', price: 0, stock: 0, sku: '', barcode: '');
    }

    var rawBatches = json.getList<PosProductBatch>(
      'batches',
      (item) => PosProductBatch.fromJson(item is Map<String, dynamic> ? item : null),
    );
    if (rawBatches.isEmpty) {
      rawBatches = json.getList<PosProductBatch>(
        'product_batches',
        (item) => PosProductBatch.fromJson(item is Map<String, dynamic> ? item : null),
      );
    }
    if (rawBatches.isEmpty) {
      rawBatches = json.getList<PosProductBatch>(
        'batches_list',
        (item) => PosProductBatch.fromJson(item is Map<String, dynamic> ? item : null),
      );
    }
    if (rawBatches.isEmpty) {
      rawBatches = json.getList<PosProductBatch>(
        'lots',
        (item) => PosProductBatch.fromJson(item is Map<String, dynamic> ? item : null),
      );
    }
    if (rawBatches.isEmpty) {
      rawBatches = json.getList<PosProductBatch>(
        'stocks',
        (item) => PosProductBatch.fromJson(item is Map<String, dynamic> ? item : null),
      );
    }

    final Map<String, dynamic> gp = (json['global_product'] is Map)
        ? Map<String, dynamic>.from(json['global_product'] as Map)
        : (json['product'] is Map ? Map<String, dynamic>.from(json['product'] as Map) : const {});

    // Product name: handles Cafe/Retail/Pharmacy keys + GlobalProduct fallback
    String productName = json.getString('name');
    if (productName.isEmpty || productName == '-') productName = json.getString('display_name');
    if (productName.isEmpty || productName == '-') productName = json.getString('custom_name');
    if (productName.isEmpty || productName == '-') productName = json.getString('name_main');
    if (productName.isEmpty || productName == '-') productName = json.getString('product_name');
    if (productName.isEmpty || productName == '-') productName = json.getString('nama_obat');
    if (productName.isEmpty || productName == '-') productName = json.getString('nama_produk');
    if (productName.isEmpty || productName == '-') productName = json.getString('medicine_name');
    if (productName.isEmpty || productName == '-') productName = json.getString('drug_name');
    if (productName.isEmpty || productName == '-') productName = json.getString('item_name');
    if (productName.isEmpty || productName == '-') productName = gp.getString('name_main');
    if (productName.isEmpty || productName == '-') productName = gp.getString('display_name');
    if (productName.isEmpty || productName == '-') productName = gp.getString('name');
    if (productName.isEmpty || productName == '-') productName = 'Produk';
    productName = sanitizeDisplayName(productName);

    // Category name: handles Cafe/Retail/Pharmacy keys + GlobalProduct fallback
    String categoryName = '';
    final rawCat = json['category'] ?? json['kategori'] ?? json['golongan'] ?? json['klasifikasi'] ?? json['jenis'] ?? gp['golongan'] ?? gp['category'];
    if (rawCat is Map) {
      categoryName = sanitizeDisplayName(rawCat);
    } else if (rawCat is String) {
      categoryName = rawCat;
    }
    if (categoryName.isEmpty || categoryName == '-') categoryName = json.getString('category_name');
    if (categoryName.isEmpty || categoryName == '-') categoryName = json.getString('golongan_obat');
    if (categoryName.isEmpty || categoryName == '-') categoryName = json.getString('category');
    if (categoryName.isEmpty || categoryName == '-') categoryName = gp.getString('golongan');
    if (categoryName.isEmpty || categoryName == '-') categoryName = 'Umum';
    categoryName = sanitizeDisplayName(categoryName);

    // Selling price: handles 'price', 'selling_price', 'harga', 'harga_jual', or tiered prices
    double priceVal = json.getDouble('price');
    if (priceVal <= 0) priceVal = json.getDouble('selling_price');
    if (priceVal <= 0) priceVal = json.getDouble('harga');
    if (priceVal <= 0) priceVal = json.getDouble('harga_jual');
    if (priceVal <= 0) priceVal = json.getDouble('unit_price');
    if (priceVal <= 0) priceVal = json.getDouble('selling_price_1');
    if (priceVal <= 0) priceVal = json.getDouble('selling_price_2');
    if (priceVal <= 0) priceVal = json.getDouble('selling_price_3');
    if (priceVal <= 0) priceVal = gp.getDouble('selling_price');
    if (priceVal <= 0) priceVal = gp.getDouble('price');

    // Stock: handles 'stock', 'stock_qty', 'stok', 'current_stock', 'qty'
    final bool hasStockField = (json.containsKey('stock') && json['stock'] != null) ||
        (json.containsKey('stock_qty') && json['stock_qty'] != null) ||
        (json.containsKey('stok') && json['stok'] != null) ||
        (json.containsKey('current_stock') && json['current_stock'] != null) ||
        (json.containsKey('total_stock') && json['total_stock'] != null) ||
        (json.containsKey('qty') && json['qty'] != null);
    final bool isExplicitlyUnavailable = json.getBool('is_out_of_stock') ||
        json.getString('status').toLowerCase() == 'out_of_stock' ||
        (json.containsKey('is_available') && json.getBool('is_available') == false);

    double stockVal;
    if (isExplicitlyUnavailable) {
      stockVal = 0.0;
    } else if (hasStockField) {
      stockVal = json.getDouble('stock',
          fallback: json.getDouble('stock_qty',
              fallback: json.getDouble('stok',
                  fallback: json.getDouble('current_stock',
                      fallback: json.getDouble('total_stock', fallback: json.getDouble('qty'))))));
    } else if (rawBatches.isNotEmpty) {
      stockVal = rawBatches.fold<double>(0.0, (sum, b) => sum + b.stock);
    } else {
      stockVal = 99.0;
    }

    // SKU & Barcode: handles 'sku'/'velora_id' and 'barcode'/'barcode_master'
    String skuVal = json.getString('sku');
    if (skuVal.isEmpty || skuVal == '-') skuVal = json.getString('velora_id');
    if (skuVal.isEmpty || skuVal == '-') skuVal = json.getString('kode_obat');
    if (skuVal.isEmpty || skuVal == '-') skuVal = json.getString('kode_produk');
    if (skuVal.isEmpty || skuVal == '-') skuVal = json.getString('code');
    if (skuVal.isEmpty || skuVal == '-') skuVal = json.getString('kode');
    if (skuVal.isEmpty || skuVal == '-') skuVal = gp.getString('velora_id');
    if (skuVal.isEmpty || skuVal == '-') skuVal = gp.getString('sku');
    String barcodeVal = json.getString('barcode');
    if (barcodeVal.isEmpty || barcodeVal == '-') barcodeVal = json.getString('barcode_master');
    if (barcodeVal.isEmpty || barcodeVal == '-') barcodeVal = gp.getString('barcode');

    // Prescription / Hard Drug detection
    final isRx = json.getBool('is_prescription_only') ||
        json.getBool('is_hard_drug') ||
        categoryName.toLowerCase().contains('keras') ||
        categoryName.toLowerCase().contains('narkotika') ||
        categoryName.toLowerCase().contains('psikotropika');

    // Root batch fallback when 'batches' array is empty or flat-mapped
    var finalBatches = rawBatches;
    if (finalBatches.isEmpty) {
      String rootBatch = json.getString('batch_number');
      if (rootBatch.isEmpty || rootBatch == '-') rootBatch = json.getString('batch_no');
      if (rootBatch.isEmpty || rootBatch == '-') rootBatch = json.getString('lot_number');
      if (rootBatch.isEmpty || rootBatch == '-') rootBatch = json.getString('lot_no');
      if (rootBatch.isEmpty || rootBatch == '-') rootBatch = json.getString('batch');

      String rootExp = json.getString('expiry_date');
      if (rootExp.isEmpty || rootExp == '-') rootExp = json.getString('exp_date');
      if (rootExp.isEmpty || rootExp == '-') rootExp = json.getString('expired_date');
      if (rootExp.isEmpty || rootExp == '-') rootExp = json.getString('expired_at');
      if (rootExp.isEmpty || rootExp == '-') rootExp = json.getString('exp');

      if (rootBatch.isNotEmpty || rootExp.isNotEmpty) {
        finalBatches = [
          PosProductBatch(
            id: json.getString('id'),
            batchNumber: rootBatch.isNotEmpty ? rootBatch : '-',
            expiryDate: rootExp.isNotEmpty ? rootExp : '-',
            stock: stockVal,
          ),
        ];
      }
    }

    // Image URL resolution across API naming conventions
    String img = json.getString('image_url');
    if (img.isEmpty || img == '-') img = json.getString('image');
    if (img.isEmpty || img == '-') img = json.getString('photo');
    if (img.isEmpty || img == '-') img = json.getString('photo_url');
    if (img.isEmpty || img == '-') img = json.getString('thumbnail');
    if (img.isEmpty || img == '-') img = json.getString('image_path');
    if (img.isEmpty || img == '-') img = json.getString('picture');
    if (img.isEmpty || img == '-') img = json.getString('img');

    // Filter out dummy/avatar generator placeholders (e.g. ui-avatars that render initials 'PA', 'Pr')
    if (img.isNotEmpty) {
      final lowerImg = img.toLowerCase().trim();
      final bool isPlaceholder = lowerImg.contains('ui-avatars') ||
          lowerImg.contains('placeholder') ||
          lowerImg.contains('dummyimage') ||
          lowerImg.contains('dicebear') ||
          lowerImg.contains('default-avatar') ||
          lowerImg.contains('no-image') ||
          lowerImg.contains('no_image') ||
          lowerImg.contains('default_drug') ||
          lowerImg.contains('avatar');
      if (isPlaceholder) {
        img = '';
      }
    }

    // Unit / Satuan resolution
    String unitVal = json.getString('unit');
    if (unitVal.isEmpty || unitVal == '-') unitVal = json.getString('satuan');
    if (unitVal.isEmpty || unitVal == '-') unitVal = json.getString('packaging');
    if (unitVal.isEmpty || unitVal == '-') unitVal = json.getString('package_unit');
    if (unitVal.isEmpty || unitVal == '-') unitVal = json.getString('uom');
    if (unitVal.isEmpty || unitVal == '-') unitVal = json.getString('base_unit');
    if (unitVal.isEmpty || unitVal == '-') unitVal = json.getString('satuan_terkecil');
    if (unitVal.isEmpty || unitVal == '-') unitVal = gp.getString('kemasan');
    if (unitVal.isEmpty || unitVal == '-') unitVal = gp.getString('unit');

    String? productTag = json.getString('badge');
    if (productTag.isEmpty) productTag = json.getString('tag');
    if (productTag.isEmpty) productTag = json.getString('promo_tag');

    String? desc = json.getString('description');
    if (desc.isEmpty) desc = json.getString('kandungan');
    if (desc.isEmpty) desc = json.getString('composition');
    if (desc.isEmpty) desc = json.getString('active_ingredient');
    if (desc.isEmpty) desc = json.getString('zat_aktif');
    if (desc.isEmpty) desc = json.getString('subtitle');
    if (desc.isEmpty) desc = json.getString('desc');
    if (desc.isEmpty) desc = gp.getString('kandungan');
    if (desc.isEmpty) desc = gp.getString('description');

    String? catId = json.getString('category_id');
    if (catId.isEmpty && json['category'] is Map) {
      catId = json['category']['id']?.toString();
    }

    final rawModifiers = json['modifier_groups'] ?? json['modifiers'] ?? json['options'];
    final List<ModifierGroup> modGroups = [];
    if (rawModifiers is List) {
      for (final m in rawModifiers) {
        if (m is Map) {
          try {
            modGroups.add(ModifierGroup.fromJson(Map<String, dynamic>.from(m)));
          } catch (e) {
            debugPrint('⚠️ [PosProduct] Gagal parse ModifierGroup: $e');
          }
        }
      }
    }

    // Multi-Satuan / Product Units resolution
    final List<PosProductUnit> finalUnits = [];
    final rawUnits = json['units'] ??
        json['product_units'] ??
        json['multi_units'] ??
        json['satuan_list'] ??
        json['conversions'] ??
        json['unit_conversions'] ??
        json['uom_conversions'] ??
        json['packaging_units'] ??
        json['prices'] ??
        json['price_levels'];
    if (rawUnits is List) {
      for (final u in rawUnits) {
        if (u is Map) {
          finalUnits.add(PosProductUnit.fromJson(Map<String, dynamic>.from(u), defaultPrice: priceVal));
        } else if (u is String && u.trim().isNotEmpty) {
          finalUnits.add(PosProductUnit(name: u.trim().toUpperCase(), price: priceVal, conversion: 1));
        }
      }
    }

    // Check tiered price & unit fields: unit_1, unit_2, unit_3 / satuan_1, satuan_2, satuan_3
    final u1 = json.getString('unit_1', fallback: json.getString('satuan_1'));
    final sp1 = json.getDouble('selling_price_1');
    final u2 = json.getString('unit_2', fallback: json.getString('satuan_2'));
    final sp2 = json.getDouble('selling_price_2');
    final u3 = json.getString('unit_3', fallback: json.getString('satuan_3'));
    final sp3 = json.getDouble('selling_price_3');

    if (finalUnits.isEmpty) {
      if (u1.isNotEmpty && sp1 > 0) {
        finalUnits.add(PosProductUnit(name: u1.toUpperCase(), price: sp1, conversion: 1, isDefault: true));
      }
      if (u2.isNotEmpty && sp2 > 0) {
        finalUnits.add(PosProductUnit(name: u2.toUpperCase(), price: sp2, conversion: 1));
      }
      if (u3.isNotEmpty && sp3 > 0) {
        finalUnits.add(PosProductUnit(name: u3.toUpperCase(), price: sp3, conversion: 1));
      }
    }

    if (finalUnits.isEmpty) {
      final defaultU = unitVal.isNotEmpty && unitVal != '-' ? unitVal.toUpperCase() : 'TAB';
      finalUnits.add(PosProductUnit(name: defaultU, price: priceVal, conversion: 1, isDefault: true));
    }

    // Auto-populate multi-satuan for single-unit medications
    if (finalUnits.length == 1) {
      final uUpper = finalUnits.first.name.toUpperCase();
      final baseP = finalUnits.first.price;
      if (uUpper == 'TAB' || uUpper == 'TABLET' || uUpper == 'KAPLET' || uUpper == 'KAPSUL' || uUpper == 'PIL') {
        if (!finalUnits.any((u) => u.name == 'STRIP')) {
          finalUnits.add(PosProductUnit(name: 'STRIP', price: (baseP * 10).round(), conversion: 10));
        }
        if (!finalUnits.any((u) => u.name == 'BOX')) {
          finalUnits.add(PosProductUnit(name: 'BOX', price: (baseP * 100).round(), conversion: 100));
        }
      } else if (uUpper == 'STRIP') {
        if (!finalUnits.any((u) => u.name == 'TAB')) {
          finalUnits.insert(0, PosProductUnit(name: 'TAB', price: (baseP / 10).round(), conversion: 1));
        }
        if (!finalUnits.any((u) => u.name == 'BOX')) {
          finalUnits.add(PosProductUnit(name: 'BOX', price: (baseP * 10).round(), conversion: 10));
        }
      } else if (!finalUnits.any((u) => u.name == 'BOX')) {
        finalUnits.add(PosProductUnit(name: 'BOX', price: (baseP * 10).round(), conversion: 10));
      }
    }

    return PosProduct(
      id: json.getString('id'),
      name: productName,
      category: categoryName,
      categoryId: catId != null && catId.isNotEmpty ? catId : null,
      price: priceVal,
      stock: stockVal,
      sku: skuVal,
      barcode: barcodeVal,
      imageUrl: img.isNotEmpty && img != '-' ? img : null,
      tag: productTag.isNotEmpty ? productTag : null,
      description: desc.isNotEmpty ? desc : null,
      unit: unitVal.isNotEmpty && unitVal != '-' ? unitVal : null,
      isPrescriptionOnly: isRx,
      batches: finalBatches,
      units: finalUnits,
      modifierGroups: modGroups,
    );
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

class ProductCatalogService {
  static final ProductCatalogService instance = ProductCatalogService._();
  ProductCatalogService._();

  PosCatalogData? _cachedCatalog;
  PosCatalogData? get cachedCatalog => _cachedCatalog;

  // In-Memory Fast Lookup Indices (O(1) Scan & Search)
  final Map<String, PosProduct> _barcodeMap = {};
  final Map<String, PosProduct> _skuMap = {};
  final Map<String, PosProduct> _idMap = {};

  void _rebuildIndex(List<PosProduct> products) {
    _barcodeMap.clear();
    _skuMap.clear();
    _idMap.clear();
    for (final p in products) {
      if (p.id.isNotEmpty) _idMap[p.id] = p;
      if (p.barcode.isNotEmpty) _barcodeMap[p.barcode.trim().toLowerCase()] = p;
      if (p.sku.isNotEmpty) _skuMap[p.sku.trim().toLowerCase()] = p;
    }
  }

  /// Pencarian barcode O(1) instan (<1ms) untuk scanner fisik USB/Bluetooth
  PosProduct? findByBarcode(String barcode) => _barcodeMap[barcode.trim().toLowerCase()];

  /// Pencarian SKU O(1) instan
  PosProduct? findBySku(String sku) => _skuMap[sku.trim().toLowerCase()];

  /// Pencarian ID produk O(1) instan
  PosProduct? findById(String id) => _idMap[id.trim()];

  /// Filter pencarian cepat (Barcode -> SKU -> Nama -> Kandungan -> Kategori)
  List<PosProduct> searchFast(String query) {
    if (query.isEmpty) return _cachedCatalog?.products ?? const [];
    final q = query.trim().toLowerCase();

    final bMatch = _barcodeMap[q];
    if (bMatch != null) return [bMatch];

    final sMatch = _skuMap[q];
    if (sMatch != null) return [sMatch];

    final list = _cachedCatalog?.products ?? const [];
    return list.where((p) =>
      p.name.toLowerCase().contains(q) ||
      p.sku.toLowerCase().contains(q) ||
      p.barcode.toLowerCase().contains(q) ||
      (p.description ?? '').toLowerCase().contains(q) ||
      p.category.toLowerCase().contains(q)
    ).toList();
  }

  /// Pencarian real-time ke backend Laravel Scout / Meilisearch (/v1/pharmacy/products?search=...)
  /// tanpa menimpa katalog dasar (_cachedCatalog), melainkan memperkaya indeks in-memory.
  Future<List<PosProduct>> searchProductsRemote(
    String query, {
    int limit = 50,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return _cachedCatalog?.products ?? const [];

    final locId = SessionStorage.instance.getLocationId();
    final queryParams = <String, dynamic>{
      'search': trimmed,
      'q': trimmed,
      'limit': limit,
      'per_page': limit,
      if (locId != null && locId.isNotEmpty) 'location_id': locId,
    };

    final bizType = SessionStorage.instance.getBusinessType()?.toLowerCase() ?? 'retail';
    bool isPharmacy = bizType == 'pharmacy';
    try {
      if (AppConfig.instance.isPharmacy) isPharmacy = true;
    } catch (_) {}

    final candidateEndpoints = isPharmacy
        ? [
            '/v1/pharmacy/products',
            '/v1/pos/products-sync',
            '/v1/pharmacy/inventory',
            '/v1/pharmacy/products/search-global',
          ]
        : [
            '/v1/pos/products-sync',
            '/v1/pos/products',
            '/v1/products',
          ];

    for (final ep in candidateEndpoints) {
      try {
        final res = await ApiClient.instance.dio.get(
          ep,
          queryParameters: queryParams,
        );
        if (res.statusCode == 200 && res.data != null) {
          final parsed = _parseCatalogData(res.data);
          if (parsed.products.isNotEmpty) {
            for (final p in parsed.products) {
              if (p.id.isNotEmpty) _idMap[p.id] = p;
              if (p.barcode.isNotEmpty) _barcodeMap[p.barcode.trim().toLowerCase()] = p;
              if (p.sku.isNotEmpty) _skuMap[p.sku.trim().toLowerCase()] = p;
            }
            return parsed.products;
          }
        }
      } catch (e) {
        debugPrint('⚠️ [SCOUT SEARCH] Candidate $ep failed: $e');
      }
    }

    return searchFast(trimmed);
  }

  /// Pindai barcode obat ke endpoint server `/v1/pharmacy/pos/scan` atau `/v1/pharmacy/products/scan`
  /// jika belum ada di memori lokal.
  Future<PosProduct?> scanBarcodeRemote(String barcode) async {
    final clean = barcode.trim();
    if (clean.isEmpty) return null;

    final local = findByBarcode(clean) ?? findBySku(clean);
    if (local != null) return local;

    final locId = SessionStorage.instance.getLocationId();
    final payload = <String, dynamic>{
      'barcode': clean,
      'code': clean,
      'sku': clean,
      if (locId != null && locId.isNotEmpty) 'location_id': locId,
    };

    const scanEndpoints = [
      '/v1/pharmacy/pos/scan',
      '/v1/pharmacy/products/scan',
    ];

    for (final ep in scanEndpoints) {
      try {
        final res = await ApiClient.instance.dio.post(ep, data: payload);
        if (res.statusCode == 200 && res.data != null) {
          final raw = res.data;
          Map<String, dynamic>? itemMap;
          if (raw is Map) {
            final d = raw['data'] ?? raw['product'] ?? raw['item'];
            if (d is Map) {
              itemMap = Map<String, dynamic>.from(d['product'] is Map ? d['product'] : d);
            } else if (raw['id'] != null || raw['name'] != null) {
              itemMap = Map<String, dynamic>.from(raw);
            }
          }
          if (itemMap != null) {
            final p = PosProduct.fromJson(itemMap);
            if (p.id.isNotEmpty) _idMap[p.id] = p;
            if (p.barcode.isNotEmpty) _barcodeMap[p.barcode.trim().toLowerCase()] = p;
            if (p.sku.isNotEmpty) _skuMap[p.sku.trim().toLowerCase()] = p;
            return p;
          }
        }
      } catch (e) {
        debugPrint('⚠️ [BARCODE SCAN] $ep failed: $e');
      }
    }

    // Fallback ke pencarian Scout dengan kata kunci barcode
    final scoutMatches = await searchProductsRemote(clean, limit: 5);
    if (scoutMatches.isNotEmpty) {
      return scoutMatches.first;
    }
    return null;
  }

  /// Fetches products from the canonical POS sync API
  Future<PosCatalogData> fetchCatalog({
    String? search,
    String? categoryId,
    int? sinceVersion,
    int limit = 100,
  }) async {
    final locId = SessionStorage.instance.getLocationId();
    final queryParams = <String, dynamic>{
      'limit': limit,
      'per_page': limit,
      if (locId != null && locId.isNotEmpty) 'location_id': locId,
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
    };

    if (sinceVersion != null) {
      queryParams['since_version'] = sinceVersion;
    }

    final bizType = SessionStorage.instance.getBusinessType()?.toLowerCase() ?? 'retail';
    bool isPharmacy = bizType == 'pharmacy';
    try {
      if (AppConfig.instance.isPharmacy) isPharmacy = true;
    } catch (_) {}
    final candidateEndpoints = bizType == 'fnb'
        ? [
            '/v1/pos/products-sync',
            '/v1/pos/menu',
            '/v1/pos/products',
            '/cafe/pos/products',
            '/cafe/menu',
            '/v1/products',
          ]
        : isPharmacy
            ? [
                '/v1/pharmacy/products',
                '/v1/pharmacy/medicines',
                '/v1/pharmacy/drugs',
                '/v1/pos/products-sync',
                '/v1/pos/products',
                '/v1/products',
                '/v1/pos/menu',
                '/products',
              ]
            : [
                '/v1/pos/products-sync',
                '/v1/pos/products',
                '/v1/products',
                '/v1/pos/menu',
                '/products',
              ];

    Response<dynamic>? response;
    String? successfulEndpoint;
    for (final ep in candidateEndpoints) {
      try {
        final res = await ApiClient.instance.dio.get(
          ep,
          queryParameters: queryParams,
        );
        if (res.statusCode == 200 && res.data != null) {
          response = res;
          successfulEndpoint = ep;
          break;
        }
      } catch (e) {
        debugPrint('⚠️ [CATALOG] Candidate $ep failed: $e');
      }
    }

    if (response == null) {
      debugPrint('⚠️ [CATALOG] All candidate endpoints failed or returned empty');
      if (_cachedCatalog != null && _cachedCatalog!.products.isNotEmpty) {
        return _cachedCatalog!;
      }
      // Pulihkan dari disk cache jika aplikasi dinyalakan saat offline total
      final diskJson = SessionStorage.instance.getCatalogCache(bizType);
      if (diskJson != null && diskJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(diskJson);
          final diskData = _parseCatalogData(decoded);
          if (diskData.products.isNotEmpty) {
            debugPrint('📦 [CATALOG] Berhasil memulihkan ${diskData.products.length} produk dari cache disk offline');
            _rebuildIndex(diskData.products);
            _cachedCatalog = diskData;
            return diskData;
          }
        } catch (e) {
          debugPrint('⚠️ [CATALOG] Gagal membaca disk catalog cache: $e');
        }
      }
      return PosCatalogData(
        products: const [],
        categories: const ['Semua'],
        catalogVersion: 1,
        businessType: bizType,
      );
    }

    final catalogData = _parseCatalogData(response.data);
    debugPrint('📦 [CATALOG] Loaded ${catalogData.products.length} dynamic products across ${catalogData.categories.length} categories and ${catalogData.modifiers.length} modifier groups from $successfulEndpoint');
    _rebuildIndex(catalogData.products);
    _cachedCatalog = catalogData;

    // Persist ke disk storage agar kasir tetap bisa berjualan saat cold-boot offline
    try {
      unawaited(SessionStorage.instance.saveCatalogCache(bizType, jsonEncode(response.data)));
    } catch (_) {}

    return catalogData;
  }

  /// Parser defensif untuk payload katalog produk dari API maupun disk cache lokal
  PosCatalogData _parseCatalogData(dynamic rawData) {
    Map<String, dynamic> data = {};
    List<dynamic> productList = const [];
    List<dynamic> categoryList = const [];

    if (rawData is Map) {
      final inner = rawData['data'];
      if (inner is Map) {
        data = Map<String, dynamic>.from(inner);
        final p = data['products'] ?? data['items'] ?? data['data'];
        if (p is List) productList = p;
        final c = data['categories'] ?? data['category_list'];
        if (c is List) categoryList = c;
      } else if (inner is List) {
        productList = inner;
        data = Map<String, dynamic>.from(rawData);
      } else {
        data = Map<String, dynamic>.from(rawData);
        final p = data['products'] ?? data['items'] ?? data['data'];
        if (p is List) productList = p;
      }
      final rawCats = rawData['categories'] ?? rawData['category_list'];
      if (categoryList.isEmpty && rawCats is List) {
        categoryList = rawCats;
      }
    } else if (rawData is List) {
      productList = rawData;
    }

    final rawProducts = <PosProduct>[];
    for (final item in productList) {
      if (item is Map) {
        try {
          rawProducts.add(PosProduct.fromJson(Map<String, dynamic>.from(item)));
        } catch (e) {
          debugPrint('⚠️ [CATALOG] Gagal parse PosProduct item: $e');
        }
      }
    }

    final rawCategories = <String>[];
    for (final item in categoryList) {
      if (item is Map) {
        final n = item['name'] ?? item['category_name'];
        if (n != null) rawCategories.add(sanitizeDisplayName(n));
      } else {
        rawCategories.add(sanitizeDisplayName(item));
      }
    }

    // Ensure 'Semua' exists and collect unique categories from both API & products
    final categorySet = <String>{'Semua'};
    for (final c in rawCategories) {
      final clean = sanitizeDisplayName(c);
      if (clean.isNotEmpty && clean != 'Semua') categorySet.add(clean);
    }
    for (final p in rawProducts) {
      final clean = sanitizeDisplayName(p.category);
      if (clean.isNotEmpty && clean != 'Semua' && clean != 'Umum') {
        categorySet.add(clean);
      }
    }

    final rawModifiersData = data['modifiers'] ?? (rawData is Map ? rawData['modifiers'] : null);
    final List<ModifierGroup> catalogModifiers = [];
    if (rawModifiersData is List) {
      for (final m in rawModifiersData) {
        if (m is Map) {
          try {
            catalogModifiers.add(ModifierGroup.fromJson(Map<String, dynamic>.from(m)));
          } catch (e) {
            debugPrint('⚠️ [CATALOG] Gagal parse ModifierGroup catalog: $e');
          }
        }
      }
    }

    return PosCatalogData(
      products: rawProducts,
      categories: categorySet.toList(),
      modifiers: catalogModifiers,
      catalogVersion: data.getInt('catalog_version', fallback: 1),
      businessType: data.getString('business_type', fallback: 'retail'),
    );
  }
}
