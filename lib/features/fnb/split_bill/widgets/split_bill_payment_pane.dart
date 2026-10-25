import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../../../shared_pos/qris_payment_service.dart';
import '../cash_payment_numpad.dart';
import 'split_bill_cash_pane.dart';

class SplitBillPaymentPane extends StatelessWidget {
  const SplitBillPaymentPane({
    super.key,
    required this.selectedMethod,
    required this.onSelectMethod,
    required this.selectedItemsTotal,
    required this.cashReceived,
    required this.onSelectPreset,
    required this.isPaymentSufficient,
    required this.changeAmount,
    required this.submitting,
    required this.onFinishPayment,
    required this.qrisInvoice,
    required this.generatingQris,
    required this.checkingQrisStatus,
    required this.onVerifyQrisStatus,
    required this.onNumpadDigit,
    required this.onNumpadClear,
    required this.onNumpadBackspace,
  });

  final String selectedMethod;
  final ValueChanged<String> onSelectMethod;
  final int selectedItemsTotal;
  final int cashReceived;
  final ValueChanged<int> onSelectPreset;
  final bool isPaymentSufficient;
  final int changeAmount;
  final bool submitting;
  final VoidCallback onFinishPayment;
  final QrisInvoiceData? qrisInvoice;
  final bool generatingQris;
  final bool checkingQrisStatus;
  final VoidCallback onVerifyQrisStatus;
  final ValueChanged<String> onNumpadDigit;
  final VoidCallback onNumpadClear;
  final VoidCallback onNumpadBackspace;

  Widget _buildMethodCard(
    String key,
    String title,
    String sub,
    IconData icon,
  ) {
    final isSel = selectedMethod == key;
    return GestureDetector(
      onTap: () => onSelectMethod(key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSel ? WarmPalette.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSel ? Colors.transparent : WarmPalette.line,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSel ? Colors.white : WarmPalette.primary,
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: isSel ? Colors.white : WarmPalette.textPrimary,
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                sub,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10,
                  color: isSel ? WarmPalette.surfaceMuted : WarmPalette.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetCard(String title, int amount) {
    final isMatch = cashReceived == amount;
    return GestureDetector(
      onTap: () => onSelectPreset(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isMatch ? WarmPalette.secondary : WarmPalette.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isMatch ? Colors.white : WarmPalette.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Rp ${amount.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isMatch ? Colors.white : WarmPalette.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.85,
            children: [
              _buildMethodCard('cash', 'Tunai / Cash', 'Manual & Presets', Icons.money_rounded),
              _buildMethodCard('qris', 'QRIS Dinamis', 'Customer Display', Icons.qr_code_rounded),
              _buildMethodCard('card', 'Debit / Kredit', 'EDC BCA / Mandiri', Icons.credit_card_rounded),
              _buildMethodCard('ewallet', 'E-Wallet', 'GoPay, Shopee', Icons.account_balance_wallet_rounded),
            ],
          )
        else
          Row(
            children: [
              Expanded(child: _buildMethodCard('cash', 'Tunai / Cash', 'Manual & Presets', Icons.money_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _buildMethodCard('qris', 'QRIS Dinamis', 'Customer Display', Icons.qr_code_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _buildMethodCard('card', 'Debit / Kredit', 'EDC BCA / Mandiri', Icons.credit_card_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _buildMethodCard('ewallet', 'E-Wallet', 'GoPay, Shopee', Icons.account_balance_wallet_rounded)),
            ],
          ),
        const SizedBox(height: 16),

        if (selectedMethod == 'cash') ...[
          Builder(
            builder: (ctx) {
              final t = selectedItemsTotal;
              final presetSet = <int>{t};
              for (final step in const [10000, 20000, 50000, 100000]) {
                final up = ((t / step).ceil() * step);
                if (up > t) presetSet.add(up);
                if (presetSet.length >= 4) break;
              }
              final list = presetSet.toList()..sort();
              if (isMobile) {
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.2,
                  children: [
                    for (int i = 0; i < list.length; i++)
                      _buildPresetCard(
                        i == 0 ? 'Uang Pas' : 'Pecahan',
                        list[i],
                      ),
                  ],
                );
              }
              return Row(
                children: [
                  for (int i = 0; i < list.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _buildPresetCard(
                        i == 0 ? 'Uang Pas' : 'Pecahan Lembar',
                        list[i],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          if (isMobile) ...[
            CashPaymentNumpad(
              cashReceived: cashReceived,
              onDigit: onNumpadDigit,
              onClear: onNumpadClear,
              onBackspace: onNumpadBackspace,
            ),
            const SizedBox(height: 14),
            SplitBillCashPane(
              isPaymentSufficient: isPaymentSufficient,
              changeAmount: changeAmount,
              selectedItemsTotal: selectedItemsTotal,
              cashReceived: cashReceived,
              submitting: submitting,
              onFinishPayment: onFinishPayment,
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: CashPaymentNumpad(
                    cashReceived: cashReceived,
                    onDigit: onNumpadDigit,
                    onClear: onNumpadClear,
                    onBackspace: onNumpadBackspace,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 5,
                  child: SplitBillCashPane(
                    isPaymentSufficient: isPaymentSufficient,
                    changeAmount: changeAmount,
                    selectedItemsTotal: selectedItemsTotal,
                    cashReceived: cashReceived,
                    submitting: submitting,
                    onFinishPayment: onFinishPayment,
                  ),
                ),
              ],
            ),
          ],
        ] else ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: WarmPalette.line),
            ),
            child: Center(
              child: Column(
                children: [
                  if (generatingQris) ...[
                    const SizedBox(height: 30),
                    const CircularProgressIndicator(
                      color: WarmPalette.primary,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Menghubungkan ke gateway QRIS backend...',
                      style: TextStyle(
                        color: WarmPalette.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ] else ...[
                    const Icon(
                      Icons.qr_code_2_rounded,
                      size: 160,
                      color: WarmPalette.textPrimary,
                    ),
                    if (qrisInvoice?.transactionId != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: WarmPalette.surfaceMuted,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'ID: ${qrisInvoice!.transactionId}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: WarmPalette.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      'Total Tagihan: Rp ${selectedItemsTotal.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: WarmPalette.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      qrisInvoice?.nmid != null
                          ? 'NMID: ${qrisInvoice!.nmid} • Siap di-scan'
                          : 'Silakan scan QRIS di layar pelanggan / EDC',
                      style: const TextStyle(color: WarmPalette.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: (submitting || checkingQrisStatus)
                          ? null
                          : onVerifyQrisStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WarmPalette.primary,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: checkingQrisStatus
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text('Memverifikasi Status ke Gateway...'),
                              ],
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.sync_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Cek Status Pembayaran (Live Gateway)'),
                              ],
                            ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: !submitting ? onFinishPayment : null,
                      style: TextButton.styleFrom(
                        foregroundColor: WarmPalette.textSecondary,
                      ),
                      child: const Text(
                        'Konfirmasi Manual (Bila Pelanggan Selesai Scan)',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
