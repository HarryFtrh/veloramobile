// features/fnb_customer/widgets/customer_cart_bottom_bar.dart
import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';

class CustomerCartBottomBar extends StatelessWidget {
  const CustomerCartBottomBar({
    super.key,
    required this.grandTotal,
    required this.discount,
    required this.isSubmitting,
    required this.onCheckout,
  });

  final int grandTotal;
  final int discount;
  final bool isSubmitting;
  final VoidCallback onCheckout;

  static String _formatRupiah(num value) {
    return value
        .round()
        .toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: WarmPalette.line)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL TAGIHAN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: WarmPalette.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Rp ${_formatRupiah(grandTotal)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: WarmPalette.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (discount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: WarmPalette.tertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 14,
                        color: WarmPalette.tertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Hemat ${discount >= 1000 ? "${(discount / 1000).round()}k" : "Rp $discount"}',
                        style: const TextStyle(
                          color: WarmPalette.tertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: WarmPalette.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Bayar Sekarang & Pesan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
