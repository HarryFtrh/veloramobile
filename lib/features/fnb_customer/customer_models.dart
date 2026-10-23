// features/fnb_customer/customer_models.dart

class CustomerMenuItem {
  final String id;
  final String name;
  final String category;
  final String description;
  final int basePrice;
  final double rating;
  final String? badge;
  final String? origin;
  final String imageUrl;

  const CustomerMenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.basePrice,
    this.rating = 4.9,
    this.badge,
    this.origin,
    required this.imageUrl,
  });
}

class CustomerCartItem {
  final CustomerMenuItem product;
  final String size;
  final int sizePrice;
  final String sweetness;
  final String iceLevel;
  final List<String> toppings;
  final int toppingsPrice;
  final int quantity;
  final String notes;

  const CustomerCartItem({
    required this.product,
    this.size = 'Regular',
    this.sizePrice = 0,
    this.sweetness = 'Normal (100%)',
    this.iceLevel = 'Normal Ice',
    this.toppings = const [],
    this.toppingsPrice = 0,
    this.quantity = 1,
    this.notes = '',
  });

  int get unitPrice => product.basePrice + sizePrice + toppingsPrice;
  int get totalPrice => unitPrice * quantity;

  CustomerCartItem copyWith({int? quantity, String? notes}) {
    return CustomerCartItem(
      product: product,
      size: size,
      sizePrice: sizePrice,
      sweetness: sweetness,
      iceLevel: iceLevel,
      toppings: toppings,
      toppingsPrice: toppingsPrice,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }
}
