import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/utils/safe_json.dart';
import '../../shared_pos/models/pos_catalog_models.dart';
import '../models/modifiers.dart';

/// Layanan Katalog Khusus Bisnis F&B / CAFE / RESTORAN.
/// Terisolasi penuh dari Pharmacy (Apotek) dan Retail:
/// - Hanya menembak endpoint menu Cafe & F&B sesuai `routes/api/pos.php` dan `routes/api/cafe.php`:
///   `/v1/pos/products-sync`, `/cafe/menu`, `/cafe/products`.
/// - Mengekstrak skema `CafePosStrategy` (`id, category_id, velora_id, name, description, price, promo_price, image, is_available, can_order, status, barcode, sku, station, sales_unit, stock_unit, is_bundle, bundle_items`, serta `modifiers`).
/// - Stok default `99.0` (menu racikan dapur/barista selalu tersedia kecuali `is_available == false`, `can_order == false`, atau `status == 'sold_out'`).
/// - Cache memori dan disk dikunci ke `fnb_<tenantId>_<locationId>`.
class FnbCatalogService {
  static final FnbCatalogService instance = FnbCatalogService._();
  FnbCatalogService._();

  PosCatalogData? _cachedCatalog;
  String? _cachedScopeKey;
  PosCatalogData? get cachedCatalog => _cachedCatalog;

  final Map<String, PosProduct> _barcodeMap = {};
  final Map<String, PosProduct> _skuMap = {};
  final Map<String, PosProduct> _idMap = {};

  String _currentScopeKey() {
    final tenantId = SessionStorage.instance.getTenantId() ?? 'anon';
    final locId = SessionStorage.instance.getLocationId() ?? 'main';
    return 'fnb_${tenantId}_$locId';
  }

  void _ensureTenantScope() {
    final currentKey = _currentScopeKey();
    if (_cachedScopeKey != null && _cachedScopeKey != currentKey) {
      clearMemoryCache();
    }
    _cachedScopeKey = currentKey;
  }

  void clearMemoryCache() {
    _cachedCatalog = null;
    _cachedScopeKey = null;
    _barcodeMap.clear();
    _skuMap.clear();
    _idMap.clear();
  }

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

  PosProduct? findByBarcode(String barcode) => _barcodeMap[barcode.trim().toLowerCase()];
  PosProduct? findBySku(String sku) => _skuMap[sku.trim().toLowerCase()];
  PosProduct? findById(String id) => _idMap[id.trim()];

