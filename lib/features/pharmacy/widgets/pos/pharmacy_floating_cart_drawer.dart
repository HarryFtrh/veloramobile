import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Mobile Floating Cart Drawer (Sticky above Bottom Nav / Screen Bottom)
class PharmacyFloatingCartDrawer extends StatelessWidget {
  final int totalItems;
  final num grandTotal;
  final int selectedPaymentMode;
  final ValueChanged<int> onSelectPaymentMode;
  final VoidCallback onOpenCartSheet;
  final VoidCallback onCheckout;

  const PharmacyFloatingCartDrawer({
    super.key,
    required this.totalItems,
    required this.grandTotal,
    required this.selectedPaymentMode,
    required this.onSelectPaymentMode,
    required this.onOpenCartSheet,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    const primaryEmerald = Color(0xFF059669);
    const darkSurface = Color(0xFF283044);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6D7A72).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Items summary & details toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: primaryEmerald,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$totalItems',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalItems Item Terpilih (Keranjang)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                      Text(
                        'Total: ${CurrencyFormatter.format(grandTotal)}',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: onOpenCartSheet,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rincian',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.keyboard_arrow_up_rounded, size: 18, color: Colors.white.withValues(alpha: 0.8)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Payment mode pills
          Row(
            children: [
              _buildPaymentPill(0, 'Tunai'),
              const SizedBox(width: 6),
              _buildPaymentPill(1, 'QRIS'),
              const SizedBox(width: 6),
              _buildPaymentPill(2, 'Debit'),
              const SizedBox(width: 6),
              _buildPaymentPill(3, 'Asuransi'),
            ],
          ),
          const SizedBox(height: 10),

          // Action CTA
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: onCheckout,
              icon: const Icon(Icons.payments_rounded, size: 18),
              label: const Text(
                'Proses Pembayaran / Bayar Cepat',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00855D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentPill(int index, String label) {
    final isSelected = selectedPaymentMode == index;
    return Expanded(
      child: InkWell(
        onTap: () => onSelectPaymentMode(index),
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0D9488) : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
