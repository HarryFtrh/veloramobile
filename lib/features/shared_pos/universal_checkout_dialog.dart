import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';
import '../../core/utils/audio_helper.dart';
import '../../core/utils/currency_formatter.dart';
import 'checkout_payment_method.dart';
import 'checkout_payment_panels.dart';
import 'pos_checkout_service.dart';
import 'receipt_printer_service.dart';

export 'checkout_payment_method.dart' show PosPaymentMethod;

class UniversalCheckoutDialog extends StatefulWidget {
  final List<PosCartItem> items;
  final num subtotal;
  final num tax;
  final num grandTotal;
  final String storeName;
  final String storeAddress;
  final String storePhone;
  final String cashierName;
  final String? tableOrCustomer;
  final String? qrisNmid;
  final Color accentColor;
  final Function(PosCheckoutResult result) onCompleted;

  const UniversalCheckoutDialog({
    super.key,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.grandTotal,
    required this.storeName,
    required this.storeAddress,
    required this.storePhone,
    required this.cashierName,
    this.tableOrCustomer,
    this.qrisNmid,
    this.accentColor = const Color(0xFFF59E0B),
    required this.onCompleted,
  });

  static Future<void> show(
    BuildContext context, {
    required List<PosCartItem> items,
    required num subtotal,
    required num tax,
    required num grandTotal,
    required String storeName,
    required String storeAddress,
    required String storePhone,
    required String cashierName,
    String? tableOrCustomer,
    String? qrisNmid,
    Color accentColor = const Color(0xFFF59E0B),
    required Function(PosCheckoutResult result) onCompleted,
  }) {
    final isMobile = context.isMobile;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 560),
        child: UniversalCheckoutDialog(
          items: items,
          subtotal: subtotal,
          tax: tax,
          grandTotal: grandTotal,
          storeName: storeName,
          storeAddress: storeAddress,
          storePhone: storePhone,
          cashierName: cashierName,
          tableOrCustomer: tableOrCustomer,
          qrisNmid: qrisNmid,
          accentColor: accentColor,
          onCompleted: onCompleted,
        ),
      ),
    );
  }

  @override
  State<UniversalCheckoutDialog> createState() =>
      _UniversalCheckoutDialogState();
}

class _UniversalCheckoutDialogState extends State<UniversalCheckoutDialog> {
  PosPaymentMethod _selectedMethod = PosPaymentMethod.cash;
  num _paidAmount = 0;
  bool _isSubmitting = false;
  String _selectedEdcBank = 'BCA';
  final _approvalCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _paidAmount = widget.grandTotal;
  }

  @override
  void dispose() {
    _approvalCodeController.dispose();
    super.dispose();
  }

  num get _changeAmount {
    if (_selectedMethod != PosPaymentMethod.cash) return 0;
    return _paidAmount >= widget.grandTotal
        ? _paidAmount - widget.grandTotal
        : 0;
  }

  bool get _isPayable {
    if (_isSubmitting) return false;
    return switch (_selectedMethod) {
      PosPaymentMethod.cash => _paidAmount >= widget.grandTotal,
      PosPaymentMethod.qris => true,
      PosPaymentMethod.debit =>
        _approvalCodeController.text.trim().isNotEmpty,
    };
  }

  Future<void> _processPayment() async {
    if (!_isPayable) return;

    setState(() => _isSubmitting = true);
    AudioHelper.actionFeedback();

    final paymentMethod = switch (_selectedMethod) {
      PosPaymentMethod.cash => 'cash',
      PosPaymentMethod.qris => 'qris',
      PosPaymentMethod.debit => 'debit',
    };
    final finalPaid = _selectedMethod == PosPaymentMethod.cash
        ? _paidAmount
        : widget.grandTotal;

    try {
      final result = await PosCheckoutService.instance.checkout(
        items: widget.items,
        totalAmount: widget.grandTotal,
        paidAmount: finalPaid,
        paymentMethod: paymentMethod,
        customerName: widget.tableOrCustomer,
      );

      final receiptData = ReceiptData(
        storeName: widget.storeName,
        storeAddress: widget.storeAddress,
        storePhone: widget.storePhone,
        invoiceNumber: result.invoiceNumber,
        cashierName: widget.cashierName,
        tableOrPatient: widget.tableOrCustomer,
        timestamp: DateTime.now(),
        items: widget.items,
        subtotal: widget.subtotal,
        tax: widget.tax,
        grandTotal: widget.grandTotal,
        paidAmount: finalPaid,
        changeAmount: _changeAmount,
        paymentMethod: paymentMethod.toUpperCase(),
      );

      await ReceiptPrinterService.instance.printReceipt(receiptData);

      AudioHelper.successFeedback();
      if (mounted) {
        Navigator.pop(context);
        widget.onCompleted(result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Pembayaran #${result.invoiceNumber} berhasil')),
                TextButton(
                  onPressed: () => ReceiptPrinterService.instance.shareReceipt(receiptData),
                  child: const Text('BAGI WA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            backgroundColor: WarmPalette.tertiary,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses pembayaran: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 28, 16, isMobile ? 16 : 28, 24),
      decoration: const BoxDecoration(
        color: WarmPalette.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: WarmPalette.line, width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(),
          const SizedBox(height: 16),
          _buildAmountSummary(),
          const SizedBox(height: 18),
          CheckoutPaymentMethodSelector(
            selectedMethod: _selectedMethod,
            accentColor: WarmPalette.primary,
            onChanged: (method) => setState(() => _selectedMethod = method),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: SingleChildScrollView(
              child: _buildSelectedPaymentPanel(),
            ),
          ),
          const SizedBox(height: 20),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: WarmPalette.line,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildAmountSummary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Tagihan',
              style: TextStyle(color: WarmPalette.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              CurrencyFormatter.format(widget.grandTotal),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: WarmPalette.primary,
              ),
            ),
          ],
        ),
        if (_selectedMethod == PosPaymentMethod.cash)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Kembalian',
                style: TextStyle(color: WarmPalette.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Text(
                CurrencyFormatter.format(_changeAmount),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: WarmPalette.tertiary,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSelectedPaymentPanel() {
    return switch (_selectedMethod) {
      PosPaymentMethod.cash => CashPaymentPanel(
        totalAmount: widget.grandTotal,
        paidAmount: _paidAmount,
        accentColor: WarmPalette.primary,
        onPaidChanged: (amount) => setState(() => _paidAmount = amount),
      ),
      PosPaymentMethod.qris => QrisPaymentPanel(
        storeName: widget.storeName,
        qrisNmid: widget.qrisNmid,
      ),
      PosPaymentMethod.debit => DebitPaymentPanel(
        selectedBank: _selectedEdcBank,
        onBankChanged: (bank) => setState(() => _selectedEdcBank = bank),
        approvalCodeController: _approvalCodeController,
        accentColor: WarmPalette.primary,
        onApprovalCodeChanged: () => setState(() {}),
      ),
    };
  }

  Widget _buildSubmitButton() {
    final label = switch (_selectedMethod) {
      PosPaymentMethod.cash =>
        'SELESAIKAN & CETAK STRUK (${CurrencyFormatter.format(_paidAmount)})',
      PosPaymentMethod.qris => 'KONFIRMASI QRIS BERHASIL',
      PosPaymentMethod.debit => 'KONFIRMASI PEMBAYARAN KARTU',
    };

    return ElevatedButton(
      onPressed: _isPayable ? _processPayment : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: WarmPalette.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: const StadiumBorder(),
        elevation: 0,
      ),
      child: _isSubmitting
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
    );
  }
}
