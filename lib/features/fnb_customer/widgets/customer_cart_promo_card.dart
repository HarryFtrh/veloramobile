// features/fnb_customer/widgets/customer_cart_promo_card.dart
import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../../fnb/billing.dart';
import 'customer_voucher_dialog.dart';

class CustomerCartPromoCard extends StatelessWidget {
  const CustomerCartPromoCard({
    super.key,
    required this.billing,
    required this.subtotal,
    required this.voucherApplied,
    this.voucherCode,
    required this.voucherDiscount,
    required this.onApplyVoucher,
    required this.onRemoveVoucher,
  });

  final BillingSettings? billing;
  final num subtotal;
  final bool voucherApplied;
  final String? voucherCode;
  final int voucherDiscount;
  final ValueChanged<PromoApplicationResult> onApplyVoucher;
  final VoidCallback onRemoveVoucher;

  static String _formatRupiah(num value) {
    return value
        .round()
        .toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    if ((!voucherApplied) && (billing?.activePromotions.isEmpty ?? true)) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF0E3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: WarmPalette.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: WarmPalette.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.discount_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      voucherCode ?? 'Promosi Toko',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: WarmPalette.textPrimary,
                      ),
                    ),
                    if (voucherApplied) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: WarmPalette.tertiary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'TERAPLIKASI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  voucherApplied
                      ? 'Potongan Rp ${_formatRupiah(voucherDiscount)} diterapkan'
                      : 'Gunakan promo diskon spesial toko',
                  style: const TextStyle(
                    fontSize: 12,
                    color: WarmPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () async {
              if (voucherApplied) {
                onRemoveVoucher();
                return;
              }
              final res = await showDialog<PromoApplicationResult>(
                context: context,
                builder: (ctx) => CustomerVoucherPromoDialog(
                  billing: billing,
                  subtotal: subtotal,
                ),
              );
              if (res != null) {
                onApplyVoucher(res);
              }
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: WarmPalette.line),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              minimumSize: Size.zero,
            ),
            child: Text(
              voucherApplied ? 'Hapus' : 'Pakai Promo',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: WarmPalette.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
