// features/shared_pos/checkout_payment_panels.dart
import 'package:flutter/material.dart';

import '../../core/design/tokens.dart';
import '../../core/components/virtual_numpad.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/audio_helper.dart';
import '../../core/utils/currency_formatter.dart';
import 'checkout_payment_method.dart';

class CheckoutPaymentMethodSelector extends StatelessWidget {
  final PosPaymentMethod selectedMethod;
  final Color accentColor;
  final ValueChanged<PosPaymentMethod> onChanged;

  const CheckoutPaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: [
          _MethodTab(
            method: PosPaymentMethod.cash,
            selectedMethod: selectedMethod,
            accentColor: accentColor,
            icon: Icons.payments_rounded,
            title: 'Tunai',
            onChanged: onChanged,
          ),
          _MethodTab(
            method: PosPaymentMethod.qris,
            selectedMethod: selectedMethod,
            accentColor: accentColor,
            icon: Icons.qr_code_2_rounded,
            title: isMobile ? 'QRIS' : 'QRIS Statis/Dinamis',
            onChanged: onChanged,
          ),
          _MethodTab(
            method: PosPaymentMethod.debit,
            selectedMethod: selectedMethod,
            accentColor: accentColor,
            icon: Icons.credit_card_rounded,
            title: isMobile ? 'Debit / EDC' : 'Kartu Debit / EDC',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _MethodTab extends StatelessWidget {
  final PosPaymentMethod method;
  final PosPaymentMethod selectedMethod;
  final Color accentColor;
  final IconData icon;
  final String title;
  final ValueChanged<PosPaymentMethod> onChanged;

  const _MethodTab({
    required this.method,
    required this.selectedMethod,
    required this.accentColor,
    required this.icon,
    required this.title,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedMethod == method;
    final p = context.palette;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          AudioHelper.tapFeedback();
          onChanged(method);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : p.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : p.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CashPaymentPanel extends StatelessWidget {
  final num totalAmount;
  final num paidAmount;
  final Color accentColor;
  final ValueChanged<num> onPaidChanged;

  const CashPaymentPanel({
    super.key,
    required this.totalAmount,
    required this.paidAmount,
    required this.accentColor,
    required this.onPaidChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Builder(
          builder: (context) {
            final t = totalAmount.round();
            final presetSet = <int>{t};
            for (final step in const [10000, 20000, 50000, 100000]) {
              final up = ((t / step).ceil() * step);
              if (up > t) presetSet.add(up);
              if (presetSet.length >= 4) break;
            }
            final list = presetSet.toList()..sort();
            return Row(
              children: [
                for (int i = 0; i < list.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _CashPresetButton(
                      label: i == 0
                          ? 'Uang Pas'
                          : CurrencyFormatter.format(list[i]).replaceAll('Rp', '').trim(),
                      amount: list[i],
                      paidAmount: paidAmount,
                      accentColor: accentColor,
                      onSelected: onPaidChanged,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        VirtualNumpad(
          totalAmount: totalAmount,
          currentPaid: paidAmount,
          onPaidChanged: onPaidChanged,
        ),
      ],
    );
  }
}

class _CashPresetButton extends StatelessWidget {
  final String label;
  final num amount;
  final num paidAmount;
  final Color accentColor;
  final ValueChanged<num> onSelected;

  const _CashPresetButton({
    required this.label,
    required this.amount,
    required this.paidAmount,
    required this.accentColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = paidAmount == amount;
    final p = context.palette;
    return OutlinedButton(
      onPressed: () {
        AudioHelper.tapFeedback();
        onSelected(amount);
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: isSelected ? accentColor : p.textPrimary,
        backgroundColor: isSelected
            ? accentColor.withValues(alpha: 0.12)
            : Colors.white,
        side: BorderSide(
          color: isSelected ? accentColor : p.line,
          width: isSelected ? 1.5 : 1.0,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }
}

class QrisPaymentPanel extends StatelessWidget {
  final String storeName;
  final String? qrisNmid;

  const QrisPaymentPanel({super.key, required this.storeName, this.qrisNmid});

  @override
  Widget build(BuildContext context) {
    final effectiveNmid =
        qrisNmid ??
        SessionStorage.instance.getQrisNmid() ??
        'NMID-${SessionStorage.instance.getTenantId() ?? SessionStorage.instance.getLocationId() ?? "VELORA"}';
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.line),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: p.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: p.danger.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'QRIS',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: p.danger,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'GPN • Standar Pembayaran Nasional',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: p.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: p.tertiary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 12,
                      color: p.tertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '04:59',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: p.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.canvas,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.line),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.qr_code_2_rounded,
                  size: 160,
                  color: p.textPrimary,
                ),
                Text(
                  storeName.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'NMID: $effectiveNmid',
                  style: TextStyle(fontSize: 10, color: p.textSecondary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Minta pelanggan scan QRIS di atas dengan BCA, Mandiri, GoPay, OVO, Dana, ShopeePay',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: p.textSecondary),
          ),
        ],
      ),
    );
  }
}

class DebitPaymentPanel extends StatelessWidget {
  final String selectedBank;
  final ValueChanged<String> onBankChanged;
  final TextEditingController approvalCodeController;
  final Color accentColor;
  final VoidCallback onApprovalCodeChanged;

  const DebitPaymentPanel({
    super.key,
    required this.selectedBank,
    required this.onBankChanged,
    required this.approvalCodeController,
    required this.accentColor,
    required this.onApprovalCodeChanged,
  });

  @override
  Widget build(BuildContext context) {
    const banks = ['BCA', 'Mandiri', 'BRI', 'BNI'];
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Mesin EDC / Bank',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: banks.map((bank) {
              final isSelected = selectedBank == bank;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: OutlinedButton(
                    onPressed: () {
                      AudioHelper.tapFeedback();
                      onBankChanged(bank);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isSelected
                          ? primaryColor
                          : p.textSecondary,
                      backgroundColor: isSelected
                          ? primaryColor.withValues(alpha: 0.12)
                          : p.surfaceMuted,
                      side: BorderSide(
                        color: isSelected
                            ? primaryColor
                            : p.line,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      bank,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Text(
            'Approval Code / No. Referensi EDC',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.textSecondary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: approvalCodeController,
            keyboardType: TextInputType.number,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.textPrimary),
            decoration: InputDecoration(
              hintText: 'Cth: 839201',
              hintStyle: TextStyle(color: p.textSecondary),
              prefixIcon: Icon(
                Icons.pin_rounded,
                size: 20,
                color: p.textSecondary,
              ),
              filled: true,
              fillColor: p.canvas,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: p.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: p.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor),
              ),
            ),
            onChanged: (_) => onApprovalCodeChanged(),
          ),
          const SizedBox(height: 8),
          Text(
            'Ketik 6 digit nomor approval yang tertera pada kertas struk EDC setelah nasabah memasukkan PIN.',
            style: TextStyle(fontSize: 11, color: p.textSecondary),
          ),
        ],
      ),
    );
  }
}
