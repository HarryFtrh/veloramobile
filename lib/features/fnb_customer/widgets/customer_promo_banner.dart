import 'package:flutter/material.dart';

import '../../fnb/billing.dart';

/// Hero promo / welcome banner card in the patron customer self-order screen.
class CustomerPromoBanner extends StatelessWidget {
  const CustomerPromoBanner({
    super.key,
    required this.billing,
    required this.onAction,
  });

  final BillingSettings? billing;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final activePromos = billing?.activePromotions ?? [];
    final hasPromo = activePromos.isNotEmpty;
    final promo = hasPromo ? activePromos.first : null;
    final bannerTag = hasPromo
        ? (promo!.code != null ? 'KODE: ${promo.code}' : 'PROMO HARI INI')
        : 'SELAMAT DATANG';
    final bannerTitle = hasPromo ? promo!.name : 'Pesan Langsung dari Meja';
    final bannerSubtitle = hasPromo
        ? (promo!.description?.isNotEmpty == true
            ? promo.description!
            : (promo.type == StorePromotionType.percentage
                ? 'Diskon ${promo.value.toInt()}% untuk menu pilihan'
                : 'Potongan Rp ${promo.value.toInt()}'))
        : 'Pilih menu favorit Anda dan nikmati pesanan cepat tanpa antre';
    final bannerAction = hasPromo ? 'Klaim Sekarang' : 'Pilih Menu';

    return Container(
      height: 168,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF2C1810),
            Color(0xFF5B301A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C1810).withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.2,
              child: const Icon(
                Icons.coffee_rounded,
                size: 140,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    bannerTag,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  bannerTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bannerSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE2D6CC),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: onAction,
                  icon: Text(
                    bannerAction,
                    style: const TextStyle(
                      color: Color(0xFF2C1810),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  label: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Color(0xFF2C1810),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2C1810),
                    elevation: 0,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
