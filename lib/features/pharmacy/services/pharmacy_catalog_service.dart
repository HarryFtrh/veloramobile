import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/utils/safe_json.dart';
import '../../shared_pos/product_catalog_service.dart';

/// Layanan Katalog Khusus Bisnis APOTEK & KLINIK (Pharmacy).
/// Terisolasi penuh dari FnB (Cafe) dan Retail:
/// - Hanya menembak endpoint `/v1/pharmacy/*` dan `/v1/pos/products-sync` milik tenant Apotek aktif.
/// - Mengekstrak struktur obat (`global_product`, `batches`/`stocks` FEFO, `golongan`, `kandungan`, multi-satuan `TAB`/`STRIP`/`BOX`).
/// - Stok default selalu `0` jika belum ada batch/stok (tidak pernah `99` seperti menu Cafe).
/// - Cache memori dan disk dikunci ke `pharmacy_<tenantId>_<locationId>`.
class PharmacyCatalogService {
  static final PharmacyCatalogService instance = PharmacyCatalogService._();
  PharmacyCatalogService._();

  PosCatalogData? _cachedCatalog;
  String? _cachedScopeKey;
  PosCatalogData? get cachedCatalog => _cachedCatalog;

  final Map<String, PosProduct> _barcodeMap = {};
  final Map<String, PosProduct> _skuMap = {};
  final Map<String, PosProduct> _idMap = {};

