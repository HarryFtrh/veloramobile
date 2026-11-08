import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../../core/utils/safe_json.dart';
import 'store_promotion.dart';

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
    this.npwpd = '',
    this.taxDeviceId = '',
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

  /// Nomor Pokok Wajib Pajak Daerah (NPWPD) untuk kepatuhan Bapenda
  final String npwpd;

  /// ID mesin tapping box / recorder pajak daerah Pemda
  final String taxDeviceId;

  /// Helper untuk audit dan ekspor rekonsiliasi Pajak Restoran (PB1 10%) Bapenda
  Map<String, dynamic> toBapendaAuditPayload({
    required String invoiceNumber,
    required num subtotal,
    required num taxAmount,
    required num totalAmount,
    required DateTime transactionTime,
  }) {
    return {
      'npwpd': npwpd.isNotEmpty ? npwpd : 'PEMDA-TAX-PENDING',
      'device_id': taxDeviceId.isNotEmpty ? taxDeviceId : 'VELORA-POS-TERMINAL',
      'bill_no': invoiceNumber,
      'subtotal': subtotal,
      'tax_rate': pb1Rate,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'timestamp': transactionTime.toIso8601String(),
      'tax_name': taxName,
    };
  }

  bool get roundsTotal => roundingEnabled && roundingScope.toLowerCase().trim() != 'discount_only';

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

  static Map<String, dynamic> _unpackJson(dynamic raw) {
    final Map<String, dynamic> result = {};

    void extract(dynamic node) {
      if (node == null) return;
      if (node is String) {
        final trimmed = node.trim();
        if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
            (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
          try {
            final decoded = jsonDecode(trimmed);
            extract(decoded);
          } catch (_) {}
        }
      } else if (node is Map) {
        for (final entry in node.entries) {
          final k = entry.key.toString();
          final v = entry.value;
          if (['data', 'tenant', 'settings', 'preferences', 'pos_config', 'config', 'billing', 'pos', 'user'].contains(k.toLowerCase())) {
            extract(v);
          }
          if (v is! Map && v is! List) {
            result[k] = v;
          } else if (v is List) {
            result[k] = v;
          }
        }
      }
    }

    extract(raw);
    return result;
  }

  factory BillingSettings.fromJson(Map<String, dynamic> rawJson) {
    final json = _unpackJson(rawJson);

    // 1. Ekstraksi Pajak / PB1
    final rawTaxRate = json.getDouble(
      'pb1_rate',
      fallback: json.getDouble(
        'tax_rate',
        fallback: json.getDouble(
          'tax_percentage',
          fallback: json.getDouble(
            'tax_percent',
            fallback: json.getDouble('pb1_percentage', fallback: json.getDouble('tax_val')),
          ),
        ),
      ),
    );
    final double pb1Rate = (rawTaxRate > 0 && rawTaxRate <= 1) ? (rawTaxRate * 100) : rawTaxRate;
    final bool pb1Explicit = json.containsKey('pb1_enabled')
        ? json.getBool('pb1_enabled')
        : (json.containsKey('enable_pb1')
            ? json.getBool('enable_pb1')
            : (json.containsKey('tax_enabled')
                ? json.getBool('tax_enabled')
                : (json.containsKey('enable_tax')
                    ? json.getBool('enable_tax')
                    : (json.containsKey('show_tax') ? json.getBool('show_tax') : (pb1Rate > 0)))));
    final bool pb1Enabled = pb1Explicit && pb1Rate > 0;
    final bool pb1Inclusive = json.getBool('pb1_inclusive', fallback: json.getBool('tax_inclusive', fallback: false));

    // 2. Ekstraksi Biaya Layanan / Service Charge
    final rawServiceRate = json.getDouble(
      'service_charge_rate',
      fallback: json.getDouble(
        'service_rate',
        fallback: json.getDouble(
          'service_charge_percent',
          fallback: json.getDouble(
            'service_charge_percentage',
            fallback: json.getDouble('service_percent', fallback: json.getDouble('service_charge')),
          ),
        ),
      ),
    );
    final double serviceRate = (rawServiceRate > 0 && rawServiceRate <= 1) ? (rawServiceRate * 100) : rawServiceRate;
    final bool serviceExplicit = json.containsKey('service_charge_enabled')
        ? json.getBool('service_charge_enabled')
        : (json.containsKey('enable_service_charge')
            ? json.getBool('enable_service_charge')
            : (json.containsKey('service_enabled') ? json.getBool('service_enabled') : (serviceRate > 0)));
    final bool serviceChargeEnabled = serviceExplicit && serviceRate > 0;

    // 3. Ekstraksi Pembulatan (Rounding) langsung dari API
    int step = 0;
    final rawStep = json['rounding_step'] ??
        json['rounding_type'] ??
        json['rounding_amount_step'] ??
        json['rounding_step_amount'] ??
        json['rounding_value'];

    if (rawStep != null) {
      if (rawStep is int) {
        step = rawStep;
      } else if (rawStep is num) {
        step = rawStep.toInt();
      } else if (rawStep is String) {
        final s = rawStep.trim().toLowerCase();
        if (s == 'hundreds' || s == 'ratusan') {
          step = 100;
        } else if (s == 'five_hundreds' || s == 'lima_ratusan') {
          step = 500;
        } else if (s == 'thousands' || s == 'ribuan') {
          step = 1000;
        } else {
          step = int.tryParse(s) ?? 0;
        }
      }
    }

    // Mapping jika backend mengirim ID kode enum (1 = 100, 2 = 500, 3 = 1000)
    if (step == 1) {
      step = 100;
    } else if (step == 2) {
      step = 500;
    } else if (step == 3) {
      step = 1000;
    }

    // Ekstraksi flag aktif pembulatan langsung dari field API
    bool isRoundingOn = false;
    final rawEnabled = json['rounding_enabled'] ??
        json['enable_rounding'] ??
        json['is_rounding'] ??
        json['rounding'] ??
        json['round_total'];

    if (rawEnabled != null) {
      if (rawEnabled is bool) {
        isRoundingOn = rawEnabled;
      } else if (rawEnabled is num) {
        isRoundingOn = rawEnabled == 1;
      } else if (rawEnabled is String) {
        final s = rawEnabled.trim().toLowerCase();
        isRoundingOn = s == 'true' || s == '1' || s == 'yes' || s == 'on';
      }
    } else {
      // Jika di API tidak ada flag boolean eksplisit tapi ada nilai kelipatan dari backend (mis. 100/500/1000),
      // maka pembulatan dianggap aktif mengikuti kelipatan tersebut.
      isRoundingOn = step > 0;
    }

    // Jika step tidak ditentukan di API atau <= 0, pembulatan dinonaktifkan
    if (step <= 0) {
      isRoundingOn = false;
      step = 0;
    }

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
          } catch (e) {
            debugPrint('⚠️ [BillingSettings] Gagal parse StorePromotion: $e');
          }
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
          } catch (e) {
            debugPrint('⚠️ [BillingSettings] Gagal parse MemberTier: $e');
          }
        }
      }
    }

    return BillingSettings(
      serviceChargeEnabled: serviceChargeEnabled,
      serviceChargeRate: serviceRate,
      pb1Enabled: pb1Enabled,
      pb1Rate: pb1Rate,
      pb1Inclusive: pb1Inclusive,
      roundingEnabled: isRoundingOn,
      roundingStep: step,
      roundingScope: json.getString('rounding_scope', fallback: 'both'),
      roundingDirection: json.getString('rounding_direction', fallback: json.getString('rounding_mode', fallback: 'floor')),
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
      npwpd: json.getString('npwpd', fallback: json.getString('tax_id')),
      taxDeviceId: json.getString('tax_device_id', fallback: json.getString('tapping_box_id')),
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
    String? npwpd,
    String? taxDeviceId,
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
      npwpd: npwpd ?? this.npwpd,
      taxDeviceId: taxDeviceId ?? this.taxDeviceId,
    );
  }

  /// Tarik data promosi dan diskon dari endpoint dedicated backend sesuai spesifikasi resmi:
  /// - Cafe: `GET /api/v1/cafe/marketing/promos`
  /// - Pharmacy: `GET /api/v1/pharmacy/promotions` (mendukung `all=true` / `per_page=all`)
  /// - Retail: `GET /api/v1/retail/promotions`
  static Future<List<StorePromotion>> fetchDiscountsFromApi() async {
    final locId = SessionStorage.instance.getLocationId();
    final qParams = {
      'all': 'true',
      'per_page': 'all',
      'is_active': 'true',
      if (locId != null && locId.isNotEmpty)
        'location_id': int.tryParse(locId) ?? locId,
    };

    final flavor = AppConfig.instance.flavor;
    final List<String> endpoints = [];

    if (flavor == AppFlavor.pharmacy) {
      endpoints.addAll([
        '/v1/pharmacy/promotions',
        '/pharmacy/promotions',
        '/v1/pos/promotions',
      ]);
    } else if (flavor == AppFlavor.sales) {
      endpoints.addAll([
        '/v1/retail/promotions',
        '/retail/promotions',
        '/v1/pos/promotions',
      ]);
    } else {
      // Default FnB / Cafe
      endpoints.addAll([
        '/v1/cafe/marketing/promos',
        '/cafe/marketing/promos',
        '/v1/retail/promotions',
        '/v1/pharmacy/promotions',
      ]);
    }

    // Comprehensive fallbacks
    endpoints.addAll([
      '/v1/cafe/marketing/promos',
      '/cafe/marketing/promos',
      '/v1/retail/promotions',
      '/retail/promotions',
      '/v1/pharmacy/promotions',
      '/pharmacy/promotions',
      '/cafe/promotions',
      '/v1/pos/promotions',
      '/v1/pos/discounts',
      '/v1/discounts',
      '/v1/promotions',
      '/cafe/pos/discounts',
      '/cafe/discounts',
      '/pos/discounts',
      '/pos/promotions',
    ]);

    final triedUrls = <String>{};

    for (final ep in endpoints) {
      if (!triedUrls.add(ep)) continue;
      try {
        final res = await ApiClient.instance.dio.get(ep, queryParameters: qParams);
        final rawData = res.data;
        List? list;
        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map) {
          final data = rawData['data'];
          if (data is List) {
            list = data;
          } else if (data is Map) {
            final sub = data['discounts'] ?? data['promotions'] ?? data['promos'] ?? data['data'];
            if (sub is List) list = sub;
          } else {
            final sub = rawData['discounts'] ?? rawData['promotions'] ?? rawData['promos'];
            if (sub is List) list = sub;
          }
        }

        if (list != null && list.isNotEmpty) {
          final results = <StorePromotion>[];
          for (final item in list) {
            if (item is Map) {
              try {
                final promo = StorePromotion.fromJson(Map<String, dynamic>.from(item));
                // Filter target_location_ids jika spesifik cabang aktif
                if (promo.targetLocationIds.isNotEmpty && locId != null && locId.isNotEmpty) {
                  if (!promo.targetLocationIds.contains(locId)) {
                    continue;
                  }
                }
                results.add(promo);
              } catch (e) {
                debugPrint('⚠️ [BillingSettings] Gagal parse promotion item: $e');
              }
            }
          }
          if (results.isNotEmpty) {
            return results;
          }
        }
      } catch (e) {
        debugPrint('⚠️ [BillingSettings] Fallback endpoint diskon $ep: $e');
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
      if (locId != null && locId.isNotEmpty)
        'location_id': int.tryParse(locId) ?? locId,
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
          final inner = raw['data'];
          if (inner is Map) {
            dataMap = Map<String, dynamic>.from(inner);
          } else {
            dataMap = Map<String, dynamic>.from(raw);
          }
        }
        if (dataMap != null && dataMap.isNotEmpty) {
          return StorePromotion.fromJson(dataMap);
        }
      } catch (e) {
        debugPrint('⚠️ [BillingSettings] POST voucher check failed on $ep: $e');
      }
    }

    final getEndpoints = [
      '/v1/pos/vouchers/$cleanCode',
      '/v1/pos/discounts/$cleanCode',
    ];
    for (final ep in getEndpoints) {
      try {
        final res = await ApiClient.instance.dio.get(ep, queryParameters: {
          if (locId != null && locId.isNotEmpty)
            'location_id': int.tryParse(locId) ?? locId,
        });
        final raw = res.data;
        Map<String, dynamic>? dataMap;
        if (raw is Map) {
          final inner = raw['data'];
          if (inner is Map) {
            dataMap = Map<String, dynamic>.from(inner);
          } else {
            dataMap = Map<String, dynamic>.from(raw);
          }
        }
        if (dataMap != null && dataMap.isNotEmpty) {
          return StorePromotion.fromJson(dataMap);
        }
      } catch (e) {
        debugPrint('⚠️ [BillingSettings] GET voucher check failed on $ep: $e');
      }
    }

    return null;
  }

  static Future<BillingSettings> fetch() async {
    try {
      final locId = SessionStorage.instance.getLocationId();
      final qLoc = {
        if (locId != null && locId.isNotEmpty)
          'location_id': int.tryParse(locId) ?? locId,
      };

      final endpoints = [
        '/v1/pos/config',
        '/preferences',
        '/v1/preferences',
        '/v1/pos/preferences',
        '/cafe/pos/config',
        '/cafe/preferences',
        '/v1/pos/tuslah-config',
        '/v1/me',
        '/me',
      ];

      Map<String, dynamic> mergedData = {};
      String? successfulEndpoint;

      for (final ep in endpoints) {
        try {
          final res = await ApiClient.instance.dio.get(ep, queryParameters: qLoc);
          final raw = res.data;
          if (raw != null) {
            final unpacked = _unpackJson(raw);
            if (unpacked.isNotEmpty) {
              mergedData.addAll(unpacked);
              successfulEndpoint ??= ep;
              if (unpacked.containsKey('pb1_rate') ||
                  unpacked.containsKey('tax_rate') ||
                  unpacked.containsKey('tax_percentage') ||
                  unpacked.containsKey('service_charge_rate') ||
                  unpacked.containsKey('service_rate') ||
                  unpacked.containsKey('rounding_enabled') ||
                  unpacked.containsKey('rounding_type')) {
                successfulEndpoint = ep;
                break;
              }
            }
          }
        } catch (_) {
          // Silent continue to fallback endpoint
        }
      }

      final storeName = mergedData.getString(
        'cafe_name',
        fallback: mergedData.getString(
          'business_name',
          fallback: mergedData.getString(
            'store_name',
            fallback: mergedData.getString('company_name', fallback: mergedData.getString('name')),
          ),
        ),
      );
      final storeAddress = mergedData.getString('address', fallback: mergedData.getString('store_address'));
      final storePhone = mergedData.getString('phone', fallback: mergedData.getString('store_phone'));
      final storeLogo = mergedData.getString('logo', fallback: mergedData.getString('logo_url', fallback: mergedData.getString('store_logo', fallback: mergedData.getString('image_url'))));
      if (storeName.isNotEmpty) {
        await SessionStorage.instance.saveTenantProfile(
          name: storeName,
          address: storeAddress.isNotEmpty ? storeAddress : null,
          phone: storePhone.isNotEmpty ? storePhone : null,
          logo: storeLogo.isNotEmpty ? storeLogo : null,
        );
      }

      var settings = BillingSettings.fromJson(mergedData);
      debugPrint('📊 [BillingSettings] Endpoint "$successfulEndpoint" -> PB1: ${settings.pb1Enabled} (${settings.pb1Rate}%, inclusive=${settings.pb1Inclusive}), Service: ${settings.serviceChargeEnabled} (${settings.serviceChargeRate}%), Rounding: ${settings.roundingEnabled} (step=${settings.roundingStep})');

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
      } catch (e) {
        debugPrint('⚠️ [BillingSettings] Gagal mengambil diskon API tambahan: $e');
      }

      return settings;
    } catch (e) {
      debugPrint('⚠️ [BillingSettings] Error fetch config: $e');
      var fallbackSettings = const BillingSettings(
        serviceChargeEnabled: false,
        serviceChargeRate: 0,
        pb1Enabled: false,
        pb1Rate: 0,
        pb1Inclusive: false,
        roundingEnabled: false,
        roundingStep: 0,
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
      } catch (e) {
        debugPrint('⚠️ [BillingSettings] Gagal fetch fallback discounts: $e');
      }

      return fallbackSettings;
    }
  }
}
