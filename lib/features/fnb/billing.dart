import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/safe_json.dart';

enum PromotionType {
  percentage,
  fixedAmount,
  bogo,
  custom,
}

typedef StorePromotionType = PromotionType;

/// Model promosi aktif dari prefensi backend (`GET /v1/pos/config` / `GET /preferences`).
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
    PromotionType type;
    if (rawType.contains('fixed') || rawType.contains('nominal') || rawType.contains('amount')) {
      type = PromotionType.fixedAmount;
    } else if (rawType.contains('bogo')) {
      type = PromotionType.bogo;
    } else if (rawType.contains('custom')) {
      type = PromotionType.custom;
    } else {
      type = PromotionType.percentage;
    }

    final val = json.getDouble('value', fallback: json.getDouble('amount', fallback: json.getDouble('rate', fallback: json.getDouble('discount_value'))));
    final rawMin = json.getDouble('min_order_amount', fallback: json.getDouble('min_order', fallback: json.getDouble('min_purchase')));
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

    final code = json.getString('code', fallback: json.getString('promo_code', fallback: json.getString('voucher_code')));

    return StorePromotion(
      id: json.getString('id', fallback: json.getString('_id', fallback: code.isNotEmpty ? code : 'promo_${DateTime.now().millisecondsSinceEpoch}')),
      name: json.getString('name', fallback: json.getString('title', fallback: json.getString('promo_name', fallback: 'Promosi'))),
      code: code.isNotEmpty ? code : null,
      type: type,
      value: val,
      minOrderAmount: rawMin,
      maxDiscountAmount: rawMax,
      isAutomatic: json.getBool('is_automatic', fallback: json.getBool('auto_apply', fallback: json.getBool('automatic'))),
      isActive: json.getBool('is_active', fallback: json.getBool('active', fallback: json.getString('status') != 'inactive')),
      description: json.getString('description', fallback: json.getString('terms')),
      startDate: start,
      endDate: end,
      applicableCategoryIds: cats,
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

/// Pengaturan tagihan & operasional F&B dari `GET /v1/pos/config` atau `GET /preferences`.
class BillingSettings {
  const BillingSettings({
    this.serviceChargeEnabled = false,
    this.serviceChargeRate = 0.0,
    this.pb1Enabled = false,
    this.pb1Rate = 0.0,
    this.pb1Inclusive = false,
    this.roundingEnabled = false,
    this.roundingStep = 0,
    this.roundingScope = 'total_only',
    this.roundingDirection = 'nearest',
    this.taxName = 'PB1',
    this.promotions = const [],
    this.memberTiers = const [],
    this.allowCustomDiscount = true,
    this.maxDiscountPercent = 100.0,
    this.receiptHeader = '',
    this.receiptFooter = '',
    this.currencySymbol = 'Rp',
    this.enableTables = true,
    this.enableKitchen = true,
    this.enableOpenBills = true,
    this.rawPreferences = const {},
  });

  final bool serviceChargeEnabled;
  final double serviceChargeRate;
  final bool pb1Enabled;
  final double pb1Rate;
  final bool pb1Inclusive;
  final bool roundingEnabled;
  final int roundingStep;

  /// `both`, `total_only`, atau `discount_only`.
  final String roundingScope;

  /// `floor`, `ceil`, atau `nearest`.
  final String roundingDirection;

  /// Nama label pajak resto (mis. "PB1", "PPN", "Pajak Restoran").
  final String taxName;

  /// Daftar promosi & voucher aktif dari API prefensi.
  final List<StorePromotion> promotions;

  /// Tingkat diskon member dari API prefensi.
  final List<MemberTier> memberTiers;

  /// Izin kasir memberikan diskon kustom manual.
  final bool allowCustomDiscount;

  /// Batas maksimal persentase diskon manual.
  final double maxDiscountPercent;

  final String receiptHeader;
  final String receiptFooter;
  final String currencySymbol;
  final bool enableTables;
  final bool enableKitchen;
  final bool enableOpenBills;
  final Map<String, dynamic> rawPreferences;

  bool get roundsTotal => roundingEnabled && (roundingScope == 'both' || roundingScope == 'total_only');

  /// Mencari promosi aktif berdasarkan kode voucher/promo (case-insensitive)
  StorePromotion? findPromotionByCode(String code) {
    final clean = code.trim().toUpperCase();
    if (clean.isEmpty) return null;
    for (final promo in promotions) {
      if (promo.isActive && promo.code?.toUpperCase() == clean) {
        return promo;
      }
    }
    return null;
  }

  /// Daftar promosi yang aktif
  List<StorePromotion> get activePromotions =>
      promotions.where((p) => p.isActive).toList();

  /// Daftar promosi otomatis yang aktif
  List<StorePromotion> get autoPromotions =>
      promotions.where((p) => p.isActive && p.isAutomatic).toList();

  /// Daftar promosi manual (voucher/promo yang bisa dipilih kasir)
  List<StorePromotion> get manualPromotions =>
      promotions.where((p) => p.isActive && !p.isAutomatic).toList();

  factory BillingSettings.fromJson(Map<String, dynamic> json) {
    final step = json.getInt('rounding_type', fallback: json.getInt('rounding_step'));

    // Ekstraksi promosi & diskon dari prefensi
    final rawPromos = json['promotions'] ??
        json['discounts'] ??
        json['active_promotions'] ??
        json['promos'] ??
        json['vouchers'];
    final List<StorePromotion> promos = [];
    if (rawPromos is List) {
      for (final item in rawPromos) {
        if (item is Map) {
          try {
            promos.add(StorePromotion.fromJson(Map<String, dynamic>.from(item)));
          } catch (_) {}
        }
      }
    }

    // Ekstraksi member tiers dari prefensi
    final rawTiers = json['member_tiers'] ??
        json['customer_tiers'] ??
        json['membership_levels'] ??
        json['tiers'];
    final List<MemberTier> tiers = [];
    if (rawTiers is List) {
      for (final item in rawTiers) {
        if (item is Map) {
          try {
            tiers.add(MemberTier.fromJson(Map<String, dynamic>.from(item)));
          } catch (_) {}
        }
      }
    }

    return BillingSettings(
      serviceChargeEnabled: json.getBool('service_charge_enabled', fallback: json.getBool('enable_service_charge')),
      serviceChargeRate: json.getDouble('service_charge_rate', fallback: json.getDouble('service_rate')),
      pb1Enabled: json.getBool('pb1_enabled', fallback: json.getBool('enable_pb1', fallback: json.getBool('tax_enabled'))),
      pb1Rate: json.getDouble('pb1_rate', fallback: json.getDouble('tax_rate')),
      pb1Inclusive: json.getBool('pb1_inclusive', fallback: json.getBool('tax_inclusive')),
      // Sama seperti web: pembulatan aktif kecuali dimatikan eksplisit.
      roundingEnabled: json['rounding_enabled'] != false,
      roundingStep: step > 0 ? step : 100,
      roundingScope: json.getString('rounding_scope', fallback: 'both'),
      roundingDirection: json.getString('rounding_direction', fallback: 'floor'),
      taxName: json.getString('tax_name', fallback: 'PB1'),
      promotions: promos,
      memberTiers: tiers,
      allowCustomDiscount: json.getBool('allow_custom_discount', fallback: true),
      maxDiscountPercent: json.getDouble('max_discount_percent', fallback: json.getDouble('max_custom_discount', fallback: 100.0)),
      receiptHeader: json.getString('receipt_header'),
      receiptFooter: json.getString('receipt_footer'),
      currencySymbol: json.getString('currency_symbol', fallback: 'Rp'),
      enableTables: json.getBool('enable_tables', fallback: true),
      enableKitchen: json.getBool('enable_kitchen', fallback: true),
      enableOpenBills: json.getBool('enable_open_bills', fallback: true),
      rawPreferences: json,
    );
  }

  BillingSettings copyWith({
    bool? serviceChargeEnabled,
    double? serviceChargeRate,
    bool? pb1Enabled,
    double? pb1Rate,
    bool? pb1Inclusive,
    bool? roundingEnabled,
    int? roundingStep,
    String? roundingScope,
    String? roundingDirection,
    String? taxName,
    List<StorePromotion>? promotions,
    List<MemberTier>? memberTiers,
    bool? allowCustomDiscount,
    double? maxDiscountPercent,
    String? receiptHeader,
    String? receiptFooter,
    String? currencySymbol,
    bool? enableTables,
    bool? enableKitchen,
    bool? enableOpenBills,
    Map<String, dynamic>? rawPreferences,
  }) {
    return BillingSettings(
      serviceChargeEnabled: serviceChargeEnabled ?? this.serviceChargeEnabled,
      serviceChargeRate: serviceChargeRate ?? this.serviceChargeRate,
      pb1Enabled: pb1Enabled ?? this.pb1Enabled,
      pb1Rate: pb1Rate ?? this.pb1Rate,
      pb1Inclusive: pb1Inclusive ?? this.pb1Inclusive,
      roundingEnabled: roundingEnabled ?? this.roundingEnabled,
      roundingStep: roundingStep ?? this.roundingStep,
      roundingScope: roundingScope ?? this.roundingScope,
      roundingDirection: roundingDirection ?? this.roundingDirection,
      taxName: taxName ?? this.taxName,
      promotions: promotions ?? this.promotions,
      memberTiers: memberTiers ?? this.memberTiers,
      allowCustomDiscount: allowCustomDiscount ?? this.allowCustomDiscount,
      maxDiscountPercent: maxDiscountPercent ?? this.maxDiscountPercent,
      receiptHeader: receiptHeader ?? this.receiptHeader,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      enableTables: enableTables ?? this.enableTables,
      enableKitchen: enableKitchen ?? this.enableKitchen,
      enableOpenBills: enableOpenBills ?? this.enableOpenBills,
      rawPreferences: rawPreferences ?? this.rawPreferences,
    );
  }

  /// Tarik data promosi dan diskon dari endpoint dedicated backend:
  /// 1. `GET /v1/pos/discounts`
  /// 2. `GET /v1/pos/promotions`
  /// 3. `GET /v1/discounts`
  /// 4. `GET /cafe/pos/discounts`
  /// 5. `GET /v1/pos/vouchers`
  static Future<List<StorePromotion>> fetchDiscountsFromApi() async {
    final locId = SessionStorage.instance.getLocationId();
    final qLoc = {if (locId != null && locId.isNotEmpty) 'location_id': locId};

    final endpoints = [
      '/v1/pos/discounts',
      '/v1/pos/promotions',
      '/v1/discounts',
      '/cafe/pos/discounts',
      '/v1/pos/vouchers',
    ];

    for (final ep in endpoints) {
      try {
        final res = await ApiClient.instance.dio.get(ep, queryParameters: qLoc);
        final rawData = res.data;
        List? list;
        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map) {
          final data = rawData['data'];
          if (data is List) {
            list = data;
          } else if (data is Map) {
            final sub = data['discounts'] ?? data['promotions'] ?? data['vouchers'] ?? data['items'];
            if (sub is List) list = sub;
          } else {
            final sub = rawData['discounts'] ?? rawData['promotions'] ?? rawData['vouchers'];
            if (sub is List) list = sub;
          }
        }

        if (list != null && list.isNotEmpty) {
          final results = <StorePromotion>[];
          for (final item in list) {
            if (item is Map) {
              try {
                results.add(StorePromotion.fromJson(Map<String, dynamic>.from(item)));
              } catch (_) {}
            }
          }
          if (results.isNotEmpty) {
            return results;
          }
        }
      } catch (_) {
        // Fallback coba endpoint berikutnya
      }
    }
    return const [];
  }

  /// Verifikasi kode voucher/diskon langsung ke API backend
  static Future<StorePromotion?> verifyVoucherCodeApi(String code, num subtotal) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return null;

    final locId = SessionStorage.instance.getLocationId();
    final payload = {
      'code': cleanCode,
      'promo_code': cleanCode,
      'voucher_code': cleanCode,
      'subtotal': subtotal,
      if (locId != null && locId.isNotEmpty) 'location_id': locId,
    };

    final postEndpoints = [
      '/v1/pos/vouchers/verify',
      '/v1/pos/discounts/check',
      '/v1/pos/discounts/validate',
      '/cafe/pos/vouchers/verify',
    ];

    for (final ep in postEndpoints) {
      try {
        final res = await ApiClient.instance.dio.post(ep, data: payload);
        final raw = res.data;
        Map<String, dynamic>? dataMap;
        if (raw is Map) {
          if (raw['data'] is Map) {
            dataMap = Map<String, dynamic>.from(raw['data'] as Map);
          } else {
            dataMap = Map<String, dynamic>.from(raw);
          }
        }
        if (dataMap != null && dataMap.isNotEmpty) {
          return StorePromotion.fromJson(dataMap);
        }
      } catch (_) {}
    }

    final getEndpoints = [
      '/v1/pos/vouchers/$cleanCode',
      '/v1/pos/discounts/$cleanCode',
    ];
    for (final ep in getEndpoints) {
      try {
        final res = await ApiClient.instance.dio.get(ep, queryParameters: {
          if (locId != null && locId.isNotEmpty) 'location_id': locId,
        });
        final raw = res.data;
        Map<String, dynamic>? dataMap;
        if (raw is Map) {
          if (raw['data'] is Map) {
            dataMap = Map<String, dynamic>.from(raw['data'] as Map);
          } else {
            dataMap = Map<String, dynamic>.from(raw);
          }
        }
        if (dataMap != null && dataMap.isNotEmpty) {
          return StorePromotion.fromJson(dataMap);
        }
      } catch (_) {}
    }

    return null;
  }

  static Future<BillingSettings> fetch() async {
    try {
      final locId = SessionStorage.instance.getLocationId();
      final qLoc = {if (locId != null && locId.isNotEmpty) 'location_id': locId};
      dynamic body;
      try {
        final res = await ApiClient.instance.dio.get('/v1/pos/config', queryParameters: qLoc);
        body = res.data;
      } catch (_) {
        try {
          final res = await ApiClient.instance.dio.get('/v1/pos/preferences', queryParameters: qLoc);
          body = res.data;
        } catch (_) {
          try {
            final res = await ApiClient.instance.dio.get('/v1/preferences', queryParameters: qLoc);
            body = res.data;
          } catch (_) {
            final res = await ApiClient.instance.dio.get('/preferences', queryParameters: qLoc);
            body = res.data;
          }
        }
      }
      Map<String, dynamic> data = const {};
      if (body is Map) {
        if (body['data'] is Map) {
          data = Map<String, dynamic>.from(body['data'] as Map);
        } else {
          data = Map<String, dynamic>.from(body);
        }
      }

      final storeName = data.getString('store_name', fallback: data.getString('company_name', fallback: data.getString('name')));
      final storeAddress = data.getString('address', fallback: data.getString('store_address'));
      final storePhone = data.getString('phone', fallback: data.getString('store_phone'));
      if (storeName.isNotEmpty) {
        await SessionStorage.instance.saveTenantProfile(
          name: storeName,
          address: storeAddress.isNotEmpty ? storeAddress : null,
          phone: storePhone.isNotEmpty ? storePhone : null,
        );
      }

      var settings = BillingSettings.fromJson(data);

      // Tarik diskon & promosi terdedikasi dari API jika tersedia
      try {
        final extraPromos = await fetchDiscountsFromApi();
        if (extraPromos.isNotEmpty) {
          final merged = List<StorePromotion>.from(settings.promotions);
          final existingIds = merged.map((p) => p.id).toSet();
          final existingCodes = merged.where((p) => p.code != null).map((p) => p.code!.toUpperCase()).toSet();
          for (final ep in extraPromos) {
            final codeUpper = ep.code?.toUpperCase();
            final isDup = existingIds.contains(ep.id) || (codeUpper != null && existingCodes.contains(codeUpper));
            if (!isDup) {
              merged.add(ep);
              existingIds.add(ep.id);
              if (codeUpper != null) existingCodes.add(codeUpper);
            }
          }
          settings = settings.copyWith(promotions: merged);
        }
      } catch (_) {}

      return settings;
    } catch (e) {
      // Fallback default jika offline atau belum diatur: PB1 nonaktif, pembulatan kelipatan 100
      var fallbackSettings = const BillingSettings(
        serviceChargeEnabled: false,
        serviceChargeRate: 0,
        pb1Enabled: false,
        pb1Rate: 0,
        pb1Inclusive: false,
        roundingEnabled: true,
        roundingStep: 100,
        roundingScope: 'both',
        roundingDirection: 'floor',
        taxName: 'PB1',
        promotions: [],
        memberTiers: [],
        allowCustomDiscount: true,
        maxDiscountPercent: 100.0,
      );

      try {
        final extraPromos = await fetchDiscountsFromApi();
        if (extraPromos.isNotEmpty) {
          fallbackSettings = fallbackSettings.copyWith(promotions: extraPromos);
        }
      } catch (_) {}

      return fallbackSettings;
    }
  }
}