  String _currentScopeKey() {
    final tenantId = SessionStorage.instance.getTenantId() ?? 'anon';
    final locId = SessionStorage.instance.getLocationId() ?? 'main';
    return 'pharmacy_${tenantId}_$locId';
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

  /// Pencarian cepat di memori lokal Apotek (Barcode -> SKU -> Nama Obat -> Kandungan -> Golongan)
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
            (p.description ?? '').toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q))
        .toList();
  }

  /// Ambil katalog obat siap jual untuk Kasir Apotek, Racikan, EMR Dokter, dan Stock Opname
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
      '/v1/pharmacy/products',
      '/v1/pharmacy/inventory',
      '/v1/pos/products',
    ];

    Response<dynamic>? response;
    PosCatalogData? parsedCatalog;
    String? successfulEndpoint;

    for (final ep in candidateEndpoints) {
      try {
        final res = await ApiClient.instance.dio.get(ep, queryParameters: queryParams);
        if (res.statusCode == 200 && res.data != null) {
          final candidateData = _parsePharmacyCatalogData(res.data);
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
        debugPrint('⚠️ [PHARMACY CATALOG] Endpoint $ep gagal: $e');
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
          final diskData = _parsePharmacyCatalogData(decoded);
          if (diskData.products.isNotEmpty) {
            _rebuildIndex(diskData.products);
            _cachedCatalog = diskData;
            return diskData;
          }
        } catch (e) {
          debugPrint('⚠️ [PHARMACY CATALOG] Gagal baca disk cache ($scopeKey): $e');
        }
      }
      return PosCatalogData(
        products: const [],
        categories: const ['Semua'],
        catalogVersion: 1,
        businessType: 'pharmacy',
      );
    }

    final catalogData = parsedCatalog;
    debugPrint(
      '💊 [PHARMACY CATALOG] Loaded ${catalogData.products.length} obat across ${catalogData.categories.length} golongan from $successfulEndpoint ($scopeKey)',
    );
    _rebuildIndex(catalogData.products);
    _cachedCatalog = catalogData;

    try {
      unawaited(SessionStorage.instance.saveCatalogCache(scopeKey, jsonEncode(response.data)));
    } catch (_) {}

    return catalogData;
  }

  /// Pencarian real-time obat via Laravel Scout / Meilisearch milik Tenant Apotek aktif
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
      '/v1/pharmacy/products',
      '/v1/pos/products-sync',
      '/v1/pharmacy/inventory',
    ];

    for (final ep in candidateEndpoints) {
      try {
        final res = await ApiClient.instance.dio.get(ep, queryParameters: queryParams);
        if (res.statusCode == 200 && res.data != null) {
          final parsed = _parsePharmacyCatalogData(res.data);
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
        debugPrint('⚠️ [PHARMACY SCOUT] $ep gagal: $e');
      }
    }

    return searchFast(trimmed);
  }

  /// Pindai barcode obat ke endpoint `/v1/pharmacy/pos/scan` atau `/v1/pharmacy/products/scan`
  Future<PosProduct?> scanBarcodeRemote(String barcode) async {
    _ensureTenantScope();
    final clean = barcode.trim();
    if (clean.isEmpty) return null;

    final local = findByBarcode(clean) ?? findBySku(clean);
    if (local != null) return local;

    final tenantId = SessionStorage.instance.getTenantId();
    final locId = SessionStorage.instance.getLocationId();
    final payload = <String, dynamic>{
      'barcode': clean,
      'code': clean,
      'sku': clean,
      if (tenantId != null && tenantId.isNotEmpty) 'tenant_id': tenantId,
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
            final p = parsePharmacyProduct(itemMap);
            if (p.id.isNotEmpty) _idMap[p.id] = p;
            if (p.barcode.isNotEmpty) _barcodeMap[p.barcode.trim().toLowerCase()] = p;
            if (p.sku.isNotEmpty) _skuMap[p.sku.trim().toLowerCase()] = p;
            return p;
          }
        }
      } catch (e) {
        debugPrint('⚠️ [PHARMACY SCAN] $ep gagal: $e');
      }
    }

    final scoutMatches = await searchProductsRemote(clean, limit: 5);
    if (scoutMatches.isNotEmpty) {
      return scoutMatches.first;
    }
    return null;
  }

  /// Parser khusus produk Farmasi (Obat, Alkes, Batch FEFO, Multi-Satuan, Golongan, Kandungan)
  static PosProduct parsePharmacyProduct(Map<String, dynamic> json) {
    final Map<String, dynamic> gp = (json['global_product'] is Map)
        ? Map<String, dynamic>.from(json['global_product'] as Map)
        : (json['product'] is Map ? Map<String, dynamic>.from(json['product'] as Map) : const {});

    var rawBatches = json.getList<PosProductBatch>(
      'batches',
      (item) => PosProductBatch.fromJson(item is Map<String, dynamic> ? item : null),
    );
    if (rawBatches.isEmpty) {
      rawBatches = json.getList<PosProductBatch>(
        'stocks',
        (item) => PosProductBatch.fromJson(item is Map<String, dynamic> ? item : null),
      );
    }
    if (rawBatches.isEmpty) {
      rawBatches = json.getList<PosProductBatch>(
        'product_batches',
        (item) => PosProductBatch.fromJson(item is Map<String, dynamic> ? item : null),
      );
    }

    String productName = json.getString('display_name');
    if (productName.isEmpty || productName == '-') productName = json.getString('name');
    if (productName.isEmpty || productName == '-') productName = json.getString('custom_name');
    if (productName.isEmpty || productName == '-') productName = json.getString('name_main');
    if (productName.isEmpty || productName == '-') productName = json.getString('nama_obat');
    if (productName.isEmpty || productName == '-') productName = gp.getString('display_name');
    if (productName.isEmpty || productName == '-') productName = gp.getString('name_main');
    if (productName.isEmpty || productName == '-') productName = gp.getString('name');
    if (productName.isEmpty || productName == '-') productName = 'Obat';
    productName = sanitizeDisplayName(productName);

    String categoryName = '';
    final rawCat = json['golongan'] ??
        json['category'] ??
        json['kategori'] ??
        json['klasifikasi'] ??
        gp['golongan'] ??
        gp['category'];
    if (rawCat is Map) {
      categoryName = sanitizeDisplayName(rawCat);
    } else if (rawCat is String) {
      categoryName = sanitizeDisplayName(rawCat);
    }
    if (categoryName.isEmpty || categoryName == '-') categoryName = json.getString('golongan_obat');
    if (categoryName.isEmpty || categoryName == '-') categoryName = json.getString('category_name');
    if (categoryName.isEmpty || categoryName == '-') categoryName = gp.getString('golongan');
    if (categoryName.isEmpty || categoryName == '-') categoryName = 'Obat Bebas';
    categoryName = sanitizeDisplayName(categoryName);

    double priceVal = json.getDouble('selling_price');
    if (priceVal <= 0) priceVal = json.getDouble('price');
    if (priceVal <= 0) priceVal = json.getDouble('harga_jual');
    if (priceVal <= 0) priceVal = json.getDouble('harga');
    if (priceVal <= 0) priceVal = json.getDouble('selling_price_1');
    if (priceVal <= 0) priceVal = gp.getDouble('selling_price');
    if (priceVal <= 0) priceVal = gp.getDouble('price');

    final bool hasStockField = (json.containsKey('stock') && json['stock'] != null) ||
        (json.containsKey('stock_qty') && json['stock_qty'] != null) ||
        (json.containsKey('total_stock') && json['total_stock'] != null) ||
        (json.containsKey('stok') && json['stok'] != null) ||
        (json.containsKey('current_stock') && json['current_stock'] != null) ||
        (json.containsKey('qty') && json['qty'] != null);

    double stockVal = 0.0;
    if (hasStockField) {
      stockVal = json.getDouble(
        'stock',
        fallback: json.getDouble(
          'stock_qty',
          fallback: json.getDouble(
            'total_stock',
            fallback: json.getDouble(
              'stok',
              fallback: json.getDouble('current_stock', fallback: json.getDouble('qty')),
            ),
          ),
        ),
      );
    } else if (rawBatches.isNotEmpty) {
      stockVal = rawBatches.fold<double>(0.0, (sum, b) => sum + b.stock);
    }

    String skuVal = json.getString('sku');
    if (skuVal.isEmpty || skuVal == '-') skuVal = json.getString('velora_id');
    if (skuVal.isEmpty || skuVal == '-') skuVal = json.getString('kode_obat');
    if (skuVal.isEmpty || skuVal == '-') skuVal = json.getString('code');
    if (skuVal.isEmpty || skuVal == '-') skuVal = gp.getString('velora_id');
    if (skuVal.isEmpty || skuVal == '-') skuVal = gp.getString('sku');

    String barcodeVal = json.getString('barcode');
    if (barcodeVal.isEmpty || barcodeVal == '-') barcodeVal = json.getString('barcode_master');
    if (barcodeVal.isEmpty || barcodeVal == '-') barcodeVal = gp.getString('barcode');

    final isRx = json.getBool('is_prescription_only') ||
        json.getBool('is_hard_drug') ||
        categoryName.toLowerCase().contains('keras') ||
        categoryName.toLowerCase().contains('narkotika') ||
        categoryName.toLowerCase().contains('psikotropika') ||
        categoryName.toLowerCase().contains('resep') ||
        json.getString('golongan').toLowerCase().contains('keras');

    String? singleBatch = json.getString('batch_number');
    if (singleBatch.isEmpty || singleBatch == '-') singleBatch = json.getString('batch');
    if (singleBatch.isEmpty || singleBatch == '-') singleBatch = json.getString('no_batch');

    String? singleExp = json.getString('expiry_date');
    if (singleExp.isEmpty || singleExp == '-') singleExp = json.getString('exp_date');
    if (singleExp.isEmpty || singleExp == '-') singleExp = json.getString('kadaluwarsa');
    if (singleExp.isEmpty || singleExp == '-') singleExp = json.getString('ed');

    final List<PosProductBatch> finalBatches = List.from(rawBatches);
    if (finalBatches.isEmpty &&
        ((singleBatch.isNotEmpty && singleBatch != '-') || (singleExp.isNotEmpty && singleExp != '-'))) {
      finalBatches.add(
        PosProductBatch(
          id: 'default',
          batchNumber: singleBatch.isNotEmpty ? singleBatch : '-',
          expiryDate: singleExp.isNotEmpty ? singleExp : '-',
          stock: stockVal,
        ),
      );
    }

    String unitStr = json.getString('unit');
    if (unitStr.isEmpty || unitStr == '-') unitStr = json.getString('base_unit');
    if (unitStr.isEmpty || unitStr == '-') unitStr = json.getString('satuan_terkecil');
    if (unitStr.isEmpty || unitStr == '-') unitStr = json.getString('satuan');
    if (unitStr.isEmpty || unitStr == '-') unitStr = json.getString('uom');
    if (unitStr.isEmpty || unitStr == '-') unitStr = gp.getString('base_unit');
    if (unitStr.isEmpty || unitStr == '-') unitStr = gp.getString('kemasan');
    if (unitStr.isEmpty || unitStr == '-') unitStr = 'TAB';
    unitStr = sanitizeDisplayName(unitStr).toUpperCase();

    final List<PosProductUnit> finalUnits = [];
    final rawUnitsList = json['units'] ??
        json['product_units'] ??
        json['satuan_list'] ??
        json['multi_units'] ??
        json['unit_prices'] ??
        json['conversions'];
    if (rawUnitsList is List) {
      for (final u in rawUnitsList) {
        if (u is Map) {
          finalUnits.add(PosProductUnit.fromJson(Map<String, dynamic>.from(u), defaultPrice: priceVal));
        } else if (u is String && u.trim().isNotEmpty) {
          finalUnits.add(PosProductUnit(name: u.trim().toUpperCase(), price: priceVal, conversion: 1));
        }
      }
    }

    if (finalUnits.isEmpty) {
      final u1 = json.getString('unit_1', fallback: json.getString('satuan_1'));
      final u2 = json.getString('unit_2', fallback: json.getString('satuan_2'));
      final u3 = json.getString('unit_3', fallback: json.getString('satuan_3'));
      final sp1 = json.getDouble('selling_price_1', fallback: priceVal);
      final sp2 = json.getDouble('selling_price_2');
      final sp3 = json.getDouble('selling_price_3');

      if (u1.isNotEmpty && u1 != '-') {
        finalUnits.add(PosProductUnit(name: u1.toUpperCase(), price: sp1, conversion: 1, isDefault: true));
      }
      if (u2.isNotEmpty && u2 != '-' && sp2 > 0) {
        finalUnits.add(PosProductUnit(name: u2.toUpperCase(), price: sp2, conversion: 1));
      }
      if (u3.isNotEmpty && u3 != '-' && sp3 > 0) {
        finalUnits.add(PosProductUnit(name: u3.toUpperCase(), price: sp3, conversion: 1));
      }
    }

    if (finalUnits.isEmpty) {
      finalUnits.add(PosProductUnit(name: unitStr, price: priceVal, conversion: 1, isDefault: true));
    }

    if (finalUnits.length == 1) {
      final baseU = finalUnits.first.name.toUpperCase();
      final baseP = finalUnits.first.price;
      if (baseU == 'TAB' || baseU == 'KAP' || baseU == 'CAP' || baseU == 'PCS') {
        finalUnits.add(PosProductUnit(name: 'STRIP', price: (baseP * 10).round(), conversion: 10));
        finalUnits.add(PosProductUnit(name: 'BOX', price: (baseP * 100).round(), conversion: 100));
      } else if (baseU == 'STRIP') {
        finalUnits.insert(0, PosProductUnit(name: 'TAB', price: (baseP / 10).round(), conversion: 1));
        finalUnits.add(PosProductUnit(name: 'BOX', price: (baseP * 10).round(), conversion: 10));
      } else if (baseU == 'FLS' || baseU == 'BTL' || baseU == 'TUBE') {
        finalUnits.add(PosProductUnit(name: 'BOX', price: (baseP * 10).round(), conversion: 10));
      }
    }

    final rawDesc = json.getString('description').isNotEmpty
        ? json.getString('description')
        : (json.getString('kandungan').isNotEmpty
            ? json.getString('kandungan')
            : (json.getString('composition').isNotEmpty
                ? json.getString('composition')
                : (gp.getString('kandungan').isNotEmpty
                    ? gp.getString('kandungan')
                    : gp.getString('composition'))));

    final rawImg = json.getString('image_url').isNotEmpty
        ? json.getString('image_url')
        : (json.getString('image').isNotEmpty ? json.getString('image') : gp.getString('image_url'));

    return PosProduct(
      id: json.getString('id', fallback: json.getString('pharmacy_product_id', fallback: json.getString('product_id'))),
      name: productName,
      category: categoryName,
      categoryId: json['category_id']?.toString(),
      price: priceVal,
      stock: stockVal,
      sku: skuVal,
      barcode: barcodeVal,
      unit: unitStr,
      imageUrl: rawImg.isNotEmpty ? rawImg : null,
      tag: json['tag']?.toString(),
      description: rawDesc.isNotEmpty ? rawDesc : null,
      isPrescriptionOnly: isRx,
      batches: finalBatches,
      units: finalUnits,
      modifierGroups: const [],
    );
  }

  PosCatalogData _parsePharmacyCatalogData(dynamic rawData) {
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
          rawProducts.add(parsePharmacyProduct(Map<String, dynamic>.from(item)));
        } catch (e) {
          debugPrint('⚠️ [PHARMACY CATALOG] Gagal parse obat: $e');
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
      businessType: 'pharmacy',
    );
  }
}
