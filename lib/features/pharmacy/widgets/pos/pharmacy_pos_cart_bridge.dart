import '../../../shared_pos/pos_checkout_service.dart';
import '../../../shared_pos/product_catalog_service.dart';
import '../../services/pharmacy_catalog_service.dart';

/// Helper utilities for cart items, unit resolution, and catalog mapping in Pharmacy POS
class PharmacyPosCartBridge {
  /// Mendapatkan data obat dari key keranjang.
  /// Jika [drugItemsById] diberikan, pencarian dieksekusi dalam kompleksitas O(1).
  /// Jika tidak, fallback ke linear search O(N) di [drugItems] demi backward compatibility.
  static Map<String, dynamic> getItemFromCartKey(
    String key,
    List<Map<String, dynamic>> drugItems, {
    Map<String, Map<String, dynamic>>? drugItemsById,
  }) {
    final id = key.contains(':') ? key.split(':').first : key;
    if (drugItemsById != null) {
      final match = drugItemsById[id.toString()];
      if (match != null) return match;
    }
    return drugItems.firstWhere(
      (m) => m['id'].toString() == id.toString(),
      orElse: () => <String, dynamic>{'id': id, 'name': 'Obat', 'price': 0},
    );
  }

  /// Lookup langsung O(1) dari hash map indeks obat.
  static Map<String, dynamic> getItemFromCartKeyFast(
    String key,
    Map<String, Map<String, dynamic>> drugItemsById,
  ) {
    final id = key.contains(':') ? key.split(':').first : key;
    return drugItemsById[id.toString()] ??
        <String, dynamic>{'id': id, 'name': 'Obat', 'price': 0};
  }

  static String getUnitFromCartKey(String key, Map<String, dynamic> item) {
    if (key.contains(':')) {
      return key.split(':').last;
    }
    return item['selectedUnit']?.toString() ?? item['unit']?.toString() ?? 'TAB';
  }

  static num getPriceForCartKey(String key, Map<String, dynamic> item) {
    final unit = getUnitFromCartKey(key, item);
    final rawUnits = item['units'];
    if (rawUnits is List) {
      for (final u in rawUnits) {
        if (u is Map && u['name']?.toString().toUpperCase() == unit.toUpperCase()) {
          return (u['price'] as num?) ?? (item['price'] as num? ?? 0);
        }
      }
    }
    return item['price'] as num? ?? 0;
  }

  /// Membangun hash cache agregasi kuantitas keranjang per ID obat secara O(M) single pass.
  static Map<String, int> buildCartQuantityMap(Map<String, int> cart) {
    final Map<String, int> qtyMap = {};
    cart.forEach((k, q) {
      final baseId = (k.contains(':') ? k.split(':').first : k).toString();
      qtyMap[baseId] = (qtyMap[baseId] ?? 0) + q;
    });
    return qtyMap;
  }

  /// Mengambil total kuantitas obat di keranjang untuk ID tertentu.
  /// Jika [quantityCache] disediakan, operasi instan O(1) per kartu produk.
  static int getCartQuantityForDrug(
    dynamic id,
    Map<String, int> cart, {
    Map<String, int>? quantityCache,
  }) {
    final strId = id.toString();
    if (quantityCache != null) {
      return quantityCache[strId] ?? 0;
    }
    int total = 0;
    cart.forEach((k, q) {
      final baseId = k.contains(':') ? k.split(':').first : k;
      if (baseId.toString() == strId) {
        total += q;
      }
    });
    return total;
  }

  /// Membangun list PosCartItem.
  /// Jika [drugItemsById] disediakan, total kalkulasi keranjang berubah dari O(M x N) menjadi O(M).
  static List<PosCartItem> buildPosCartItems(
    Map<String, int> cart,
    List<Map<String, dynamic>> drugItems, {
    Map<String, Map<String, dynamic>>? drugItemsById,
  }) {
    return cart.entries.map((e) {
      final item = drugItemsById != null
          ? getItemFromCartKeyFast(e.key, drugItemsById)
          : getItemFromCartKey(e.key, drugItems);
      final unit = getUnitFromCartKey(e.key, item);
      final price = getPriceForCartKey(e.key, item);
      final baseId = e.key.contains(':') ? e.key.split(':').first : e.key;

      return PosCartItem(
        productId: baseId,
        name: '${item['name']?.toString() ?? 'Obat'} ($unit)',
        unit: unit,
        price: price,
        quantity: e.value,
        batchNumber: item['batch']?.toString(),
        expiryDate: (item['ed'] ?? item['exp'])?.toString(),
        modifiers: {'Satuan': unit},
      );
    }).toList();
  }

  static Map<String, dynamic> posProductToDrugMap(PosProduct p) {
    var batches = p.batches;
    if (batches.isEmpty || batches.every((b) => b.batchNumber == '-' && b.expiryDate == '-')) {
      final enriched = PharmacyCatalogService.instance.enrichProductsWithBatches([p]).first;
      batches = enriched.batches;
    }
    final sortedBatches = List<PosProductBatch>.from(batches);
    sortedBatches.sort((a, b) {
      if (a.expiryDate == '-' && b.expiryDate == '-') return 0;
      if (a.expiryDate == '-') return 1;
      if (b.expiryDate == '-') return -1;
      return a.expiryDate.compareTo(b.expiryDate);
    });

    final primaryBatch = sortedBatches.isNotEmpty ? sortedBatches.first.batchNumber : '-';
    final primaryEd = sortedBatches.isNotEmpty ? sortedBatches.first.expiryDate : '-';

    return {
      'id': p.id,
      'name': p.name,
      'sku': p.sku.isNotEmpty ? p.sku : (p.barcode.isNotEmpty ? p.barcode : '-'),
      'barcode': p.barcode,
      'category': p.category,
      'price': p.price,
      'isDotRed': p.isPrescriptionOnly,
      'isPrescriptionOnly': p.isPrescriptionOnly,
      'batch': primaryBatch,
      'ed': primaryEd,
      'batchCount': sortedBatches.length,
      'stock': p.stock.toInt(),
      'unit': p.unit ?? 'TAB',
      'selectedUnit': p.units.isNotEmpty ? p.units.first.name : (p.unit ?? 'TAB'),
      'units': p.units.map((u) => u.toJson()).toList(),
      'imageUrl': p.imageUrl,
      'image': p.imageUrl,
      'description': p.description,
      'fungsi': p.fungsi,
      'kandungan': p.kandungan,
      'klasifikasi': p.klasifikasi,
      'sediaan': p.sediaan,
      'batches': sortedBatches
          .map((b) => {
                'id': b.id,
                'batch': b.batchNumber,
                'batch_number': b.batchNumber,
                'ed': b.expiryDate,
                'expiry_date': b.expiryDate,
                'stock': b.stock,
              })
          .toList(),
    };
  }
}
