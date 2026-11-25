import '../billing/models/bill_breakdown.dart';
import '../billing/models/billing_settings.dart';
import '../billing/models/store_promotion.dart';
import '../billing/services/bill_calculator.dart';
import '../services/fnb_register_service.dart';

/// Manajer penetapan harga, hierarki diskon (Rule of Precedence), dan kalkulasi tagihan POS.
class FnbPricingManager {
  StorePromotion? activePromotion;
  String? activeVoucherCode;
  double voucherDiscountAmount = 0.0;
  String? memberTier;
  double memberDiscountPercent = 0.0;
  double manualDiscountPercent = 0.0;
  double manualDiscountAmount = 0.0;

  num calculateSubtotal(List<RegisterLine> lines) {
    return lines.fold<num>(0, (sum, l) => sum + l.subtotal);
  }

  num calculateMemberDiscount(num subtotal) {
    return memberDiscountPercent > 0
        ? (subtotal * (memberDiscountPercent / 100))
        : 0;
  }

  num calculatePromoDiscount(num subtotal) {
    if (activePromotion != null) {
      return activePromotion!.calculateDiscount(subtotal);
    }
    return voucherDiscountAmount;
  }

  num calculateManualDiscount(num subtotal) {
    if (manualDiscountAmount > 0) return manualDiscountAmount;
    if (manualDiscountPercent > 0) {
      return subtotal * (manualDiscountPercent / 100);
    }
    return 0;
  }

  num calculateTotalDiscount(num subtotal) {
    final member = calculateMemberDiscount(subtotal);
    final promo = calculatePromoDiscount(subtotal);
    final manual = calculateManualDiscount(subtotal);
    return (member + promo + manual).clamp(0, subtotal);
  }

  BillBreakdown? calculateBill(BillingSettings? billing, num subtotal) {
    if (billing == null) return null;
    return BillCalculator.calculate(
      billing,
      subtotal: subtotal,
      discount: calculateTotalDiscount(subtotal),
    );
  }

  void applyPromotion(StorePromotion promo, num subtotal) {
    activePromotion = promo;
    activeVoucherCode = promo.code ?? promo.name;
    voucherDiscountAmount = promo.calculateDiscount(subtotal);
  }

  void removePromotion() {
    activePromotion = null;
    activeVoucherCode = null;
    voucherDiscountAmount = 0.0;
  }

  void applyManualDiscount({double percent = 0.0, double amount = 0.0}) {
    manualDiscountPercent = percent;
    manualDiscountAmount = amount;
  }

  void removeManualDiscount() {
    manualDiscountPercent = 0.0;
    manualDiscountAmount = 0.0;
  }

  void reset() {
    activePromotion = null;
    activeVoucherCode = null;
    voucherDiscountAmount = 0.0;
    memberTier = null;
    memberDiscountPercent = 0.0;
    manualDiscountPercent = 0.0;
    manualDiscountAmount = 0.0;
  }

  /// Menilai dan memilih promosi toko otomatis terbaik dari server
  StorePromotion? findBestAutoPromotion({
    required List<StorePromotion> promotions,
    required num subtotal,
    String? locationId,
  }) {
    if (subtotal <= 0) return null;

    final candidates = promotions.where((p) {
      if (!p.isActive) return false;
      if (p.targetLocationIds.isNotEmpty && locationId != null && locationId.isNotEmpty) {
        if (!p.targetLocationIds.contains(locationId)) return false;
      }
      return p.isAutomatic || (p.code == null || p.code!.trim().isEmpty);
    }).toList();

    StorePromotion? bestPromo;
    double maxDisc = 0.0;
    for (final promo in candidates) {
      final d = promo.calculateDiscount(subtotal);
      if (d > maxDisc) {
        maxDisc = d;
        bestPromo = promo;
      }
    }
    return maxDisc > 0 ? bestPromo : null;
  }
}
