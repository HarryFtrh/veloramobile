import '../../core/network/api_client.dart';
import '../../core/utils/safe_json.dart';

class MarketplaceProduct {
  final String id;
  final String name;
  final num price;
  final int stock;
  final String? manufacturer;
  final String? packaging;

  MarketplaceProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.manufacturer,
    this.packaging,
  });

  factory MarketplaceProduct.fromJson(Map<String, dynamic> json) {
    return MarketplaceProduct(
      id: json.getString('id'),
      name: json.getString('name_main', fallback: json.getString('name', fallback: 'Produk Farmasi')),
      price: json.getNum('sell_price', fallback: json.getNum('price')),
      stock: json.getInt('stock', fallback: 0),
      manufacturer: json.getString('manufacturer'),
      packaging: json.getString('packaging', fallback: 'Box'),
    );
  }
}

class MarketplaceOrderHistoryItem {
  final String id;
  final String orderNumber;
  final num totalAmount;
  final String status;
  final DateTime createdAt;

  MarketplaceOrderHistoryItem({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  factory MarketplaceOrderHistoryItem.fromJson(Map<String, dynamic> json) {
    return MarketplaceOrderHistoryItem(
      id: json.getString('id'),
      orderNumber: json.getString('order_number', fallback: 'ORD-${json.getString('id')}'),
      totalAmount: json.getNum('total_amount', fallback: json.getNum('total')),
      status: json.getString('status', fallback: 'pending'),
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json.getString('created_at')) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

class MarketplaceService {
  static final MarketplaceService instance = MarketplaceService._();
  MarketplaceService._();

  Future<List<MarketplaceProduct>> fetchCatalog({
    String? sellerId,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      if (sellerId != null && sellerId.isNotEmpty) 'seller_id': sellerId,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final endpoints = [
      '/v1/mobile/customer/catalog',
      '/v1/marketplace/catalog',
      '/mobile/customer/catalog',
    ];

    dynamic rawData;
    for (final ep in endpoints) {
      try {
        final response = await ApiClient.instance.dio.get(
          ep,
          queryParameters: queryParams,
        );
        if (response.statusCode == 200 && response.data != null) {
          rawData = response.data;
          break;
        }
      } catch (_) {}
    }

    List items = [];
    if (rawData is Map) {
      final inner = rawData['data'];
      final prods = rawData['products'];
      items = inner is List ? inner : (prods is List ? prods : const []);
    } else if (rawData is List) {
      items = rawData;
    }

    return items
        .whereType<Map>()
        .map((e) => MarketplaceProduct.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<MarketplaceOrderHistoryItem>> getOrderHistory() async {
    final endpoints = [
      '/v1/mobile/customer/order-history',
      '/v1/marketplace/order-history',
      '/mobile/customer/order-history',
    ];

    dynamic rawData;
    for (final ep in endpoints) {
      try {
        final response = await ApiClient.instance.dio.get(ep);
        if (response.statusCode == 200 && response.data != null) {
          rawData = response.data;
          break;
        }
      } catch (_) {}
    }

    List items = [];
    if (rawData is Map) {
      final inner = rawData['data'];
      final orders = rawData['orders'];
      items = inner is List ? inner : (orders is List ? orders : const []);
    } else if (rawData is List) {
      items = rawData;
    }

    return items
        .whereType<Map>()
        .map((e) => MarketplaceOrderHistoryItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<num> getPointsBalance() async {
    final endpoints = [
      '/v1/mobile/customer/points-balance',
      '/v1/pos/customer/points-balance',
      '/mobile/customer/points-balance',
    ];

    for (final ep in endpoints) {
      try {
        final response = await ApiClient.instance.dio.get(ep);
        final rawData = response.data;
        if (rawData is Map) {
          final inner = rawData['data'] ?? rawData;
          if (inner is Map) {
            return (inner['points_balance'] as num?) ?? (inner['points'] as num?) ?? 0;
          }
        }
      } catch (_) {}
    }
    return 0;
  }

  Future<Map<String, dynamic>> processCheckout({
    required String sellerId,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    final endpoints = [
      '/v1/mobile/customer/checkout',
      '/v1/marketplace/checkout',
      '/mobile/customer/checkout',
    ];

    final payload = {
      'seller_id': sellerId,
      'items': items,
      'notes': notes,
    };

    for (final ep in endpoints) {
      try {
        final response = await ApiClient.instance.dio.post(
          ep,
          data: payload,
        );
        final rawData = response.data;
        if (rawData is Map) {
          final inner = rawData['data'];
          return inner is Map ? Map<String, dynamic>.from(inner) : Map<String, dynamic>.from(rawData);
        }
      } catch (_) {}
    }
    return {};
  }
}