  /// Pencarian cepat menu F&B di memori lokal
  List<PosProduct> searchFast(String query) {
    _ensureTenantScope();
    if (query.isEmpty) return _cachedCatalog?.products ?? const [];
    final q = query.trim().toLowerCase();

    final bMatch = _barcodeMap[q];
    if (bMatch != null) return [bMatch];

    final sMatch = _skuMap[q];
    if (sMatch != null) return [sMatch];

    final list = _cachedCatalog?.products ?? const [];
    return list
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            (p.description ?? '').toLowerCase().contains(q))
        .toList();
  }

  /// Ambil katalog menu F&B / Cafe untuk Kasir F&B dan Self-Order Pelanggan
  Future<PosCatalogData> fetchCatalog({
    String? search,
    String? categoryId,
    int? sinceVersion,
    int limit = 100,
  }) async {
    _ensureTenantScope();
    final scopeKey = _currentScopeKey();
    final locId = SessionStorage.instance.getLocationId();

    final queryParams = <String, dynamic>{
      'limit': limit,
      if (locId != null && locId.isNotEmpty) 'location_id': locId,
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
      'since_version': ?sinceVersion,
    };

    Response<dynamic>? response;
    PosCatalogData? parsedCatalog;

    try {
      final res = await ApiClient.instance.dio.get(
        '/v1/pos/products-sync',
        queryParameters: queryParams,
      );
      if (res.statusCode == 200 && res.data != null) {
        response = res;
        parsedCatalog = await compute(parseCatalogData, res.data);
      }
    } catch (e) {
      debugPrint('⚠️ [FNB CATALOG] /v1/pos/products-sync gagal: $e');
    }

    if (response == null || parsedCatalog == null) {
      if (_cachedCatalog != null && _cachedCatalog!.products.isNotEmpty) {
        return _cachedCatalog!;
      }
      final diskJson = SessionStorage.instance.getCatalogCache(scopeKey);
      if (diskJson != null && diskJson.isNotEmpty) {
        try {
          final diskData = await compute(decodeAndParseCatalogData, diskJson);
          if (diskData.products.isNotEmpty) {
            _rebuildIndex(diskData.products);
            _cachedCatalog = diskData;
            return diskData;
          }
        } catch (e) {
          debugPrint('⚠️ [FNB CATALOG] Gagal baca disk cache ($scopeKey): $e');
        }
      }
      return PosCatalogData(
        products: const [],
        categories: const ['Semua'],
        catalogVersion: 1,
        businessType: 'fnb',
      );
    }

    final catalogData = parsedCatalog;
    debugPrint(
      '☕ [FNB CATALOG] Loaded ${catalogData.products.length} menu across ${catalogData.categories.length} kategori from /v1/pos/products-sync ($scopeKey)',
    );
    _rebuildIndex(catalogData.products);
    _cachedCatalog = catalogData;

    try {
      final encoded = await compute(jsonEncode, response.data);
      unawaited(SessionStorage.instance.saveCatalogCache(scopeKey, encoded));
    } catch (_) {}

    return catalogData;
  }

  /// Pencarian menu F&B ke 1 endpoint resmi POS (`/v1/pos/products-sync?search=...`)
  Future<List<PosProduct>> searchProductsRemote(
    String query, {
    int limit = 50,
  }) async {
    _ensureTenantScope();
    final trimmed = query.trim();
    if (trimmed.isEmpty) return _cachedCatalog?.products ?? const [];

    final locId = SessionStorage.instance.getLocationId();
    try {
      final res = await ApiClient.instance.dio.get(
        '/v1/pos/products-sync',
        queryParameters: {
          'search': trimmed,
          'limit': limit,
          if (locId != null && locId.isNotEmpty) 'location_id': locId,
        },
      );
      if (res.statusCode == 200 && res.data != null) {
        final parsed = await compute(parseCatalogData, res.data);
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
      debugPrint('⚠️ [FNB SEARCH] /v1/pos/products-sync?search gagal: $e');
    }

    return searchFast(trimmed);
  }

  /// Parser khusus produk F&B / Cafe (Menu, Kategori, Modifier Groups, Resep/Available Stock)
  static PosProduct parseFnbProduct(Map<String, dynamic> json) {
    String productName = json.getString('name');
    if (productName.isEmpty || productName == '-') productName = json.getString('menu_name');
    if (productName.isEmpty || productName == '-') productName = json.getString('display_name');
    if (productName.isEmpty || productName == '-') productName = json.getString('product_name');
    if (productName.isEmpty || productName == '-') productName = json.getString('item_name');
    if (productName.isEmpty || productName == '-') productName = 'Menu';
    productName = sanitizeDisplayName(productName);

    String categoryName = '';
    final rawCat = json['category'] ?? json['kategori'] ?? json['menu_category'];
    if (rawCat is Map) {
      categoryName = sanitizeDisplayName(rawCat);
    } else if (rawCat is String) {
      categoryName = sanitizeDisplayName(rawCat);
    }
    if (categoryName.isEmpty || categoryName == '-') categoryName = json.getString('category_name');
    if (categoryName.isEmpty || categoryName == '-') categoryName = 'Minuman & Makanan';
    categoryName = sanitizeDisplayName(categoryName);

    // Deteksi harga normal / reguler dan harga promo / diskon
    double rawRegularPrice = json.getDouble('original_price');
    if (rawRegularPrice <= 0) rawRegularPrice = json.getDouble('normal_price');
    if (rawRegularPrice <= 0) rawRegularPrice = json.getDouble('base_price');
    if (rawRegularPrice <= 0) rawRegularPrice = json.getDouble('regular_price');
    if (rawRegularPrice <= 0) rawRegularPrice = json.getDouble('harga_normal');
    if (rawRegularPrice <= 0) rawRegularPrice = json.getDouble('harga_asli');
    if (rawRegularPrice <= 0) rawRegularPrice = json.getDouble('price');
    if (rawRegularPrice <= 0) rawRegularPrice = json.getDouble('selling_price');
    if (rawRegularPrice <= 0) rawRegularPrice = json.getDouble('harga_jual');
    if (rawRegularPrice <= 0) rawRegularPrice = json.getDouble('harga');

    double rawPromoPrice = json.getDouble('promo_price');
    if (rawPromoPrice <= 0) rawPromoPrice = json.getDouble('discount_price');
    if (rawPromoPrice <= 0) rawPromoPrice = json.getDouble('discounted_price');
    if (rawPromoPrice <= 0) rawPromoPrice = json.getDouble('special_price');
    if (rawPromoPrice <= 0) rawPromoPrice = json.getDouble('sale_price');
    if (rawPromoPrice <= 0) rawPromoPrice = json.getDouble('harga_promo');
    if (rawPromoPrice <= 0) rawPromoPrice = json.getDouble('harga_diskon');

    // Cek kemungkinan objek nested promo atau diskon
    final promoMap = json['promo'] is Map
        ? Map<String, dynamic>.from(json['promo'])
        : (json['promotion'] is Map
            ? Map<String, dynamic>.from(json['promotion'])
            : (json['discount'] is Map ? Map<String, dynamic>.from(json['discount']) : null));
    if (promoMap != null) {
      if (rawPromoPrice <= 0) {
        rawPromoPrice = promoMap.getDouble(
          'promo_price',
          fallback: promoMap.getDouble('price', fallback: promoMap.getDouble('discount_price')),
        );
      }
    }

    double discountPct = json.getDouble('discount_percentage');
    if (discountPct <= 0) discountPct = json.getDouble('discount_percent');
    if (discountPct <= 0) discountPct = json.getDouble('discount_rate');
    if (discountPct <= 0) discountPct = json.getDouble('diskon_persen');
    if (discountPct <= 0) discountPct = json.getDouble('discount');
    if (discountPct <= 0 && promoMap != null) {
      discountPct = promoMap.getDouble(
        'percentage',
        fallback: promoMap.getDouble('discount_percent', fallback: promoMap.getDouble('discount')),
      );
    }

    final bool isPromoFlag = json.getBool('is_promo') ||
        json.getBool('has_promo') ||
        json.getBool('is_discount') ||
        json.getBool('on_sale') ||
        (promoMap != null && promoMap.getBool('is_active', fallback: true));

    double priceVal;
    double? originalPriceVal;

    if (rawPromoPrice > 0 && rawRegularPrice > rawPromoPrice) {
      priceVal = rawPromoPrice;
      originalPriceVal = rawRegularPrice;
      if (discountPct <= 0 && rawRegularPrice > 0) {
        discountPct = ((rawRegularPrice - rawPromoPrice) / rawRegularPrice) * 100;
      }
    } else if (rawPromoPrice > 0 && rawRegularPrice <= 0) {
      priceVal = rawPromoPrice;
    } else if (discountPct > 0 && discountPct < 100 && rawRegularPrice > 0) {
      priceVal = (rawRegularPrice * (1.0 - (discountPct / 100.0))).roundToDouble();
      originalPriceVal = rawRegularPrice;
    } else {
      priceVal = rawRegularPrice;
      final explicitOrig = json.getDouble(
        'original_price',
        fallback: json.getDouble('normal_price', fallback: json.getDouble('base_price')),
      );
      if (explicitOrig > priceVal) {
        originalPriceVal = explicitOrig;
        if (discountPct <= 0) {
          discountPct = ((explicitOrig - priceVal) / explicitOrig) * 100;
        }
      }
    }

    final bool hasStockField = (json.containsKey('stock') && json['stock'] != null) ||
        (json.containsKey('stock_qty') && json['stock_qty'] != null);
    final statusStr = json.getString('status').toLowerCase();
    final bool isExplicitlyUnavailable = json.getBool('is_out_of_stock') ||
        statusStr == 'sold_out' ||
        statusStr == 'out_of_stock' ||
        statusStr == 'unavailable' ||
        (json.containsKey('is_available') && json.getBool('is_available') == false) ||
        (json.containsKey('can_order') && json.getBool('can_order') == false);

    double stockVal;
    if (isExplicitlyUnavailable) {
      stockVal = 0.0;
    } else if (hasStockField) {
      stockVal = json.getDouble('stock', fallback: json.getDouble('stock_qty'));
    } else {
      stockVal = 99.0;
    }

    String skuVal = json.getString('sku');
    if (skuVal.isEmpty || skuVal == '-') skuVal = json.getString('velora_id');
    if (skuVal.isEmpty || skuVal == '-') skuVal = json.getString('code');

    String barcodeVal = json.getString('barcode');

    String img = json.getString('image');
    if (img.isEmpty || img == '-') img = json.getString('image_url');

    String? productTag = json.getString('station');
    if (productTag.isEmpty) productTag = json.getString('badge');
    if (productTag.isEmpty) productTag = json.getString('tag');
    if (productTag.isEmpty) productTag = json.getString('promo_badge');
    if (productTag.isEmpty) productTag = json.getString('promo_label');
    if (productTag.isEmpty && (isPromoFlag || (originalPriceVal != null && originalPriceVal > priceVal))) {
      if (discountPct > 0) {
        productTag = 'DISKON ${discountPct.round()}%';
      } else {
        productTag = 'PROMO';
      }
    }

    String? desc = json.getString('description');

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
            debugPrint('⚠️ [FNB CATALOG] Gagal parse ModifierGroup: $e');
          }
        }
      }
    }

    final unitVal = json.getString(
      'sales_unit',
      fallback: json.getString('stock_unit', fallback: json.getString('unit', fallback: 'PORSI')),
    );

    return PosProduct(
      id: json.getString('id'),
      name: productName,
      category: categoryName,
      categoryId: catId != null && catId.isNotEmpty ? catId : null,
      price: priceVal,
      originalPrice: originalPriceVal,
      discountPercent: discountPct > 0 ? discountPct : null,
      stock: stockVal,
      sku: skuVal,
      barcode: barcodeVal,
      imageUrl: PosProduct.resolveImageUrl(img),
      tag: productTag.isNotEmpty ? productTag : null,
      description: desc.isNotEmpty ? desc : null,
      unit: unitVal,
      isPrescriptionOnly: false,
      batches: const [],
      units: [PosProductUnit(name: unitVal.toUpperCase(), price: priceVal, conversion: 1, isDefault: true)],
      modifierGroups: modGroups,
    );
  }

  static PosCatalogData decodeAndParseCatalogData(String diskJson) =>
      parseCatalogData(jsonDecode(diskJson));

  static PosCatalogData parseCatalogData(dynamic rawData) {
    Map<String, dynamic> data = {};
    List<dynamic> productList = const [];
    List<dynamic> categoryList = const [];

    if (rawData is Map) {
      final inner = rawData['data'];
      if (inner is Map) {
        data = Map<String, dynamic>.from(inner);
        final p = data['products'] ?? data['menus'] ?? data['items'] ?? data['data'];
        if (p is List) productList = p;
        final c = data['categories'] ?? data['category_list'];
        if (c is List) categoryList = c;
      } else if (inner is List) {
        productList = inner;
        data = Map<String, dynamic>.from(rawData);
      } else {
        data = Map<String, dynamic>.from(rawData);
        final p = data['products'] ?? data['menus'] ?? data['items'] ?? data['data'];
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
          rawProducts.add(parseFnbProduct(Map<String, dynamic>.from(item)));
        } catch (e) {
          debugPrint('⚠️ [FNB CATALOG] Gagal parse menu: $e');
        }
      }
    }

    final categorySet = <String>{'Semua'};
    if (rawProducts.any((p) => p.isOnPromo)) {
      categorySet.add('Promo');
    }
    for (final item in categoryList) {
      final clean = sanitizeDisplayName(item is Map ? (item['name'] ?? item['category_name']) : item);
      if (clean.isNotEmpty && clean != 'Semua' && clean != 'Promo') categorySet.add(clean);
    }
    for (final p in rawProducts) {
      final clean = sanitizeDisplayName(p.category);
      if (clean.isNotEmpty && clean != 'Semua' && clean != 'Umum' && clean != 'Promo') {
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
          } catch (_) {}
        }
      }
    }

    return PosCatalogData(
      products: rawProducts,
      categories: categorySet.toList(),
      modifiers: catalogModifiers,
      catalogVersion: data.getInt('catalog_version', fallback: 1),
      businessType: 'fnb',
    );
  }
}
