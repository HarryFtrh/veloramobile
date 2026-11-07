import 'dart:async';
import '../../core/config/business_vertical.dart';
import '../../core/storage/session_storage.dart';
import '../fnb/fnb_catalog_service.dart';
import '../pharmacy/services/pharmacy_catalog_service.dart';
import 'retail_catalog_service.dart';
import 'models/pos_catalog_models.dart';

export 'models/pos_catalog_models.dart';

/// Router Katalog Produk yang mendelegasikan operasi ke layanan per-bisnis:
/// - `pharmacy` -> [PharmacyCatalogService]
/// - `fnb`      -> [FnbCatalogService]
/// - `retail`   -> [RetailCatalogService]
/// Setiap vertikal bisnis memiliki endpoint, parser JSON, aturan stok, dan cache terpisah.
class ProductCatalogService {
  static final ProductCatalogService instance = ProductCatalogService._();
  ProductCatalogService._();

  /// Menormalisasi dan memvalidasi URL gambar produk dari backend/S3.
  static String? resolveImageUrl(String? raw) => PosProduct.resolveImageUrl(raw);

  /// URL cadangan ke `/storage/` lokal apabila file tidak ditemukan di S3 `storage.velora.co.id`
  static String? resolveImageFallbackUrl(String? primaryUrl) => PosProduct.resolveImageFallbackUrl(primaryUrl);

  static String activeVertical() {
    return BusinessVertical.resolve(
      businessType: SessionStorage.instance.getBusinessType(),
    ).key;
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
