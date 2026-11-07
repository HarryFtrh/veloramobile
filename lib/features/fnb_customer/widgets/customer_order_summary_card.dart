import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../customer_models.dart';

/// Summary card displaying cart items, total amount, and download/share e-receipt button
class CustomerOrderSummaryCard extends StatelessWidget {
  final List<CustomerCartItem> items;
  final int totalAmount;
  final VoidCallback onDownloadOrShareReceipt;

  const CustomerOrderSummaryCard({
    super.key,
    required this.items,
    required this.totalAmount,
    required this.onDownloadOrShareReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: p.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      size: 18,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ringkasan Pesanan (${items.length} Item)',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: p.textPrimary,
                        ),
                      ),
                      Text(
                        'Total: Rp ${totalAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} • QRIS Kasir',
                        style: TextStyle(
                          fontSize: 12,
                          color: p.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: p.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: p.line),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${item.quantity}x ${item.product.name}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Rp ${item.totalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDownloadOrShareReceipt,
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text(
                'Download Nota Digital / E-Receipt',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: p.line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