/// Hasil hitung tagihan satu keranjang.
class BillBreakdown {
  const BillBreakdown({
    required this.subtotal,
    required this.discount,
    required this.serviceCharge,
    required this.tax,
    required this.rounding,
    required this.total,
  });

  final num subtotal;
  final num discount;
  final num serviceCharge;
  final num tax;

  /// Selisih pembulatan (dikirim ke backend sebagai `rounding_amount`).
  final num rounding;
  final num total;
}

/// Rumus yang sama dengan `useCafePosBilling.js` di web, supaya angka di
/// aplikasi dan di kasir web selalu cocok.
abstract final class BillCalculator {
  static num _round(BillingSettings s, num value) {
    if (!s.roundingEnabled || s.roundingStep <= 1) return value.round();
    final step = s.roundingStep;
    switch (s.roundingDirection) {
      case 'ceil':
        return (value / step).ceil() * step;
      case 'nearest':
        return (value / step).round() * step;
      default:
        final floored = (value / step).floor() * step;
        if (floored == 0 && value > 0) {
          if (step > 100) {
            final hundreds = (value / 100).floor() * 100;
            return hundreds == 0 ? value.round() : hundreds;
          }
          return value.round();
        }
        return floored;
    }
  }

  static BillBreakdown calculate(BillingSettings s, {required num subtotal, num discount = 0}) {
    final disc = discount > subtotal ? subtotal : discount;
    final net = (subtotal - disc).clamp(0, double.infinity);

    final service = s.serviceChargeEnabled && s.serviceChargeRate > 0 && net > 0
        ? (net * (s.serviceChargeRate / 100)).round()
        : 0;
    final base = net + service;
    final tax = s.pb1Enabled && !s.pb1Inclusive && s.pb1Rate > 0 && base > 0
        ? (base * (s.pb1Rate / 100)).round()
        : 0;

    final raw = base + tax;
    final total = s.roundsTotal && raw > 0 ? _round(s, raw) : raw.round();
    return BillBreakdown(
      subtotal: subtotal,
      discount: disc,
      serviceCharge: service,
      tax: tax,
      rounding: total - raw,
      total: total,
    );
  }
}
