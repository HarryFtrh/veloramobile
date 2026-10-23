import 'package:flutter_test/flutter_test.dart';
import 'package:velora_mobile/features/fnb/billing.dart';

BillingSettings settings({
  bool service = false,
  double serviceRate = 0,
  bool pb1 = false,
  double pb1Rate = 10,
  bool inclusive = false,
  bool rounding = false,
  int step = 100,
  String direction = 'floor',
}) =>
    BillingSettings(
      serviceChargeEnabled: service,
      serviceChargeRate: serviceRate,
      pb1Enabled: pb1,
      pb1Rate: pb1Rate,
      pb1Inclusive: inclusive,
      roundingEnabled: rounding,
      roundingStep: step,
      roundingScope: 'both',
      roundingDirection: direction,
    );

void main() {
  test('tanpa pajak dan layanan total sama dengan subtotal', () {
    final b = BillCalculator.calculate(settings(), subtotal: 45000);
    expect(b.total, 45000);
    expect(b.tax, 0);
    expect(b.serviceCharge, 0);
  });

  test('pajak dihitung dari subtotal + layanan', () {
    final b = BillCalculator.calculate(
      settings(service: true, serviceRate: 5, pb1: true, pb1Rate: 10),
      subtotal: 100000,
    );
    expect(b.serviceCharge, 5000);
    expect(b.tax, 10500);
    expect(b.total, 115500);
  });

  test('pajak inklusif tidak menambah total', () {
    final b = BillCalculator.calculate(settings(pb1: true, inclusive: true), subtotal: 50000);
    expect(b.tax, 0);
    expect(b.total, 50000);
  });

  test('diskon tidak boleh melebihi subtotal', () {
    final b = BillCalculator.calculate(settings(), subtotal: 20000, discount: 30000);
    expect(b.discount, 20000);
    expect(b.total, 0);
  });

  test('pembulatan ke bawah menghasilkan selisih negatif', () {
    final b = BillCalculator.calculate(settings(rounding: true, step: 500), subtotal: 12300);
    expect(b.total, 12000);
    expect(b.rounding, -300);
  });

  test('pembulatan ke atas', () {
    final b = BillCalculator.calculate(settings(rounding: true, step: 500, direction: 'ceil'), subtotal: 12300);
    expect(b.total, 12500);
    expect(b.rounding, 200);
  });
}
