import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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
    return PosProductBatch(
      id: json.getString('id'),
      batchNumber: json.getString('batch_number', fallback: '-'),
      expiryDate: json.getString('expiry_date', fallback: '-'),
      stock: json.getDouble('stock'),
    );
  }
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
  final bool isPrescriptionOnly;
  final List<PosProductBatch> batches;
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
    this.isPrescriptionOnly = false,
    this.batches = const [],
    this.modifierGroups = const [],
  });

  factory PosProduct.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return PosProduct(id: '', name: '', category: '', price: 0, stock: 0, sku: '', barcode: '');
    }

    final rawBatches = json.getList<PosProductBatch>(
      'batches',
      (item) => PosProductBatch.fromJson(item is Map<String, dynamic> ? item : null),
    );

    // Product name: handles Cafe/Retail 'name' and Pharmacy 'custom_name'/'name_main'
    String productName = json.getString('name');
    if (productName.isEmpty || productName == '-') {
      productName = json.getString('custom_name');
    }
    if (productName.isEmpty || productName == '-') {
      productName = json.getString('name_main', fallback: 'Produk');
    }
    productName = sanitizeDisplayName(productName);

    // Category name: handles Cafe/Retail 'category' and Pharmacy 'golongan'/'klasifikasi'/'fungsi'
    String categoryName = '';
    final rawCat = json['category'];
    if (rawCat is Map) {
      categoryName = sanitizeDisplayName(rawCat);
    } else {
      categoryName = json.getString('category');
    }
    if (categoryName.isEmpty || categoryName == '-') {
      categoryName = json.getString('golongan');
    }
    if (categoryName.isEmpty || categoryName == '-') {
      categoryName = json.getString('klasifikasi');
    }
    if (categoryName.isEmpty || categoryName == '-') {
      categoryName = 'Umum';
    }
    categoryName = sanitizeDisplayName(categoryName);

    // Selling price: handles 'price', 'selling_price', or tiered 'selling_price_1'
    double priceVal = json.getDouble('price');
    if (priceVal <= 0) {
      priceVal = json.getDouble('selling_price');
    }
    if (priceVal <= 0) {
      priceVal = json.getDouble('selling_price_1');
    }

    // Stock: handles 'stock' or 'stock_qty'
    // Pada bisnis FnB (Cafe/Resto), menu makanan & minuman dibuat berdasarkan resep/bahan baku
    // dan tidak selalu memiliki kuantitas stok fisik terbatas di JSON sinkronisasi.
    // Jika backend tidak menyertakan field stok, produk dianggap selalu TERSEDIA (default 99).
    // Produk hanya berstatus habis jika backend secara eksplisit mengirimkan stock = 0 atau is_available = false.
    final bool hasStockField = (json.containsKey('stock') && json['stock'] != null) ||
        (json.containsKey('stock_qty') && json['stock_qty'] != null);
    final bool isExplicitlyUnavailable = json.getBool('is_out_of_stock') ||
        json.getString('status').toLowerCase() == 'out_of_stock' ||
        (json.containsKey('is_available') && json.getBool('is_available') == false);

    double stockVal;
    if (isExplicitlyUnavailable) {
      stockVal = 0.0;
    } else if (hasStockField) {
      stockVal = json.getDouble('stock', fallback: json.getDouble('stock_qty'));
    } else {
      stockVal = 99.0;
    }

    // SKU & Barcode: handles 'sku'/'velora_id' and 'barcode'/'barcode_master'
    String skuVal = json.getString('sku');
    if (skuVal.isEmpty || skuVal == '-') {
      skuVal = json.getString('velora_id');
    }
    String barcodeVal = json.getString('barcode');
    if (barcodeVal.isEmpty || barcodeVal == '-') {
      barcodeVal = json.getString('barcode_master');
    }

    // Prescription / Hard Drug detection
    final isRx = json.getBool('is_prescription_only') ||
        json.getBool('is_hard_drug') ||
        categoryName.toLowerCase().contains('keras') ||
        categoryName.toLowerCase().contains('narkotika') ||
        categoryName.toLowerCase().contains('psikotropika');

    final rawImage = json.getString('image_url');
    final img = rawImage.isNotEmpty ? rawImage : json.getString('image');

    String? productTag = json.getString('badge');
    if (productTag.isEmpty) productTag = json.getString('tag');
    if (productTag.isEmpty) productTag = json.getString('promo_tag');

    String? desc = json.getString('description');
    if (desc.isEmpty) desc = json.getString('subtitle');
    if (desc.isEmpty) desc = json.getString('desc');

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
          } catch (_) {}
        }
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
      isPrescriptionOnly: isRx,
      batches: rawBatches,
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

    final candidateEndpoints = [
      '/v1/pos/products-sync',
      '/v1/pos/products',
      '/v1/pos/menu',
      '/v1/products',
      '/cafe/pos/products',
      '/cafe/menu',
      '/cafe/products',
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
      } catch (_) {}
    }

    if (response == null) {
      debugPrint('⚠️ [CATALOG] All candidate endpoints failed or returned empty');
      if (_cachedCatalog != null && _cachedCatalog!.products.isNotEmpty) {
        return _cachedCatalog!;
      }
      return PosCatalogData(
        products: const [],
        categories: const ['Semua'],
        catalogVersion: 1,
        businessType: 'fnb',
      );
    }

    final dynamic rawData = response.data;
    Map<String, dynamic> data = {};
    List<dynamic> productList = const [];
    List<dynamic> categoryList = const [];

    if (rawData is Map) {
      final inner = rawData['data'];
      if (inner is Map) {
        data = Map<String, dynamic>.from(inner);
        final p = data['products'] ?? data['data'] ?? data['items'] ?? data['menu'];
        if (p is List) productList = p;
        final c = data['categories'] ?? data['category_list'];
        if (c is List) categoryList = c;
      } else if (inner is List) {
        productList = inner;
        data = Map<String, dynamic>.from(rawData);
      } else {
        data = Map<String, dynamic>.from(rawData);
        final p = data['products'] ?? data['data'] ?? data['items'] ?? data['menu'];
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
        } catch (_) {}
      }
    }

    final rawCategories = <String>[];
    for (final item in categoryList) {
      if (item is Map) {
        final n = item['name'] ?? item['category_name'] ?? item['title'] ?? item['label'];
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

    final rawModifiersData = data['modifiers'] ?? rawData['modifiers'];
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

    final catalogData = PosCatalogData(
      products: rawProducts,
      categories: categorySet.toList(),
      modifiers: catalogModifiers,
      catalogVersion: data.getInt('catalog_version', fallback: 1),
      businessType: data.getString('business_type', fallback: 'retail'),
    );

    debugPrint('📦 [CATALOG] Loaded ${rawProducts.length} dynamic products across ${categorySet.length} categories and ${catalogModifiers.length} modifier groups from $successfulEndpoint');
    _cachedCatalog = catalogData;
    return catalogData;
  }
}
