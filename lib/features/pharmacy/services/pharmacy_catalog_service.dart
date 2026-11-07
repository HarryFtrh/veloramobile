import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/utils/safe_json.dart';
import '../../shared_pos/models/pos_catalog_models.dart';

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
  final Map<String, List<PosProductBatch>> _cachedBatchMap = {};
  final Map<String, List<PosProductBatch>> _cachedBatchByNameMap = {};

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
    _cachedBatchMap.clear();
    _cachedBatchByNameMap.clear();
  }

  /// Sinkronkan batch obat FEFO dari `/v1/pharmacy/inventory/batches`
  Future<void> _fetchAndCacheBatches(String? locId) async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/v1/pharmacy/inventory/batches',
        queryParameters: {
          if (locId != null && locId.isNotEmpty) 'location_id': locId,
          'limit': 250,
        },
      );
      if (res.statusCode == 200 && res.data != null) {
        final raw = res.data;
        List items = [];
        if (raw is List) {
          items = raw;
        } else if (raw is Map) {
          final d = raw['data'] ?? raw['batches'] ?? raw['items'];
          if (d is List) {
            items = d;
          } else if (d is Map && d['data'] is List) {
            items = d['data'] as List;
          }
        }
        if (items.isNotEmpty) {
          _cachedBatchMap.clear();
          _cachedBatchByNameMap.clear();
          for (final item in items) {
            if (item is Map) {
              final m = Map<String, dynamic>.from(item);
              final prodId = (m['pharmacy_product_id'] ??
                      m['product_id'] ??
                      (m['product'] is Map ? m['product']['id'] : null))
                  ?.toString();
              final prodName = (m['product_name'] ??
                      (m['product'] is Map
                          ? (m['product']['custom_name'] ?? m['product']['name_main'])
                          : null) ??
                      m['name'])
                  ?.toString()
                  .trim()
                  .toLowerCase();
              final batch = PosProductBatch.fromJson(m);
              if ((batch.batchNumber.isNotEmpty && batch.batchNumber != '-') ||
                  (batch.expiryDate.isNotEmpty && batch.expiryDate != '-')) {
                if (prodId != null && prodId.isNotEmpty) {
                  _cachedBatchMap.putIfAbsent(prodId, () => []).add(batch);
                }
                if (prodName != null && prodName.isNotEmpty) {
                  _cachedBatchByNameMap.putIfAbsent(prodName, () => []).add(batch);
                  final norm = prodName.replaceAll(RegExp(r'\s+'), '');
                  if (norm != prodName) {
                    _cachedBatchByNameMap.putIfAbsent(norm, () => []).add(batch);
                  }
                }
              }
            }
          }

          void sortBatches(List<PosProductBatch> list) {
            list.sort((a, b) {
              if (a.expiryDate == '-' && b.expiryDate == '-') return 0;
              if (a.expiryDate == '-') return 1;
              if (b.expiryDate == '-') return -1;
              return a.expiryDate.compareTo(b.expiryDate);
            });
          }

          _cachedBatchMap.values.forEach(sortBatches);
          _cachedBatchByNameMap.values.forEach(sortBatches);
        }
      }
    } catch (e) {
      debugPrint('ℹ️ [PHARMACY BATCHES] /v1/pharmacy/inventory/batches: $e');
    }
  }

  /// Sisipkan data batch & ED FEFO ke dalam daftar produk yang belum memiliki batch
  List<PosProduct> enrichProductsWithBatches(List<PosProduct> products) {
    if (_cachedBatchMap.isEmpty && _cachedBatchByNameMap.isEmpty) {
      return products;
    }
    return products.map((p) {
      if (p.batches.isNotEmpty && p.batches.any((b) => b.batchNumber != '-')) {
        return p;
      }
      final norm = p.name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
      final bList = _cachedBatchMap[p.id] ??
          _cachedBatchByNameMap[p.name.trim().toLowerCase()] ??
          _cachedBatchByNameMap[norm];
      if (bList != null && bList.isNotEmpty) {
        return p.copyWith(batches: bList);
      }
      return p;
    }).toList();
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

  /// Kamus sinonim singkatan farmasi (selaras dengan `GlobalProduct::generateSearchTokens()` di backend)
  static const Map<String, String> _pharmacyAbbreviations = {
    'pct': 'paracetamol',
    'pcm': 'paracetamol',
    'parasetamol': 'paracetamol',
    'ctm': 'chlorpheniramine',
    'asmef': 'asam mefenamat',
    'mefenamat': 'asam mefenamat',
    'amox': 'amoxicillin',
    'amoksisilin': 'amoxicillin',
    'dexa': 'dexamethasone',
    'deksametason': 'dexamethasone',
    'ome': 'omeprazole',
    'lansop': 'lansoprazole',
    'amlod': 'amlodipine',
    'simvas': 'simvastatin',
    'cefa': 'cefadroxil',
    'cetir': 'cetirizine',
    'ranit': 'ranitidine',
    'metfor': 'metformin',
    'glime': 'glimepiride',
    'capto': 'captopril',
    'cande': 'candesartan',
    'vit c': 'vitamin c',
    'vit b': 'vitamin b',
  };

  /// Ekspansi singkatan farmasi (misal `"pct 500"` -> `"paracetamol 500"`, `"pct"` -> `"paracetamol"`)
  static String expandPharmacyQuery(String rawQuery) {
    final trimmed = rawQuery.trim().toLowerCase();
    if (trimmed.isEmpty) return trimmed;
    if (_pharmacyAbbreviations.containsKey(trimmed)) {
      return _pharmacyAbbreviations[trimmed]!;
    }
    final words = trimmed.split(RegExp(r'\s+'));
    final replaced = words.map((w) => _pharmacyAbbreviations[w] ?? w).toList();
    return replaced.join(' ');
  }

  /// Pencarian cepat di memori lokal Apotek (Barcode -> SKU -> Nama Obat -> Kandungan -> Fungsi/Indikasi -> Klasifikasi -> Golongan)
  List<PosProduct> searchFast(String query) {
    _ensureTenantScope();
    if (query.isEmpty) return _cachedCatalog?.products ?? const [];
    final q = query.trim().toLowerCase();
    final expanded = expandPharmacyQuery(q);

    final bMatch = _barcodeMap[q];
    if (bMatch != null) return [bMatch];

    final sMatch = _skuMap[q];
    if (sMatch != null) return [sMatch];

    final list = _cachedCatalog?.products ?? const [];
    return list
        .where((p) => p.matchesQuery(q) || (expanded != q && p.matchesQuery(expanded)))
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
        parsedCatalog = _parsePharmacyCatalogData(res.data);
      }
    } catch (e) {
      debugPrint('⚠️ [PHARMACY CATALOG] /v1/pos/products-sync gagal: $e');
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
      '💊 [PHARMACY CATALOG] Loaded ${catalogData.products.length} obat across ${catalogData.categories.length} golongan from /v1/pos/products-sync ($scopeKey)',
    );

    // Sinkronkan batch dan tanggal kadaluwarsa (FEFO) jika belum ada di data produk
    PosCatalogData finalCatalog = catalogData;
    if (catalogData.products.any((p) => p.batches.isEmpty)) {
      await _fetchAndCacheBatches(locId);
      final enrichedProducts = enrichProductsWithBatches(catalogData.products);
      finalCatalog = PosCatalogData(
        products: enrichedProducts,
        categories: catalogData.categories,
        catalogVersion: catalogData.catalogVersion,
        businessType: catalogData.businessType,
      );
    }

    _rebuildIndex(finalCatalog.products);
    _cachedCatalog = finalCatalog;

    try {
      unawaited(SessionStorage.instance.saveCatalogCache(scopeKey, jsonEncode(response.data)));
    } catch (_) {}

    return finalCatalog;
  }

  /// Pencarian obat langsung ke Unified POS Engine (`/v1/pos/products` & `/v1/pos/products-sync`)
  /// Backend ditenagai oleh PharmacyPosStrategy & Laravel Scout Meilisearch (519 sinonim farmasi)
  Future<List<PosProduct>> searchProductsRemote(
    String query, {
    int limit = 50,
  }) async {
    _ensureTenantScope();
    final trimmed = query.trim();
    if (trimmed.isEmpty) return _cachedCatalog?.products ?? const [];

    final locId = SessionStorage.instance.getLocationId();
    final queryParams = <String, dynamic>{
      'search': trimmed,
      'limit': limit,
      if (locId != null && locId.isNotEmpty) 'location_id': locId,
    };

    // 1. Unified POS Products API (PharmacyPosStrategy::search via Meilisearch)
    try {
      final res = await ApiClient.instance.dio.get(
        '/v1/pos/products',
        queryParameters: queryParams,
      );
      if (res.statusCode == 200 && res.data != null) {
        final parsed = _parsePharmacyCatalogData(res.data);
        if (parsed.products.isNotEmpty) {
          final enriched = enrichProductsWithBatches(parsed.products);
          for (final p in enriched) {
            if (p.id.isNotEmpty) _idMap[p.id] = p;
            if (p.barcode.isNotEmpty) _barcodeMap[p.barcode.trim().toLowerCase()] = p;
            if (p.sku.isNotEmpty) _skuMap[p.sku.trim().toLowerCase()] = p;
          }
          return enriched;
        }
      }
    } catch (e) {
      debugPrint('ℹ️ [PHARMACY SEARCH] /v1/pos/products: $e');
    }

    // 2. Fallback ke /v1/pos/products-sync
    try {
      final res = await ApiClient.instance.dio.get(
        '/v1/pos/products-sync',
        queryParameters: queryParams,
      );
      if (res.statusCode == 200 && res.data != null) {
        final parsed = _parsePharmacyCatalogData(res.data);
        if (parsed.products.isNotEmpty) {
          final enriched = enrichProductsWithBatches(parsed.products);
          for (final p in enriched) {
            if (p.id.isNotEmpty) _idMap[p.id] = p;
            if (p.barcode.isNotEmpty) _barcodeMap[p.barcode.trim().toLowerCase()] = p;
            if (p.sku.isNotEmpty) _skuMap[p.sku.trim().toLowerCase()] = p;
          }
          return enriched;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [PHARMACY SEARCH] /v1/pos/products-sync: $e');
    }

    return searchFast(trimmed);
  }

  /// Pindai barcode obat melalui 1 endpoint resmi POS (`POST /v1/pos/scan`)
  Future<PosProduct?> scanBarcodeRemote(String barcode) async {
    _ensureTenantScope();
    final clean = barcode.trim();
    if (clean.isEmpty) return null;

    final local = findByBarcode(clean) ?? findBySku(clean);
    if (local != null) return local;

    final locId = SessionStorage.instance.getLocationId();
    try {
      final res = await ApiClient.instance.dio.post(
        '/v1/pos/scan',
        data: {
          'barcode': clean,
          if (locId != null && locId.isNotEmpty) 'location_id': locId,
        },
      );
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
          final enrichedP = enrichProductsWithBatches([p]).first;
          if (enrichedP.id.isNotEmpty) _idMap[enrichedP.id] = enrichedP;
          if (enrichedP.barcode.isNotEmpty) _barcodeMap[enrichedP.barcode.trim().toLowerCase()] = enrichedP;
          if (enrichedP.sku.isNotEmpty) _skuMap[enrichedP.sku.trim().toLowerCase()] = enrichedP;
          return enrichedP;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [PHARMACY SCAN] /v1/pos/scan gagal: $e');
    }

    return null;
  }

  /// Parser khusus produk Farmasi sesuai skema `PharmacyPosStrategy` & `PharmacyProduct` di backend Velora:
  /// - Kolom utama: `id, tenant_id, velora_id, name_main, custom_name, ratio_1, ratio_2, ratio_3, unit_1, unit_2, unit_3, barcode_master, selling_price, selling_price_1, selling_price_2, selling_price_3, golongan, klasifikasi, fungsi, kandungan, sediaan, is_narcotic, is_psychotropic, is_precursor, is_oot, is_active, image, stocks`
  static PosProduct parsePharmacyProduct(Map<String, dynamic> rawJson) {
    // Jika item berasal dari /v1/pharmacy/inventory (PharmacyStock wrapper dengan relasi 'product'),
    // gabungkan atribut produk di dalam 'product' ke level utama sambil mempertahankan total_stock & batches
    final Map<String, dynamic> json;
    if (rawJson['product'] is Map && rawJson['pharmacy_product_id'] != null) {
      final prodMap = Map<String, dynamic>.from(rawJson['product'] as Map);
      json = {
        ...prodMap,
        'id': prodMap['id'] ?? rawJson['pharmacy_product_id'],
        'total_stock': rawJson['total_stock'] ?? prodMap['total_stock'],
        'batches': rawJson['batches'] ?? prodMap['batches'],
      };
    } else {
      json = rawJson;
    }

    final Map<String, dynamic> gp = (json['global_product'] is Map)
        ? Map<String, dynamic>.from(json['global_product'] as Map)
        : (json['globalProduct'] is Map
            ? Map<String, dynamic>.from(json['globalProduct'] as Map)
            : (json['product'] is Map ? Map<String, dynamic>.from(json['product'] as Map) : const {}));

    var rawBatches = json.getList<PosProductBatch>(
      'batches',
      (item) => PosProductBatch.fromJson(item is Map<String, dynamic> ? item : null),
    );
    if (rawBatches.isEmpty && json['product_batches'] is List) {
      rawBatches = json.getList<PosProductBatch>(
        'product_batches',
        (item) => PosProductBatch.fromJson(item is Map<String, dynamic> ? item : null),
      );
    }
    if (rawBatches.isEmpty && json['stocks'] is List) {
      final stocksList = json['stocks'] as List;
      final extracted = <PosProductBatch>[];
      for (final s in stocksList) {
        if (s is Map) {
          if (s['batches'] is List) {
            for (final b in (s['batches'] as List)) {
              if (b is Map) {
                extracted.add(PosProductBatch.fromJson(Map<String, dynamic>.from(b)));
              }
            }
          } else if (s['product_batches'] is List) {
            for (final b in (s['product_batches'] as List)) {
              if (b is Map) {
                extracted.add(PosProductBatch.fromJson(Map<String, dynamic>.from(b)));
              }
            }
          } else if (s['batch_no'] != null ||
              s['batch_number'] != null ||
              s['batch'] != null ||
              s['expired_date'] != null ||
              s['expiry_date'] != null ||
              s['exp_date'] != null) {
            extracted.add(PosProductBatch.fromJson(Map<String, dynamic>.from(s)));
          }
        }
      }
      rawBatches = extracted;
    }

    // Ekstraksi langsung jika batch/exp ada di level produk
    if (rawBatches.isEmpty) {
      final bDirect = json.getString('batch_number',
          fallback: json.getString('batch_no',
              fallback: json.getString('batch',
                  fallback: json.getString('no_batch',
                      fallback: rawJson.getString('batch_number',
                          fallback: rawJson.getString('batch_no',
                              fallback: rawJson.getString('batch')))))));
      final eDirect = json.getString('expired_date',
          fallback: json.getString('expiry_date',
              fallback: json.getString('exp_date',
                  fallback: json.getString('ed',
                      fallback: json.getString('kadaluwarsa',
                          fallback: rawJson.getString('expired_date',
                              fallback: rawJson.getString('expiry_date',
                                  fallback: rawJson.getString('exp_date'))))))));

      if ((bDirect.isNotEmpty && bDirect != '-') || (eDirect.isNotEmpty && eDirect != '-')) {
        rawBatches = [
          PosProductBatch(
            id: json.getString('id', fallback: rawJson.getString('id')),
            batchNumber: bDirect.isNotEmpty ? bDirect : '-',
            expiryDate: eDirect.isNotEmpty ? eDirect : '-',
            stock: json.getDouble('total_stock', fallback: json.getDouble('stock', fallback: rawJson.getDouble('stock'))),
          ),
        ];
      }
    }

    // Sesuai PharmacyProductMarketplaceService: custom_name diutamakan di atas name_main
    String productName = json.getString('custom_name');
    if (productName.isEmpty || productName == '-') productName = json.getString('name_main');
    if (productName.isEmpty || productName == '-') productName = json.getString('display_name');
    if (productName.isEmpty || productName == '-') productName = json.getString('name');
    if (productName.isEmpty || productName == '-') productName = gp.getString('name_main');
    if (productName.isEmpty || productName == '-') productName = gp.getString('name');
    if (productName.isEmpty || productName == '-') productName = 'Obat';
    productName = sanitizeDisplayName(productName);

    String categoryName = '';
    final rawCat = json['golongan'] ??
        json['klasifikasi'] ??
        json['fungsi'] ??
        json['sediaan'] ??
        json['category'] ??
        gp['golongan'] ??
        gp['klasifikasi'];
    if (rawCat is Map) {
      categoryName = sanitizeDisplayName(rawCat);
    } else if (rawCat is String) {
      categoryName = sanitizeDisplayName(rawCat);
    }
    if (categoryName.isEmpty || categoryName == '-') categoryName = 'Obat Bebas';
    categoryName = sanitizeDisplayName(categoryName);

    // Sesuai PharmacyProductCrudService: selling_price default adalah selling_price_3 (satuan terkecil)
    double priceVal = json.getDouble('selling_price');
    if (priceVal <= 0) priceVal = json.getDouble('selling_price_3');
    if (priceVal <= 0) priceVal = json.getDouble('selling_price_2');
    if (priceVal <= 0) priceVal = json.getDouble('selling_price_1');
    if (priceVal <= 0) priceVal = json.getDouble('price');
    if (priceVal <= 0) priceVal = gp.getDouble('selling_price');

    final bool hasStockField = (json.containsKey('stock') && json['stock'] != null) ||
        (json.containsKey('total_stock') && json['total_stock'] != null) ||
        (json.containsKey('total_physical_stock') && json['total_physical_stock'] != null) ||
        (json.containsKey('stock_qty') && json['stock_qty'] != null);

    double stockVal = 0.0;
    if (hasStockField) {
      stockVal = json.getDouble(
        'stock',
        fallback: json.getDouble(
          'total_stock',
          fallback: json.getDouble('total_physical_stock', fallback: json.getDouble('stock_qty')),
        ),
      );
    } else if (json['stocks'] is List && (json['stocks'] as List).isNotEmpty) {
      for (final s in (json['stocks'] as List)) {
        if (s is Map) {
          stockVal += Map<String, dynamic>.from(s).getDouble(
            'total_stock',
            fallback: Map<String, dynamic>.from(s).getDouble('stock', fallback: Map<String, dynamic>.from(s).getDouble('quantity')),
          );
        }
      }
    } else if (rawBatches.isNotEmpty) {
      stockVal = rawBatches.fold<double>(0.0, (sum, b) => sum + b.stock);
    }

    String skuVal = json.getString('velora_id');
    if (skuVal.isEmpty || skuVal == '-') skuVal = json.getString('sku');
    if (skuVal.isEmpty || skuVal == '-') skuVal = gp.getString('velora_id');

    String barcodeVal = json.getString('barcode_master');
    if (barcodeVal.isEmpty || barcodeVal == '-') barcodeVal = json.getString('barcode');
    if (barcodeVal.isEmpty || barcodeVal == '-') barcodeVal = gp.getString('barcode');

    final bool isExplicitlyBebasTerbatas = categoryName.toLowerCase().contains('terbatas') ||
        json.getString('golongan').toLowerCase().contains('terbatas');
    final bool isExplicitlyBebas = (categoryName.toLowerCase().contains('bebas') && !isExplicitlyBebasTerbatas) ||
        (json.getString('golongan').toLowerCase().contains('bebas') && !isExplicitlyBebasTerbatas);

    final isRx = !isExplicitlyBebas && !isExplicitlyBebasTerbatas && (
        json.getBool('is_narcotic') ||
        json.getBool('is_psychotropic') ||
        json.getBool('is_precursor') ||
        json.getBool('is_prescription_only') ||
        json.getBool('is_hard_drug') ||
        categoryName.toLowerCase().contains('keras') ||
        categoryName.toLowerCase().contains('narkotika') ||
        categoryName.toLowerCase().contains('psikotropika') ||
        categoryName.toLowerCase().contains('prekursor') ||
        json.getString('golongan').toLowerCase().contains('keras')
    );

    String? singleBatch = json.getString('batch_no');
    if (singleBatch.isEmpty || singleBatch == '-') singleBatch = json.getString('batch_number');
    if (singleBatch.isEmpty || singleBatch == '-') singleBatch = json.getString('batch');
    if (singleBatch.isEmpty || singleBatch == '-') singleBatch = json.getString('no_batch');
    if (singleBatch.isEmpty || singleBatch == '-') singleBatch = json.getString('lot_no');
    if (singleBatch.isEmpty || singleBatch == '-') singleBatch = json.getString('lot_number');
    if (singleBatch.isEmpty || singleBatch == '-') singleBatch = json.getString('kode_batch');

    String? singleExp = json.getString('expired_date');
    if (singleExp.isEmpty || singleExp == '-') singleExp = json.getString('expiry_date');
    if (singleExp.isEmpty || singleExp == '-') singleExp = json.getString('exp_date');
    if (singleExp.isEmpty || singleExp == '-') singleExp = json.getString('expired_at');
    if (singleExp.isEmpty || singleExp == '-') singleExp = json.getString('kadaluwarsa');
    if (singleExp.isEmpty || singleExp == '-') singleExp = json.getString('tgl_kadaluarsa');
    if (singleExp.isEmpty || singleExp == '-') singleExp = json.getString('tanggal_kadaluwarsa');
    if (singleExp.isEmpty || singleExp == '-') singleExp = json.getString('exp');

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

    // Skema Multi-Satuan PharmacyProduct di Backend:
    // unit_3 = satuan terkecil/dasar POS (misal TAB/KAP/PCS), ratio_3, selling_price_3
    // unit_2 = satuan menengah (misal STRIP/BLISTER), ratio_2, selling_price_2
    // unit_1 = satuan terbesar (misal BOX/FLS), ratio_1, selling_price_1
    final u3 = json.getString('unit_3', fallback: gp.getString('unit_3'));
    final u2 = json.getString('unit_2', fallback: gp.getString('unit_2'));
    final u1 = json.getString('unit_1', fallback: gp.getString('unit_1'));
    final r3 = json.getDouble('ratio_3', fallback: gp.getDouble('ratio_3', fallback: 1.0));
    final r2 = json.getDouble('ratio_2', fallback: gp.getDouble('ratio_2', fallback: 1.0));
    final r1 = json.getDouble('ratio_1', fallback: gp.getDouble('ratio_1', fallback: 1.0));
    final sp3 = json.getDouble('selling_price_3', fallback: priceVal);
    final sp2 = json.getDouble('selling_price_2');
    final sp1 = json.getDouble('selling_price_1');

    String unitStr = u3.isNotEmpty && u3 != '-'
        ? u3
        : (u2.isNotEmpty && u2 != '-'
            ? u2
            : (u1.isNotEmpty && u1 != '-' ? u1 : json.getString('unit', fallback: 'TAB')));
    unitStr = sanitizeDisplayName(unitStr).toUpperCase();

    final List<PosProductUnit> finalUnits = [];
    final rawUnitsList = json['units'] ?? json['product_units'];
    if (rawUnitsList is List) {
      for (final u in rawUnitsList) {
        if (u is Map) {
          finalUnits.add(PosProductUnit.fromJson(Map<String, dynamic>.from(u), defaultPrice: priceVal));
        }
      }
    }

    if (finalUnits.isEmpty) {
      final seenUnits = <String>{};
      if (u3.isNotEmpty && u3 != '-') {
        final name3 = u3.trim().toUpperCase();
        seenUnits.add(name3);
        finalUnits.add(
          PosProductUnit(
            name: name3,
            price: sp3 > 0 ? sp3 : priceVal,
            conversion: r3 > 0 ? r3 : 1,
            isDefault: true,
          ),
        );
      }
      if (u2.isNotEmpty && u2 != '-' && sp2 > 0) {
        final name2 = u2.trim().toUpperCase();
        if (seenUnits.add(name2)) {
          finalUnits.add(
            PosProductUnit(
              name: name2,
              price: sp2,
              conversion: r2 > 0 ? r2 : 1,
              isDefault: finalUnits.isEmpty,
            ),
          );
        }
      }
      if (u1.isNotEmpty && u1 != '-' && sp1 > 0) {
        final name1 = u1.trim().toUpperCase();
        if (seenUnits.add(name1)) {
          finalUnits.add(
            PosProductUnit(
              name: name1,
              price: sp1,
              conversion: r1 > 0 ? r1 : 1,
              isDefault: finalUnits.isEmpty,
            ),
          );
        }
      }
    }

    if (finalUnits.isEmpty) {
      finalUnits.add(PosProductUnit(name: unitStr, price: priceVal, conversion: 1, isDefault: true));
    }

    final rawKandungan = json.getString('kandungan', fallback: gp.getString('kandungan'));
    final rawFungsi = json.getString('fungsi', fallback: gp.getString('fungsi'));
    final rawKlasifikasi = json.getString('klasifikasi', fallback: gp.getString('klasifikasi'));
    final rawSediaan = json.getString('sediaan', fallback: gp.getString('sediaan'));

    String rawDesc = '';
    if (rawKandungan.isNotEmpty && rawFungsi.isNotEmpty) {
      rawDesc = '$rawKandungan • $rawFungsi';
    } else if (rawKandungan.isNotEmpty) {
      rawDesc = rawKandungan;
    } else if (rawFungsi.isNotEmpty) {
      rawDesc = rawFungsi;
    } else if (rawKlasifikasi.isNotEmpty) {
      rawDesc = rawKlasifikasi;
    } else {
      rawDesc = json.getString('description', fallback: gp.getString('description'));
    }

    final resolvedImgUrl = PosProduct.resolveImageUrl(json.getString('image_url')) ??
        PosProduct.resolveImageUrl(json.getString('image')) ??
        PosProduct.resolveImageUrl(gp.getString('image_url')) ??
        PosProduct.resolveImageUrl(gp.getString('image')) ??
        PosProduct.resolveImageUrl(json.getString('photo_url')) ??
        PosProduct.resolveImageUrl(json.getString('thumbnail'));

    return PosProduct(
      id: json.getString('id', fallback: json.getString('pharmacy_product_id')),
      name: productName,
      category: categoryName,
      categoryId: json['category_id']?.toString() ?? json['golongan']?.toString(),
      price: priceVal,
      stock: stockVal,
      sku: skuVal,
      barcode: barcodeVal,
      unit: unitStr,
      imageUrl: resolvedImgUrl,
      tag: rawSediaan.isNotEmpty ? rawSediaan : (rawKlasifikasi.isNotEmpty ? rawKlasifikasi : null),
      description: rawDesc.isNotEmpty ? rawDesc : null,
      fungsi: rawFungsi.isNotEmpty ? rawFungsi : null,
      kandungan: rawKandungan.isNotEmpty ? rawKandungan : null,
      klasifikasi: rawKlasifikasi.isNotEmpty ? rawKlasifikasi : null,
      sediaan: rawSediaan.isNotEmpty ? rawSediaan : null,
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
        final p = data['products'] ?? data['items'] ?? data['data'] ?? data['results'] ?? data['hits'];
        if (p is List) productList = p;
        final c = data['categories'] ?? data['category_list'];
        if (c is List) categoryList = c;
      } else if (inner is List) {
        productList = inner;
        data = Map<String, dynamic>.from(rawData);
      } else {
        data = Map<String, dynamic>.from(rawData);
        final p = data['products'] ?? data['items'] ?? data['data'] ?? data['results'] ?? data['hits'];
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
