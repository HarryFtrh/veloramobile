import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/utils/audio_helper.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../shared_pos/receipt_printer_service.dart';

/// Success dialog after settlement in FnB POS with receipt printing and drawer trigger
class FnbPaymentSuccessDialog extends StatefulWidget {
  final String invoiceNumber;
  final num changeAmount;
  final ReceiptData finalReceipt;

  const FnbPaymentSuccessDialog({
    super.key,
    required this.invoiceNumber,
    required this.changeAmount,
    required this.finalReceipt,
  });

  static Future<void> show(
    BuildContext context, {
    required String invoiceNumber,
    required num changeAmount,
    required ReceiptData finalReceipt,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FnbPaymentSuccessDialog(
        invoiceNumber: invoiceNumber,
        changeAmount: changeAmount,
        finalReceipt: finalReceipt,
      ),
    );
  }

  @override
  State<FnbPaymentSuccessDialog> createState() => _FnbPaymentSuccessDialogState();
}

class _FnbPaymentSuccessDialogState extends State<FnbPaymentSuccessDialog> {
  bool _isPrinting = false;
  bool _isOpeningDrawer = false;
  bool _copiedInvoice = false;

  String get _effectiveInvoice => widget.invoiceNumber.isNotEmpty
      ? widget.invoiceNumber
      : (widget.finalReceipt.invoiceNumber.isNotEmpty ? widget.finalReceipt.invoiceNumber : '-');

  Future<void> _handlePrint() async {
    if (_isPrinting) return;
    AudioHelper.actionFeedback();
    setState(() => _isPrinting = true);

    try {
      final ok = await ReceiptPrinterService.instance.printReceipt(widget.finalReceipt);
      if (mounted) {
        final msg = ReceiptPrinterService.instance.lastStatusMessage.isNotEmpty
            ? ReceiptPrinterService.instance.lastStatusMessage
            : (ok ? '✓ Struk berhasil dikirim ke printer' : '⚠️ Gagal mencetak struk');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(ok ? Icons.check_circle_rounded : Icons.error_outline_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(msg)),
              ],
            ),
            backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<void> _handleShare() async {
    AudioHelper.actionFeedback();
    await ReceiptPrinterService.instance.shareReceipt(widget.finalReceipt);
  }

  Future<void> _handleOpenDrawer() async {
    if (_isOpeningDrawer) return;
    AudioHelper.actionFeedback();
    setState(() => _isOpeningDrawer = true);

    try {
      await ReceiptPrinterService.instance.openCashDrawer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Sinyal buka laci kasir (RJ11) terkirim'),
              ],
            ),
            backgroundColor: Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) setState(() => _isOpeningDrawer = false);
        });
      }
    }
  }

  void _copyInvoice() {
    Clipboard.setData(ClipboardData(text: _effectiveInvoice));
    AudioHelper.tapFeedback();
    setState(() => _copiedInvoice = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedInvoice = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final dt = widget.finalReceipt.timestamp;
    final timeStr =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} WIB';

    final hasCustomerOrTable =
        widget.finalReceipt.tableOrPatient != null && widget.finalReceipt.tableOrPatient!.trim().isNotEmpty;

    return AlertDialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
      actionsPadding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Success Indicator & Title
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: p.success.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(Icons.check_circle_rounded, color: p.success, size: 28),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pembayaran Berhasil!',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: p.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          widget.finalReceipt.storeName.isNotEmpty
                              ? widget.finalReceipt.storeName
                              : 'Transaksi Selesai & Lunas',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: p.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. Invoice Card with Copy Action
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: p.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_long_rounded, size: 16, color: primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          'No. Faktur',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.textSecondary),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: _copyInvoice,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              children: [
                                Icon(
                                  _copiedInvoice ? Icons.done_all_rounded : Icons.copy_rounded,
                                  size: 13,
                                  color: _copiedInvoice ? p.success : primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _copiedInvoice ? 'Disalin' : 'Salin',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: _copiedInvoice ? p.success : primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      '#$_effectiveInvoice',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: p.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (hasCustomerOrTable) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person_pin_circle_outlined, size: 14, color: p.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.finalReceipt.tableOrPatient!,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            timeStr,
                            style: TextStyle(fontSize: 10, color: p.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 3. Payment Breakdown Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.line),
                ),
                child: Column(
                  children: [
                    // Total Tagihan
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Tagihan',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.textSecondary),
                        ),
                        Text(
                          CurrencyFormatter.format(widget.finalReceipt.grandTotal),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: p.textPrimary,
                          ),
                        ),
                      ],
                    ),

                    // Diskon (jika ada)
                    if (widget.finalReceipt.discount > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Potongan Diskon',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.danger),
                          ),
                          Text(
                            '-${CurrencyFormatter.format(widget.finalReceipt.discount)}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: p.danger),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 8),
                    Divider(color: p.line, height: 1),
                    const SizedBox(height: 8),

                    // Metode Bayar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Metode Pembayaran',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.textSecondary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.finalReceipt.paymentMethod.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (widget.finalReceipt.paymentMethod.toUpperCase() == 'CASH' ||
                        widget.finalReceipt.paymentMethod.toUpperCase() == 'TUNAI') ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Uang Diterima',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.textSecondary),
                          ),
                          Text(
                            CurrencyFormatter.format(widget.finalReceipt.paidAmount),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.textPrimary),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // 4. Kembalian Box (Highlight jika > 0, atau Lunas jika 0)
              if (widget.changeAmount > 0) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: p.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: p.success.withValues(alpha: 0.35), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: p.success.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.payments_rounded, color: p.success, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'UANG KEMBALIAN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: p.success,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(widget.changeAmount),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: p.success,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // 5. Actions: [Cetak Struk] + [Bagikan] + [Buka Laci]
              Row(
                children: [
                  // Tombol Cetak Struk
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isPrinting ? null : _handlePrint,
                      icon: _isPrinting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.print_rounded, size: 16),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _isPrinting ? 'Mencetak...' : 'Cetak',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor.withValues(alpha: 0.4), width: 1.2),
                        backgroundColor: primaryColor.withValues(alpha: 0.04),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Tombol Bagikan Struk (WA)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleShare,
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Bagikan',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF10B981),
                        side: const BorderSide(color: Color(0xFF6EE7B7), width: 1.2),
                        backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Tombol Buka Laci Kasir (RJ11)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isOpeningDrawer ? null : _handleOpenDrawer,
                      icon: _isOpeningDrawer
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.point_of_sale_rounded, size: 16),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Buka Laci',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD97706),
                        side: const BorderSide(color: Color(0xFFFCD34D), width: 1.2),
                        backgroundColor: const Color(0xFFD97706).withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: () {
              AudioHelper.actionFeedback();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
            label: const Text(
              'Pesanan Baru (Selesai)',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }
}
