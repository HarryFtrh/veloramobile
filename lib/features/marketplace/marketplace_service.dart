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

    final response = await ApiClient.instance.dio.get(
      '/v1/mobile/customer/catalog',
      queryParameters: queryParams,
    );

    final rawData = response.data;
    List items = [];
    if (rawData is Map<String, dynamic>) {
      items = rawData['data'] is List ? rawData['data'] as List : [];
    } else if (rawData is List) {
      items = rawData;
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((e) => MarketplaceProduct.fromJson(e))
        .toList();
  }

  Future<List<MarketplaceOrderHistoryItem>> getOrderHistory() async {
    final response = await ApiClient.instance.dio.get('/v1/mobile/customer/order-history');
    final rawData = response.data;
    List items = [];
    if (rawData is Map<String, dynamic>) {
      items = rawData['data'] is List ? rawData['data'] as List : [];
    } else if (rawData is List) {
      items = rawData;
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((e) => MarketplaceOrderHistoryItem.fromJson(e))
        .toList();
  }

  Future<num> getPointsBalance() async {
    final response = await ApiClient.instance.dio.get('/v1/mobile/customer/points-balance');
    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      final data = rawData['data'] is Map<String, dynamic> ? rawData['data'] : rawData;
      return (data['points_balance'] as num?) ?? 0;
    }
    return 0;
  }

  Future<Map<String, dynamic>> processCheckout({
    required String sellerId,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    final response = await ApiClient.instance.dio.post(
      '/v1/mobile/customer/checkout',
      data: {
        'seller_id': sellerId,
        'items': items,
        'notes': notes,
      },
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      return rawData['data'] is Map<String, dynamic> ? rawData['data'] : rawData;
    }
    return {};
  }
}
