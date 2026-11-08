import '../../../../core/utils/safe_json.dart';

enum PromotionType {
  percentage,
  fixedAmount,
  bogo,
  custom,
}

typedef StorePromotionType = PromotionType;

/// Model promosi aktif dari prefensi backend (`GET /api/v1/cafe/marketing/promos` / `GET /api/v1/pharmacy/promotions`).
class StorePromotion {
  const StorePromotion({
    required this.id,
    required this.name,
    this.code,
    required this.type,
    required this.value,
    this.minOrderAmount = 0,
    this.maxDiscountAmount = 0,
    this.isAutomatic = false,
    this.isActive = true,
    this.description,
    this.startDate,
    this.endDate,
    this.applicableCategoryIds = const [],
    this.applicableMenuIds = const [],
    this.targetLocationIds = const [],
  });

  final String id;
  final String name;
  final String? code;
  final PromotionType type;
  final double value;
  final double minOrderAmount;
  final double maxDiscountAmount;
  final bool isAutomatic;
  final bool isActive;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> applicableCategoryIds;
  final List<String> applicableMenuIds;
  final List<String> targetLocationIds;

  /// Hitung potongan diskon riil terhadap nilai subtotal
  double calculateDiscount(num subtotal) {
    if (!isActive) return 0.0;
    if (minOrderAmount > 0 && subtotal < minOrderAmount) return 0.0;

    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return 0.0;
    if (endDate != null && now.isAfter(endDate!)) return 0.0;

    double disc = 0.0;
    switch (type) {
      case PromotionType.percentage:
        disc = (subtotal * (value / 100)).toDouble();
        if (maxDiscountAmount > 0 && disc > maxDiscountAmount) {
          disc = maxDiscountAmount;
        }
        break;
      case PromotionType.fixedAmount:
      case PromotionType.bogo:
      case PromotionType.custom:
        disc = value;
        break;
    }
    return disc.clamp(0.0, subtotal.toDouble());
  }

  factory StorePromotion.fromJson(Map<String, dynamic> json) {
    final rawType = json.getString('type', fallback: json.getString('discount_type')).toLowerCase();
    final bool isFlat = json.getBool('is_flat') ||
        rawType == 'discount_nominal' ||
        rawType.contains('nominal') ||
        rawType.contains('fixed') ||
        rawType.contains('amount');

    PromotionType type;
    if (isFlat) {
      type = PromotionType.fixedAmount;
    } else if (rawType == 'discount_percent' || rawType.contains('percent')) {
      type = PromotionType.percentage;
    } else if (rawType == 'buy_x_get_y' || rawType.contains('bogo') || rawType.contains('buy_x')) {
      type = PromotionType.bogo;
    } else if (rawType.contains('custom')) {
      type = PromotionType.custom;
    } else {
      type = PromotionType.percentage;
    }

    final val = json.getDouble(
      'discount_value',
      fallback: json.getDouble(
        'value',
        fallback: json.getDouble(
          'amount',
          fallback: json.getDouble(
            'discount_nominal',
            fallback: json.getDouble('discount_percent', fallback: json.getDouble('rate')),
          ),
        ),
      ),
    );

    final rawMin = json.getDouble(
      'min_purchase',
      fallback: json.getDouble(
        'min_purchase_amount',
        fallback: json.getDouble('min_order_amount', fallback: json.getDouble('min_order')),
      ),
    );
    final rawMax = json.getDouble('max_discount_amount', fallback: json.getDouble('max_discount', fallback: json.getDouble('max_amount')));

    DateTime? start;
    final sStr = json.getString('start_date', fallback: json.getString('starts_at'));
    if (sStr.isNotEmpty) start = DateTime.tryParse(sStr);

    DateTime? end;
    final eStr = json.getString('end_date', fallback: json.getString('expires_at'));
    if (eStr.isNotEmpty) end = DateTime.tryParse(eStr);

    final cats = <String>[];
    final rawCats = json['applicable_categories'] ?? json['category_ids'] ?? json['categories'];
    if (rawCats is List) {
      for (final c in rawCats) {
        if (c != null) cats.add(c.toString());
      }
    }

    final menus = <String>[];
    final rawMenus = json['applicable_menus'] ?? json['applicable_products'] ?? json['menu_ids'] ?? json['product_ids'];
    if (rawMenus is List) {
      for (final m in rawMenus) {
        if (m != null) menus.add(m.toString());
      }
    }

    final locs = <String>[];
    final rawLocs = json['target_location_ids'] ?? json['location_ids'] ?? json['target_locations'];
    if (rawLocs is List) {
      for (final l in rawLocs) {
        if (l != null) locs.add(l.toString());
      }
    }

    final code = json.getString('code', fallback: json.getString('promo_code', fallback: json.getString('voucher_code')));
    final bool explicitAuto = json.containsKey('is_automatic')
        ? json.getBool('is_automatic')
        : (json.containsKey('auto_apply')
            ? json.getBool('auto_apply')
            : (json.containsKey('automatic') ? json.getBool('automatic') : false));
    final bool isAuto = explicitAuto || code.isEmpty;

    return StorePromotion(
      id: json.getString('id', fallback: json.getString('_id', fallback: code.isNotEmpty ? code : 'promo_${DateTime.now().millisecondsSinceEpoch}')),
      name: json.getString('name', fallback: json.getString('title', fallback: json.getString('promo_name', fallback: 'Promosi'))),
      code: code.isNotEmpty ? code : null,
      type: type,
      value: val,
      minOrderAmount: rawMin,
      maxDiscountAmount: rawMax,
      isAutomatic: isAuto,
      isActive: json.getBool('is_active', fallback: json.getBool('active', fallback: json.getString('status') != 'inactive')),
      description: json.getString('description', fallback: json.getString('terms')),
      startDate: start,
      endDate: end,
      applicableCategoryIds: cats,
      applicableMenuIds: menus,
      targetLocationIds: locs,
    );
  }
}

/// Tingkat keanggotaan/loyalitas pelanggan dari prefensi.
class MemberTier {
  const MemberTier({
    required this.name,
    required this.discountPercent,
    this.minSpend = 0,
  });

  final String name;
  final double discountPercent;
  final double minSpend;

  factory MemberTier.fromJson(Map<String, dynamic> json) {
    return MemberTier(
      name: json.getString('name', fallback: json.getString('tier', fallback: 'Member')),
      discountPercent: json.getDouble('discount_percent', fallback: json.getDouble('discount_rate')),
      minSpend: json.getDouble('min_spend', fallback: json.getDouble('min_order')),
    );
  }
}
