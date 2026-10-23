import '../../core/utils/safe_json.dart';

enum SubscriptionStatus {
  active,
  trialing,
  pastDue,
  expired,
  canceled,
  unknown;

  static SubscriptionStatus fromString(String? val) {
    if (val == null) return SubscriptionStatus.active;
    final clean = val.trim().toLowerCase();
    switch (clean) {
      case 'active':
      case 'aktif':
        return SubscriptionStatus.active;
      case 'trial':
      case 'trialing':
      case 'percobaan':
        return SubscriptionStatus.trialing;
      case 'past_due':
      case 'pastdue':
      case 'tertunggak':
        return SubscriptionStatus.pastDue;
      case 'expired':
      case 'kedaluwarsa':
      case 'habis':
        return SubscriptionStatus.expired;
      case 'canceled':
      case 'cancelled':
      case 'dibatalkan':
        return SubscriptionStatus.canceled;
      default:
        return SubscriptionStatus.active;
    }
  }
}

/// Model data langganan & lisensi tenant/toko dari backend Velora.
class TenantSubscription {
  const TenantSubscription({
    required this.planName,
    required this.planCode,
    required this.status,
    this.billingCycle = 'monthly',
    this.validUntil,
    this.startsAt,
    this.maxLocations = 0,
    this.maxDevices = 0,
    this.features = const [],
    this.isTrial = false,
    this.priceFormatted,
    this.invoiceUrl,
  });

  final String planName;
  final String planCode;
  final SubscriptionStatus status;
  final String billingCycle;
  final DateTime? validUntil;
  final DateTime? startsAt;
  final int maxLocations;
  final int maxDevices;
  final List<String> features;
  final bool isTrial;
  final String? priceFormatted;
  final String? invoiceUrl;

  bool get isActive =>
      status == SubscriptionStatus.active || status == SubscriptionStatus.trialing;

  bool get isExpired {
    if (status == SubscriptionStatus.expired) return true;
    if (validUntil != null) {
      return DateTime.now().isAfter(validUntil!);
    }
    return false;
  }

  int? get daysRemaining {
    if (validUntil == null) return null;
    final diff = validUntil!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  bool get isNearExpiry {
    final days = daysRemaining;
    return days != null && days <= 7 && !isExpired;
  }

  String get statusDisplayName {
    if (isExpired) return 'Kedaluwarsa';
    switch (status) {
      case SubscriptionStatus.active:
        return 'Aktif';
      case SubscriptionStatus.trialing:
        return 'Masa Percobaan';
      case SubscriptionStatus.pastDue:
        return 'Tertunggak';
      case SubscriptionStatus.expired:
        return 'Kedaluwarsa';
      case SubscriptionStatus.canceled:
        return 'Dibatalkan';
      case SubscriptionStatus.unknown:
        return 'Aktif';
    }
  }

  String get billingCycleDisplayName {
    final clean = billingCycle.toLowerCase();
    if (clean.contains('year') || clean.contains('tahunan')) {
      return 'Tahunan';
    }
    if (clean.contains('life') || clean.contains('permanen')) {
      return 'Selamanya (Lifetime)';
    }
    return 'Bulanan';
  }

  factory TenantSubscription.fromJson(Map<String, dynamic> raw) {
    // Unwrap nested objects if wrapped in 'data', 'subscription', or 'plan'
    Map<String, dynamic> json = raw;
    if (raw['subscription'] is Map) {
      json = Map<String, dynamic>.from(raw['subscription'] as Map);
    } else if (raw['data'] is Map) {
      final inner = raw['data'] as Map;
      if (inner['subscription'] is Map) {
        json = Map<String, dynamic>.from(inner['subscription'] as Map);
      } else {
        json = Map<String, dynamic>.from(inner);
      }
    }

    final pName = json.getString(
      'plan_name',
      fallback: json.getString('name', fallback: json.getString('plan', fallback: 'Velora Pro')),
    );
    final pCode = json.getString(
      'plan_code',
      fallback: json.getString('code', fallback: pName.toLowerCase().replaceAll(' ', '_')),
    );

    final statusStr = json.getString('status', fallback: json.getString('subscription_status', fallback: 'active'));
    final status = SubscriptionStatus.fromString(statusStr);

    final cycle = json.getString('billing_cycle', fallback: json.getString('cycle', fallback: json.getString('interval', fallback: 'monthly')));

    DateTime? valid;
    final vStr = json.getString('valid_until', fallback: json.getString('expires_at', fallback: json.getString('end_date')));
    if (vStr.isNotEmpty) valid = DateTime.tryParse(vStr);

    DateTime? starts;
    final sStr = json.getString('starts_at', fallback: json.getString('created_at', fallback: json.getString('start_date')));
    if (sStr.isNotEmpty) starts = DateTime.tryParse(sStr);

    final maxLoc = json.getInt('max_locations', fallback: json.getInt('max_branches', fallback: json.getInt('locations_limit')));
    final maxDev = json.getInt('max_devices', fallback: json.getInt('devices_limit', fallback: json.getInt('pos_limit')));

    final feats = <String>[];
    final rawFeats = json['features'] ?? json['capabilities'] ?? json['modules'];
    if (rawFeats is List) {
      for (final f in rawFeats) {
        if (f != null && f.toString().isNotEmpty) feats.add(f.toString());
      }
    }

    return TenantSubscription(
      planName: pName,
      planCode: pCode,
      status: status,
      billingCycle: cycle,
      validUntil: valid,
      startsAt: starts,
      maxLocations: maxLoc,
      maxDevices: maxDev,
      features: feats,
      isTrial: json.getBool('is_trial', fallback: status == SubscriptionStatus.trialing),
      priceFormatted: json.getString('price_formatted', fallback: json.getString('price')),
      invoiceUrl: json.getString('invoice_url'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan_name': planName,
      'plan_code': planCode,
      'status': status.name,
      'billing_cycle': billingCycle,
      if (validUntil != null) 'valid_until': validUntil!.toIso8601String(),
      if (startsAt != null) 'starts_at': startsAt!.toIso8601String(),
      'max_locations': maxLocations,
      'max_devices': maxDevices,
      'features': features,
      'is_trial': isTrial,
      if (priceFormatted != null) 'price_formatted': priceFormatted,
      if (invoiceUrl != null) 'invoice_url': invoiceUrl,
    };
  }

  /// Fallback aman jika backend belum menyediakan rincian langganan
  factory TenantSubscription.standard({String? tenantName}) {
    return const TenantSubscription(
      planName: 'Velora Pro',
      planCode: 'pro',
      status: SubscriptionStatus.active,
      billingCycle: 'monthly',
      maxLocations: 0,
      maxDevices: 0,
      features: [
        'POS Kasir Multi-Terminal',
        'Kitchen Display System (KDS)',
        'Manajemen Meja & Open Bill',
        'Manajemen Resep & Stok Bahan',
        'Laporan Penjualan Real-Time',
      ],
      isTrial: false,
    );
  }
}
