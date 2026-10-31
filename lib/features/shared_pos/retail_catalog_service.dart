import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/safe_json.dart';
import 'product_catalog_service.dart';

/// Layanan Katalog Khusus Bisnis RETAIL / MINIMARKET / GROSIR.
/// Terisolasi penuh dari Pharmacy (Apotek) dan FnB (Cafe):
/// - Hanya menembak endpoint POS Retail (`/v1/pos/products-sync`, `/v1/pos/products`).
/// - Mengekstrak struktur barang Retail (`sku`, `barcode`, `selling_price_1..3` bertingkat, satuan `PCS`/`PACK`/`DUS`).
/// - Stok default selalu `0` jika belum ada stok fisik (tidak pernah `99`).
/// - Cache memori dan disk dikunci ke `retail_<tenantId>_<locationId>`.
class RetailCatalogService {
  static final RetailCatalogService instance = RetailCatalogService._();
  RetailCatalogService._();

  PosCatalogData? _cachedCatalog;
  String? _cachedScopeKey;
  PosCatalogData? get cachedCatalog => _cachedCatalog;

  final Map<String, PosProduct> _barcodeMap = {};
  final Map<String, PosProduct> _skuMap = {};
  final Map<String, PosProduct> _idMap = {};

  String _currentScopeKey() {
    final tenantId = SessionStorage.instance.getTenantId() ?? 'anon';
    final locId = SessionStorage.instance.getLocationId() ?? 'main';
    return 'retail_${tenantId}_$locId';
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

  /// Pencarian cepat barang Retail di memori lokal (Barcode -> SKU -> Nama Barang -> Kategori)
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
            p.barcode.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q))
        .toList();
  }

  /// Ambil katalog barang untuk Kasir Retail
  Future<PosCatalogData> fetchCatalog({
    String? search,
    String? categoryId,
    int? sinceVersion,
    int limit = 100,
  }) async {
    _ensureTenantScope();
    final scopeKey = _currentScopeKey();
    final tenantId = SessionStorage.instance.getTenantId();
    final locId = SessionStorage.instance.getLocationId();

    final queryParams = <String, dynamic>{
      'limit': limit,
      'per_page': limit,
      if (tenantId != null && tenantId.isNotEmpty) 'tenant_id': tenantId,
      if (locId != null && locId.isNotEmpty) 'location_id': locId,
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
      if (sinceVersion != null) 'since_version': sinceVersion,
    };

    const candidateEndpoints = [
      '/v1/pos/products-sync',
      '/v1/pos/products',
    ];

    Response<dynamic>? response;
    PosCatalogData? parsedCatalog;
    String? successfulEndpoint;

    for (final ep in candidateEndpoints) {
      try {
        final res = await ApiClient.instance.dio.get(ep, queryParameters: queryParams);
        if (res.statusCode == 200 && res.data != null) {
          final candidateData = _parseRetailCatalogData(res.data);
          response ??= res;
          parsedCatalog ??= candidateData;
          successfulEndpoint ??= ep;
          if (candidateData.products.isNotEmpty) {
            response = res;
            parsedCatalog = candidateData;
            successfulEndpoint = ep;
            break;
          }
        }
      } catch (e) {
        debugPrint('⚠️ [RETAIL CATALOG] Endpoint $ep gagal: $e');
      }
    }

    if (response == null || parsedCatalog == null) {
      if (_cachedCatalog != null && _cachedCatalog!.products.isNotEmpty) {
        return _cachedCatalog!;
      }
      final diskJson = SessionStorage.instance.getCatalogCache(scopeKey);
      if (diskJson != null && diskJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(diskJson);
          final diskData = _parseRetailCatalogData(decoded);
          if (diskData.products.isNotEmpty) {
            _rebuildIndex(diskData.products);
            _cachedCatalog = diskData;
            return diskData;
          }
        } catch (e) {
          debugPrint('⚠️ [RETAIL CATALOG] Gagal baca disk cache ($scopeKey): $e');
        }
      }
      return PosCatalogData(
        products: const [],
        categories: const ['Semua'],
        catalogVersion: 1,
        businessType: 'retail',
      );
    }

    final catalogData = parsedCatalog;
    debugPrint(
      '🛒 [RETAIL CATALOG] Loaded ${catalogData.products.length} barang across ${catalogData.categories.length} kategori from $successfulEndpoint ($scopeKey)',
    );
    _rebuildIndex(catalogData.products);
    _cachedCatalog = catalogData;

    try {
      unawaited(SessionStorage.instance.saveCatalogCache(scopeKey, jsonEncode(response.data)));
    } catch (_) {}

    return catalogData;
  }

  /// Pencarian barang Retail ke backend
  Future<List<PosProduct>> searchProductsRemote(
    String query, {
    int limit = 50,
  }) async {
    _ensureTenantScope();
    final trimmed = query.trim();
    if (trimmed.isEmpty) return _cachedCatalog?.products ?? const [];

    final tenantId = SessionStorage.instance.getTenantId();
    final locId = SessionStorage.instance.getLocationId();
    final queryParams = <String, dynamic>{
      'search': trimmed,
      'q': trimmed,
      'limit': limit,
      'per_page': limit,
      if (tenantId != null && tenantId.isNotEmpty) 'tenant_id': tenantId,
      if (locId != null && locId.isNotEmpty) 'location_id': locId,
    };

    const candidateEndpoints = [
      '/v1/pos/products-sync',
      '/v1/pos/products',
    ];

    for (final ep in candidateEndpoints) {
      try {
        final res = await ApiClient.instance.dio.get(ep, queryParameters: queryParams);
        if (res.statusCode == 200 && res.data != null) {
          final parsed = _parseRetailCatalogData(res.data);
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
        debugPrint('⚠️ [RETAIL SEARCH] $ep gagal: $e');
      }
    }

    return searchFast(trimmed);
  }

  /// Parser khusus barang Retail / Grosir
  static PosProduct parseRetailProduct(Map<String, dynamic> json) {
    String productName = json.getString('name');
    if (productName.isEmpty || productName == '-') productName = json.getString('display_name');
    if (productName.isEmpty || productName == '-') productName = json.getString('product_name');
    if (productName.isEmpty || productName == '-') productName = json.getString('nama_produk');
    if (productName.isEmpty || productName == '-') productName = json.getString('item_name');
    if (productName.isEmpty || productName == '-') productName = 'Barang';
    productName = sanitizeDisplayName(productName);

    String categoryName = '';
    final rawCat = json['category'] ?? json['kategori'];
    if (rawCat is Map) {
      categoryName = sanitizeDisplayName(rawCat);
    } else if (rawCat is String) {
      categoryName = sanitizeDisplayName(rawCat);
    }
    if (categoryName.isEmpty || categoryName == '-') categoryName = json.getString('category_name');
    if (categoryName.isEmpty || categoryName == '-') categoryName = 'Umum';
    categoryName = sanitizeDisplayName(categoryName);

    double priceVal = json.getDouble('price');
    if (priceVal <= 0) priceVal = json.getDouble('selling_price');
    if (priceVal <= 0) priceVal = json.getDouble('harga_jual');
    if (priceVal <= 0) priceVal = json.getDouble('harga');
    if (priceVal <= 0) priceVal = json.getDouble('selling_price_1');

    final bool hasStockField = (json.containsKey('stock') && json['stock'] != null) ||
        (json.containsKey('stock_qty') && json['stock_qty'] != null) ||
        (json.containsKey('current_stock') && json['current_stock'] != null) ||
        (json.containsKey('stok') && json['stok'] != null) ||
        (json.containsKey('qty') && json['qty'] != null);

    double stockVal = 0.0;
    if (hasStockField) {
      stockVal = json.getDouble(
        'stock',
        fallback: json.getDouble(
          'stock_qty',
          fallback: json.getDouble('current_stock', fallback: json.getDouble('stok', fallback: json.getDouble('qty'))),
        ),
      );
    }

    String skuVal = json.getString('sku');
    if (skuVal.isEmpty || skuVal == '-') skuVal = json.getString('kode_produk');
    if (skuVal.isEmpty || skuVal == '-') skuVal = json.getString('code');

    String barcodeVal = json.getString('barcode');

    String unitVal = json.getString('unit');
    if (unitVal.isEmpty || unitVal == '-') unitVal = json.getString('satuan');
    if (unitVal.isEmpty || unitVal == '-') unitVal = json.getString('uom');
    if (unitVal.isEmpty || unitVal == '-') unitVal = 'PCS';
    unitVal = sanitizeDisplayName(unitVal).toUpperCase();

    final List<PosProductUnit> finalUnits = [];
    final rawUnits = json['units'] ?? json['product_units'] ?? json['multi_units'] ?? json['price_levels'];
    if (rawUnits is List) {
      for (final u in rawUnits) {
        if (u is Map) {
          finalUnits.add(PosProductUnit.fromJson(Map<String, dynamic>.from(u), defaultPrice: priceVal));
        }
      }
    }
    if (finalUnits.isEmpty) {
      finalUnits.add(PosProductUnit(name: unitVal, price: priceVal, conversion: 1, isDefault: true));
    }

    String img = json.getString('image_url');
    if (img.isEmpty || img == '-') img = json.getString('image');

    return PosProduct(
      id: json.getString('id'),
      name: productName,
      category: categoryName,
      categoryId: json['category_id']?.toString(),
      price: priceVal,
      stock: stockVal,
      sku: skuVal,
      barcode: barcodeVal,
      imageUrl: img.isNotEmpty && img != '-' ? img : null,
      unit: unitVal,
      isPrescriptionOnly: false,
      batches: const [],
      units: finalUnits,
      modifierGroups: const [],
    );
  }

  PosCatalogData _parseRetailCatalogData(dynamic rawData) {
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
          rawProducts.add(parseRetailProduct(Map<String, dynamic>.from(item)));
        } catch (e) {
          debugPrint('⚠️ [RETAIL CATALOG] Gagal parse barang: $e');
        }
      }
    }

    final categorySet = <String>{'Semua'};
    for (final item in categoryList) {
      final clean = sanitizeDisplayName(item is Map ? (item['name'] ?? item['category_name']) : item);
      if (clean.isNotEmpty && clean != 'Semua') categorySet.add(clean);
    }
    for (final p in rawProducts) {
      final clean = sanitizeDisplayName(p.category);
      if (clean.isNotEmpty && clean != 'Semua' && clean != 'Umum') {
        categorySet.add(clean);
      }
    }

    return PosCatalogData(
      products: rawProducts,
      categories: categorySet.toList(),
      modifiers: const [],
      catalogVersion: data.getInt('catalog_version', fallback: 1),
      businessType: 'retail',
    );
  }
}
