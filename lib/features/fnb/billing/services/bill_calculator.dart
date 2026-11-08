import '../models/bill_breakdown.dart';
import '../models/billing_settings.dart';

/// Rumus deterministik perhitungan tagihan kasir (PB1, Biaya Layanan, Diskon, Pembulatan)
/// dengan standar integer-guarded Rupiah untuk mencegah floating-point inaccuracy.
abstract final class BillCalculator {
  static num _round(BillingSettings s, num value) {
    if (!s.roundingEnabled) return value.round();
    final step = s.roundingStep > 1 ? s.roundingStep : 100;
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

  static BillBreakdown calculate(
    BillingSettings s, {
    required num subtotal,
    num discount = 0,
  }) {
    final disc = discount > subtotal ? subtotal : discount;
    final net = (subtotal - disc).clamp(0, double.infinity);

    final service = s.serviceChargeEnabled && s.serviceChargeRate > 0 && net > 0
        ? (net * (s.serviceChargeRate / 100)).round()
        : 0;
    final base = net + service;
    final tax = s.pb1Enabled && s.pb1Rate > 0 && base > 0
        ? (s.pb1Inclusive
            ? (base - (base / (1 + s.pb1Rate / 100))).round()
            : (base * (s.pb1Rate / 100)).round())
        : 0;

    final raw = base + (s.pb1Inclusive ? 0 : tax);
    final total = s.roundsTotal && raw > 0 ? _round(s, raw) : raw.round();
    return BillBreakdown(
      subtotal: subtotal.round(),
      discount: disc.round(),
      serviceCharge: service,
      tax: tax,
      rounding: total - raw,
      total: total,
    );
  }
}
