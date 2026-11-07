import 'app_config.dart';

/// Single source of truth for all business verticals across Velora POS.
/// Replaces fragmented, duplicate string substring matches (`contains('pharm')`, etc.).
enum BusinessVertical {
  pharmacy('pharmacy', 'Apotek & Klinik', 'Velora Pharmacy'),
  fnb('fnb', 'Restoran & Kafe', 'Velora F&B'),
  retail('retail', 'Retail & Toko', 'Velora POS'),
  sales('sales', 'Sales Lapangan', 'Velora Sales'),
  marketplace('marketplace', 'B2B Marketplace', 'Velora Marketplace'),
  customer('customer', 'Self-Order Pelanggan', 'Velora Self-Order');

  final String key;
  final String label;
  final String appTitle;

  const BusinessVertical(this.key, this.label, this.appTitle);

  /// Resolves the business vertical from business type string, user role, and/or build flavor.
  static BusinessVertical resolve({
    String? businessType,
    String? role,
    AppFlavor? flavor,
  }) {
    // 1. Build flavor override (when running specific flavor entrypoint)
    final f = flavor ?? AppConfig.instance.flavor;
    if (f == AppFlavor.pharmacy) return BusinessVertical.pharmacy;
    if (f == AppFlavor.sales) return BusinessVertical.sales;
    if (f == AppFlavor.marketplace) return BusinessVertical.marketplace;
    if (f == AppFlavor.customer) return BusinessVertical.customer;

    // 2. Role override
    final r = (role ?? '').toLowerCase().trim();
    if (r == 'customer' || r == 'member' || r == 'guest' || r == 'pelanggan') {
      return BusinessVertical.customer;
    }
    if (r.contains('sales') || r.contains('canvass') || r.contains('salesman')) {
      return BusinessVertical.sales;
    }
    if (r.contains('marketplace') || r.contains('buyer')) {
      return BusinessVertical.marketplace;
    }

    // 3. Normalized business type from backend / tenant
    final b = (businessType ?? '').toLowerCase().trim();
    if (b.contains('pharm') || b.contains('apotek') || b.contains('klinik') || b.contains('med')) {
      return BusinessVertical.pharmacy;
    }
    if (b.contains('fnb') || b.contains('cafe') || b.contains('resto') || b.contains('kopi') || b.contains('coffee') || b.contains('kuliner') || b.contains('food')) {
      return BusinessVertical.fnb;
    }
    if (b.contains('sales') || b.contains('distributor')) {
      return BusinessVertical.sales;
    }
    if (b.contains('marketplace') || b.contains('b2b')) {
      return BusinessVertical.marketplace;
    }

    // 4. Default fallback is Retail POS
    return BusinessVertical.retail;
  }
}
