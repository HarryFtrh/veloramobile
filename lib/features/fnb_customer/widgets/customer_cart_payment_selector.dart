// features/fnb_customer/widgets/customer_cart_payment_selector.dart
import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';

class CustomerCartPaymentSelector extends StatelessWidget {
  const CustomerCartPaymentSelector({
    super.key,
    required this.selectedMethod,
    required this.onChanged,
  });

  final String selectedMethod;
  final ValueChanged<String> onChanged;

  static const List<_PaymentOptionData> _options = [
    _PaymentOptionData(
      name: 'GoPay',
      sub: 'E-Wallet Instan',
      icon: Icons.account_balance_wallet_rounded,
    ),
    _PaymentOptionData(
      name: 'QRIS',
      sub: 'BCA, Mandiri, OVO, ShopeePay, dll',
      icon: Icons.qr_code_scanner_rounded,
    ),
    _PaymentOptionData(
      name: 'DANA',
      sub: 'E-Wallet Dompet Digital',
      icon: Icons.wallet_rounded,
    ),
    _PaymentOptionData(
      name: 'Kartu Debit',
      sub: 'Visa / Mastercard / GPN',
      icon: Icons.credit_card_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Metode Pembayaran',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: p.textPrimary,
              ),
            ),
            Text(
              'Pilih Salah Satu',
              style: TextStyle(fontSize: 11, color: p.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final opt in _options)
          _PaymentOptionTile(
            name: opt.name,
            sub: opt.sub,
            icon: opt.icon,
            isSelected: selectedMethod == opt.name,
            onTap: () => onChanged(opt.name),
          ),
      ],
    );
  }
}

class _PaymentOptionData {
  const _PaymentOptionData({
    required this.name,
    required this.sub,
    required this.icon,
  });

  final String name;
  final String sub;
  final IconData icon;
}

class _PaymentOptionTile extends StatelessWidget {
  const _PaymentOptionTile({
    required this.name,
    required this.sub,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final String sub;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : p.line,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: p.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: p.textPrimary,
                    ),
                  ),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 11,
                      color: p.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? primaryColor : p.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
