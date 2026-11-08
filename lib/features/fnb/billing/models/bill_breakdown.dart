/// Hasil hitung tagihan satu keranjang transaksi POS.
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
