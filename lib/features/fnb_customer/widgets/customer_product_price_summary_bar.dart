import '../../../core/design/tokens.dart';
import 'package:flutter/material.dart';

class CustomerProductPriceSummaryBar extends StatelessWidget {
  const CustomerProductPriceSummaryBar({
    super.key,
    required this.totalPrice,
    required this.onSubmit,
  });

  final int totalPrice;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final formattedPrice = totalPrice.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: p.line),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TOTAL PEMBAYARAN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: p.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Rp $formattedPrice',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onSubmit,
                icon: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 18,
                ),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Tambah Pesanan',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }
}
