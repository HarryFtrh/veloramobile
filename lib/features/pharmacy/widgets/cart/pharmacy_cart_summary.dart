import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Ringkasan Finansial & CTA Pembayaran di Bagian Bawah Keranjang Apotek
class PharmacyCartSummary extends StatelessWidget {
  final int totalQty;
  final num subtotal;
  final num effectiveTuslah;
  final bool taxEnabled;
  final double taxRate;
  final String taxName;
  final bool taxInclusive;
  final num taxAmount;
  final num grandTotal;
  final bool hasItems;
  final VoidCallback onProceedToPayment;

  const PharmacyCartSummary({
    super.key,
    required this.totalQty,
    required this.subtotal,
    required this.effectiveTuslah,
    required this.taxEnabled,
    required this.taxRate,
    required this.taxName,
    required this.taxInclusive,
    required this.taxAmount,
    required this.grandTotal,
    required this.hasItems,
    required this.onProceedToPayment,
  });

  @override
  Widget build(BuildContext context) {
    const primaryEmerald = Color(0xFF059669);
    const borderColor = Color(0xFFE2E8F0);
    const textPrimary = Color(0xFF0F172A);
    const textMuted = Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal ($totalQty item)', style: const TextStyle(color: textMuted, fontSize: 11.5)),
              Text(
                CurrencyFormatter.format(subtotal),
                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 3),
          if (effectiveTuslah > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tuslah & Embalase Resep', style: TextStyle(color: textMuted, fontSize: 11.5)),
                Text(
                  CurrencyFormatter.format(effectiveTuslah),
                  style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 3),
          ],
          if (taxEnabled && taxRate > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$taxName (${(taxRate * 100).toStringAsFixed(0)}%${taxInclusive ? " Termasuk" : ""})',
                  style: const TextStyle(color: textMuted, fontSize: 11),
                ),
                Text(
                  CurrencyFormatter.format(taxAmount),
                  style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: Color(0xFF6D7A72)),
                ),
              ],
            ),
            const SizedBox(height: 3),
          ],
          const SizedBox(height: 10),

          // Grand Total Hero Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF047857), Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primaryEmerald.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL TAGIHAN',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 9.5,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      CurrencyFormatter.format(grandTotal),
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$totalQty Item',
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Action Button: Lanjut ke Pembayaran (Target Sentuh Minimal 48dp & Aksesibilitas WCAG)
          Semantics(
            button: true,
            label: hasItems ? 'Lanjut ke Pembayaran Kasir' : 'Keranjang Kasir Masih Kosong',
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: hasItems ? onProceedToPayment : null,
                icon: const Icon(Icons.payments_rounded, size: 20),
                label: Text(
                  hasItems
                      ? 'Lanjut ke Pembayaran'
                      : 'Keranjang Masih Kosong',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                  disabledForegroundColor: const Color(0xFF94A3B8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: hasItems ? 2 : 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
