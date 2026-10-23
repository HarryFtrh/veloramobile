// features/fnb/fnb_payment_split_screen.dart
import 'package:flutter/material.dart';

import '../../core/design/tokens.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/safe_json.dart';
import '../shared_pos/pos_checkout_service.dart';
import '../shared_pos/receipt_printer_service.dart';
import '../shared_pos/qris_payment_service.dart';
import '../shared_pos/sales_history_drawer.dart';
import '../tables/table_service.dart';
import 'billing.dart';
import 'cash_payment_numpad.dart';
import 'fnb_register_service.dart';

class FnbPaymentSplitScreen extends StatefulWidget {
  const FnbPaymentSplitScreen({
    super.key,
    this.orderId,
    this.tableId,
    this.tableNumber = 'Meja Kasir',
    this.guestCount = 1,
    this.waiterName,
    this.seatingDuration,
    this.totalAmount = 0,
    this.lines,
    this.bill,
    this.shiftId,
    this.customerName,
    this.onPaymentComplete,
  });

  final String? orderId;
  final String? tableId;
  final String tableNumber;
  final int guestCount;
  final String? waiterName;
  final String? seatingDuration;
  final int totalAmount;
  final List<RegisterLine>? lines;
  final BillBreakdown? bill;
  final String? shiftId;
  final String? customerName;
  final VoidCallback? onPaymentComplete;

  @override
  State<FnbPaymentSplitScreen> createState() => _FnbPaymentSplitScreenState();
}

class _FnbPaymentSplitScreenState extends State<FnbPaymentSplitScreen> {
  bool _isSplitBill = false;
  String _splitMode = 'item'; // 'item', 'equal'
  int _paxCount = 2; // Equal split: 2..20 orang
  int _paxToPay = 1; // Berapa orang dibayar sekarang: 1.._paxCount
  String _selectedMethod = 'cash'; // 'cash', 'qris', 'card', 'ewallet'
  int _cashReceived = 0;
  String _numpadBuffer = '0';
  bool _loading = false;
  bool _submitting = false;

  QrisInvoiceData? _qrisInvoice;
  bool _generatingQris = false;
  bool _checkingQrisStatus = false;

  List<Map<String, dynamic>> _billItems = [];
  BillBreakdown? _activeBill;

  BillingSettings? _billingSettings;

  @override
  void initState() {
    super.initState();
    _initData();
    _loadBilling();
  }

  Future<void> _loadDynamicQris() async {
    setState(() => _generatingQris = true);
    try {
      final invoice = await QrisPaymentService.instance.generateDynamicQris(
        amount: _selectedItemsTotal,
        orderId: widget.orderId,
        tableNumber: widget.tableNumber,
      );
      if (mounted) {
        setState(() {
          _qrisInvoice = invoice;
          _generatingQris = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _generatingQris = false);
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg.isNotEmpty ? msg : 'Gagal membuat tagihan QRIS'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _verifyQrisStatus() async {
    final inv = _qrisInvoice;
    if (inv == null) {
      _finishPayment();
      return;
    }

    setState(() => _checkingQrisStatus = true);
    try {
      final status = await QrisPaymentService.instance.checkStatus(
        inv.transactionId,
      );
      if (status == QrisPaymentStatus.paid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pembayaran QRIS Berhasil Diverifikasi!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _finishPayment();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                status == QrisPaymentStatus.expired
                    ? 'QRIS Telah Kedaluwarsa. Silakan muat ulang QR.'
                    : 'Pelanggan belum menyelesaikan scan/pembayaran QRIS.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (_) {
      await _finishPayment();
    } finally {
      if (mounted) setState(() => _checkingQrisStatus = false);
    }
  }

  Future<void> _loadBilling() async {
    try {
      final b = await BillingSettings.fetch();
      if (mounted) setState(() => _billingSettings = b);
    } catch (_) {}
  }

  Future<void> _initData() async {
    if (widget.lines != null && widget.lines!.isNotEmpty) {
      _billItems = widget.lines!.map((l) {
        return {
          'id': l.productId,
          'name': l.name,
          'notes':
              l.note ??
              (l.options.isNotEmpty
                  ? l.options.map((o) => o.name).join(', ')
                  : 'Porsi reguler'),
          'price': l.unitPrice.toInt(),
          'qty': l.quantity,
          'payQty': l.quantity,
          'checked': true,
          'line': l,
        };
      }).toList();
      _activeBill = widget.bill;
      _updatePreset(totalBillAmount);
    } else if (widget.tableId != null) {
      setState(() => _loading = true);
      try {
        final activeOrder = await TableService.instance.getActiveOrder(
          widget.tableId!,
        );
        if (activeOrder != null && activeOrder.items.isNotEmpty) {
          _billItems = activeOrder.items.map((it) {
            return {
              'id': it.id,
              'name': it.name,
              'notes': it.notes ?? '',
              'price': it.price.toInt(),
              'qty': it.quantity,
              'payQty': it.quantity,
              'checked': true,
              'line': RegisterLine(
                productId: it.id,
                name: it.name,
                price: it.price,
                quantity: it.quantity,
                note: it.notes,
              ),
            };
          }).toList();
        }
      } catch (_) {}
      setState(() => _loading = false);
      _updatePreset(totalBillAmount);
    }
  }

  void _updatePreset(int total) {
    _cashReceived = total;
    _numpadBuffer = _cashReceived > 0 ? _cashReceived.toString() : '';
  }

  int get totalBillAmount {
    if (_activeBill != null) return _activeBill!.total.round().clamp(0, 999999999);
    if (widget.totalAmount > 0) return widget.totalAmount;
    final sum = _billItems.fold<num>(
      0,
      (acc, item) =>
          acc + (((item['price'] as num?) ?? 0) * ((item['qty'] as num?)?.toInt() ?? 1)),
    );
    if (_billingSettings != null) {
      return BillCalculator.calculate(
        _billingSettings!,
        subtotal: sum,
      ).total.round().clamp(0, 999999999);
    }
    return sum.round().clamp(0, 999999999);
  }

  int get _selectedItemsTotal {
    if (!_isSplitBill) return totalBillAmount;
    if (_splitMode == 'equal') {
      final perPerson = (totalBillAmount / _paxCount).ceil();
      return (_paxToPay * perPerson).clamp(0, 999999999);
    }
    final itemsSum = _billItems
        .where((i) => i['checked'] == true)
        .fold<num>(
          0,
          (sum, i) {
            final price = (i['price'] as num?) ?? 0;
            final count = (i['payQty'] as num?)?.toInt() ?? ((i['qty'] as num?)?.toInt() ?? 1);
            return sum + (price * count);
          },
        );
    if (_billingSettings != null) {
      return BillCalculator.calculate(
        _billingSettings!,
        subtotal: itemsSum,
      ).total.round().clamp(0, 999999999);
    }
    return itemsSum.round().clamp(0, 999999999);
  }

  int get _changeAmount =>
      (_cashReceived - _selectedItemsTotal).clamp(0, 99999999);

  bool get _isPaymentSufficient {
    if (_selectedItemsTotal <= 0) return false;
    if (_isSplitBill && _splitMode == 'item' && !_billItems.any((i) => i['checked'] == true)) {
      return false;
    }
    if (_selectedMethod == 'cash') {
      return _cashReceived >= _selectedItemsTotal;
    }
    return true;
  }

  void _onNumpadDigit(String digit) {
    if (_numpadBuffer.length >= 12) return;
    setState(() {
      if (_numpadBuffer == '0') {
        _numpadBuffer = digit;
      } else {
        _numpadBuffer += digit;
      }
      _cashReceived = int.tryParse(_numpadBuffer) ?? 0;
    });
  }

  void _onNumpadClear() {
    setState(() {
      _numpadBuffer = '0';
      _cashReceived = 0;
    });
  }

  void _onNumpadBackspace() {
    setState(() {
      if (_numpadBuffer.length > 1) {
        _numpadBuffer = _numpadBuffer.substring(0, _numpadBuffer.length - 1);
      } else {
        _numpadBuffer = '0';
      }
      _cashReceived = int.tryParse(_numpadBuffer) ?? 0;
    });
  }

  void _setPreset(int amount) {
    setState(() {
      _cashReceived = amount;
      _numpadBuffer = amount.toString();
    });
  }

  Future<void> _finishPayment() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    String invoiceNumber =
        widget.orderId ??
        '#POS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final selectedLines = <RegisterLine>[];
    for (final item in _billItems) {
      if (!_isSplitBill || _splitMode == 'equal' || item['checked'] == true) {
        final totalQty = (item['qty'] as num?)?.toInt() ?? 1;
        final payQty = _isSplitBill && _splitMode == 'item'
            ? ((item['payQty'] as num?)?.toInt() ?? totalQty)
            : totalQty;
        final fullLine = item['line'];
        if (fullLine is RegisterLine) {
          selectedLines.add(
            RegisterLine(
              productId: fullLine.productId,
              name: fullLine.name,
              price: fullLine.price,
              quantity: payQty,
              note: fullLine.note,
              options: fullLine.options,
            ),
          );
        } else {
          selectedLines.add(
            RegisterLine(
              productId: (item['id'] ?? 'item-${item['name']}').toString(),
              name: item['name']?.toString() ?? 'Item',
              price: (item['price'] as num?) ?? 0,
              quantity: payQty,
              note: item['notes']?.toString(),
            ),
          );
        }
      }
    }

    try {
      final billingSettings = await BillingSettings.fetch();
      final calculatedBill = BillCalculator.calculate(
        billingSettings,
        subtotal: selectedLines.fold<num>(0, (s, l) => s + l.subtotal),
      );

      final outcome = await FnbRegisterService.instance.checkout(
        lines: selectedLines,
        bill: calculatedBill,
        method: _selectedMethod,
        paid: _selectedMethod == 'cash'
            ? _cashReceived
            : (_isSplitBill ? calculatedBill.total : totalBillAmount),
        orderId: widget.orderId,
        tableId: widget.tableId,
        customerName: widget.customerName,
        shiftId: widget.shiftId,
      );

      if (outcome.invoice.isNotEmpty) {
        invoiceNumber = outcome.invoice;
      }

      await ReceiptPrinterService.instance.openCashDrawer();
    } catch (e) {
      debugPrint('Checkout API note: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }

    final storeName =
        SessionStorage.instance.getLocationName() ??
        SessionStorage.instance.getTenantName() ??
        'Velora Cafe';
    final cashier = SessionStorage.instance.getUserName() ?? 'Kasir';
    final effectiveItems = selectedLines.isNotEmpty
        ? selectedLines
        : (widget.lines ?? []);
    final effectiveTotal = _selectedItemsTotal;
    final receiptData = ReceiptData(
      storeName: storeName,
      storeAddress: SessionStorage.instance.getStoreAddress() ?? '',
      storePhone: SessionStorage.instance.getStorePhone() ?? '',
      invoiceNumber: invoiceNumber,
      cashierName: cashier,
      tableOrPatient: widget.tableNumber,
      timestamp: DateTime.now(),
      items: effectiveItems
          .map(
            (l) => PosCartItem(
              productId: l.productId,
              name: l.name,
              price: l.unitPrice,
              quantity: l.quantity,
            ),
          )
          .toList(),
      subtotal: effectiveItems.fold<num>(0, (s, l) => s + l.subtotal),
      tax: (effectiveTotal - effectiveItems.fold<num>(0, (s, l) => s + l.subtotal)).clamp(0, double.infinity),
      grandTotal: effectiveTotal,
      paidAmount: _selectedMethod == 'cash' ? _cashReceived : effectiveTotal,
      changeAmount: _selectedMethod == 'cash' ? _changeAmount : 0,
      paymentMethod: _selectedMethod,
    );

    SalesHistoryDrawer.addRecord(
      CompletedSaleRecord(
        invoiceNumber: invoiceNumber,
        time: DateTime.now(),
        total: effectiveTotal,
        paymentMethod: _selectedMethod,
        tableOrCustomer: widget.tableNumber,
        items: List.from(receiptData.items),
      ),
    );

    // Hitung sisa item jika ini adalah split bill
    final remainingItems = <Map<String, dynamic>>[];
    if (_isSplitBill && _splitMode == 'item') {
      for (final item in _billItems) {
        final isChecked = item['checked'] == true;
        if (!isChecked) {
          remainingItems.add(item);
        } else {
          final totalQty = (item['qty'] as num?)?.toInt() ?? 1;
          final paidQty = (item['payQty'] as num?)?.toInt() ?? totalQty;
          if (paidQty < totalQty) {
            final leftQty = totalQty - paidQty;
            final updatedItem = Map<String, dynamic>.from(item);
            updatedItem['qty'] = leftQty;
            updatedItem['payQty'] = leftQty;
            updatedItem['checked'] = true;
            remainingItems.add(updatedItem);
          }
        }
      }
    }

    final bool hasRemainingSplit = _isSplitBill &&
        ((_splitMode == 'item' && remainingItems.isNotEmpty) ||
         (_splitMode == 'equal' && _paxToPay < _paxCount));

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: WarmPalette.canvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: WarmPalette.line, width: 1.2),
        ),
        title: Row(
          children: [
            Icon(
              hasRemainingSplit ? Icons.call_split_rounded : Icons.check_circle_rounded,
              color: hasRemainingSplit ? WarmPalette.secondary : WarmPalette.tertiary,
              size: 26,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                hasRemainingSplit ? 'Split Bill Berhasil!' : 'Pembayaran Berhasil!',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: WarmPalette.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.dialogMaxWidth),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nomor Struk: $invoiceNumber', style: const TextStyle(fontWeight: FontWeight.w600, color: WarmPalette.textPrimary)),
                const SizedBox(height: 4),
                Text('Metode: ${_selectedMethod.toUpperCase()}', style: const TextStyle(color: WarmPalette.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  'Total Sesi Ini: Rp ${_selectedItemsTotal.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: WarmPalette.primary),
                ),
                if (_selectedMethod == 'cash') ...[
                  const SizedBox(height: 4),
                  Text(
                    'Kembalian: Rp ${_changeAmount.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: WarmPalette.tertiary),
                  ),
                ],
                const SizedBox(height: 12),
                if (hasRemainingSplit) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: WarmPalette.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: WarmPalette.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: WarmPalette.secondary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _splitMode == 'item'
                                ? 'Masih ada ${remainingItems.length} jenis item tagihan yang belum lunas.'
                                : 'Telah dibayar $_paxToPay dari $_paxCount orang (Sisa ${_paxCount - _paxToPay} orang belum bayar).',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: WarmPalette.secondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: WarmPalette.surfaceMuted,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: WarmPalette.line),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.receipt_long, size: 20, color: WarmPalette.primary),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Laci kasir otomatis dibuka & transaksi tersimpan rapi.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: WarmPalette.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actionsOverflowButtonSpacing: 8,
        actionsOverflowDirection: VerticalDirection.down,
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ReceiptPrinterService.instance.shareReceipt(receiptData),
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Bagi Nota')),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ReceiptPrinterService.instance.printReceipt(receiptData);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Perintah cetak dikirim ke thermal printer')),
                      );
                    }
                  },
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Cetak Struk')),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ],
          ),
          if (hasRemainingSplit) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    if (_splitMode == 'item') {
                      _billItems = remainingItems;
                      _activeBill = null;
                      for (final it in _billItems) {
                        it['checked'] = true;
                      }
                    } else {
                      _paxCount = _paxCount - _paxToPay;
                      _paxToPay = 1;
                    }
                    _updatePreset(_selectedItemsTotal);
                    _qrisInvoice = null;
                  });
                },
                icon: const Icon(Icons.sync_alt_rounded, size: 16),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Lanjut Bayar Sisa Item (Split Berikutnya)', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WarmPalette.secondary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (widget.onPaymentComplete != null) {
                    widget.onPaymentComplete!();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Keluar (Sisa Tagihan Nanti)', style: TextStyle(color: WarmPalette.textSecondary)),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (widget.onPaymentComplete != null) {
                    widget.onPaymentComplete!();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: WarmPalette.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                child: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 860;

    return Scaffold(
      backgroundColor: WarmPalette.canvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: WarmPalette.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: WarmPalette.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.payments_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.orderId != null
                        ? 'Pesanan ${widget.orderId}'
                        : 'Pembayaran ${sanitizeDisplayName(widget.tableNumber)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: WarmPalette.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${sanitizeDisplayName(widget.tableNumber)} • Kasir: ${widget.waiterName ?? SessionStorage.instance.getUserName() ?? "Kasir"}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: WarmPalette.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: isWide
            ? [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: WarmPalette.surfaceMuted,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'TOTAL TAGIHAN SAAT INI',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: WarmPalette.textSecondary,
                        ),
                      ),
                      Text(
                        'Rp ${totalBillAmount.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: WarmPalette.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ]
            : null,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: WarmPalette.primary),
            )
          : isWide
          ? _buildWideLayout()
          : _buildMobileLayout(),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildBillColumn(),
          ),
        ),
        const VerticalDivider(width: 1, color: WarmPalette.line),
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildPaymentColumn(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildBillColumn(),
          const SizedBox(height: 20),
          _buildPaymentColumn(),
        ],
      ),
    );
  }

  Widget _buildBillColumn() {
    final isWide = MediaQuery.of(context).size.width >= 860;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle Bayar Penuh vs Split Bill
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: WarmPalette.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSplitBill = false;
                      for (final it in _billItems) {
                        it['checked'] = true;
                        it['payQty'] = it['qty'];
                      }
                      _updatePreset(totalBillAmount);
                      _qrisInvoice = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      color: !_isSplitBill
                          ? WarmPalette.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 16,
                          color: !_isSplitBill
                              ? Colors.white
                              : WarmPalette.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              isWide ? 'Bayar Penuh (Single Pay)' : 'Bayar Penuh',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: !_isSplitBill
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: !_isSplitBill
                                    ? Colors.white
                                    : WarmPalette.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSplitBill = true;
                      _updatePreset(_selectedItemsTotal);
                      _qrisInvoice = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      color: _isSplitBill
                          ? WarmPalette.secondary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.call_split_rounded,
                          size: 16,
                          color: _isSplitBill
                              ? Colors.white
                              : WarmPalette.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              isWide ? 'Bagi Tagihan (Split Bill)' : 'Split Bill',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _isSplitBill
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: _isSplitBill
                                    ? Colors.white
                                    : WarmPalette.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (_isSplitBill) ...[
          // Sub-toggle Split Mode: Per Item vs Bagi Rata
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WarmPalette.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _splitMode = 'item';
                        _updatePreset(_selectedItemsTotal);
                        _qrisInvoice = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: _splitMode == 'item' ? WarmPalette.surfaceMuted : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.checklist_rounded, size: 14, color: _splitMode == 'item' ? WarmPalette.primary : WarmPalette.textSecondary),
                          const SizedBox(width: 5),
                          Text(
                            'Pilih Per Item',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _splitMode == 'item' ? FontWeight.w800 : FontWeight.w600,
                              color: _splitMode == 'item' ? WarmPalette.primary : WarmPalette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _splitMode = 'equal';
                        _updatePreset(_selectedItemsTotal);
                        _qrisInvoice = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: _splitMode == 'equal' ? WarmPalette.surfaceMuted : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pie_chart_rounded, size: 14, color: _splitMode == 'equal' ? WarmPalette.secondary : WarmPalette.textSecondary),
                          const SizedBox(width: 5),
                          Text(
                            'Bagi Rata (Pax)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _splitMode == 'equal' ? FontWeight.w800 : FontWeight.w600,
                              color: _splitMode == 'equal' ? WarmPalette.secondary : WarmPalette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Bill Content Container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: WarmPalette.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isSplitBill && _splitMode == 'equal') ...[
                // Equal Split Control Card
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Jumlah Orang (Pax)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _paxCount > 2
                              ? () => setState(() {
                                    _paxCount--;
                                    if (_paxToPay > _paxCount) _paxToPay = _paxCount;
                                    _updatePreset(_selectedItemsTotal);
                                    _qrisInvoice = null;
                                  })
                              : null,
                          icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('$_paxCount Orang', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                        ),
                        IconButton(
                          onPressed: _paxCount < 20
                              ? () => setState(() {
                                    _paxCount++;
                                    _updatePreset(_selectedItemsTotal);
                                    _qrisInvoice = null;
                                  })
                              : null,
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: WarmPalette.primary),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: WarmPalette.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Seluruh Tagihan', style: TextStyle(fontSize: 12, color: WarmPalette.textSecondary)),
                          Text(
                            'Rp ${totalBillAmount.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Bagian per 1 Orang', style: TextStyle(fontSize: 12, color: WarmPalette.textSecondary)),
                          Text(
                            'Rp ${(totalBillAmount / _paxCount).ceil().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: WarmPalette.secondary),
                          ),
                        ],
                      ),
                      const Divider(height: 16, color: WarmPalette.line),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Bayar Berapa Orang Sekarang?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: _paxToPay > 1
                                    ? () => setState(() {
                                          _paxToPay--;
                                          _updatePreset(_selectedItemsTotal);
                                          _qrisInvoice = null;
                                        })
                                    : null,
                                icon: const Icon(Icons.remove, size: 16),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text('$_paxToPay', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              ),
                              IconButton(
                                onPressed: _paxToPay < _paxCount
                                    ? () => setState(() {
                                          _paxToPay++;
                                          _updatePreset(_selectedItemsTotal);
                                          _qrisInvoice = null;
                                        })
                                    : null,
                                icon: const Icon(Icons.add, size: 16),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ] else ...[
                // Item List Header with Quick Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Item Dipesan (${_billItems.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: WarmPalette.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isSplitBill) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                for (final it in _billItems) {
                                  it['checked'] = true;
                                }
                                _updatePreset(_selectedItemsTotal);
                                _qrisInvoice = null;
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text('Pilih Semua', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                          const Text('•', style: TextStyle(color: WarmPalette.line)),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                for (final it in _billItems) {
                                  it['checked'] = false;
                                }
                                _updatePreset(_selectedItemsTotal);
                                _qrisInvoice = null;
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text('Lepas Semua', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: WarmPalette.textSecondary)),
                          ),
                        ],
                      ),
                    ] else ...[
                      const Text(
                        'Dapur: Siap Dibayar',
                        style: TextStyle(
                          fontSize: 11,
                          color: WarmPalette.tertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                ..._billItems.map((item) {
                  final isChecked = item['checked'] == true;
                  final totalQty = (item['qty'] as num?)?.toInt() ?? 1;
                  final payQty = (item['payQty'] as num?)?.toInt() ?? totalQty;
                  final notes = item['notes']?.toString() ?? '';
                  final itemPrice = (item['price'] as num?) ?? 0;
                  final effectiveCount = _isSplitBill ? payQty : totalQty;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: _isSplitBill && isChecked
                          ? WarmPalette.primary.withValues(alpha: 0.04)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _isSplitBill
                          ? () {
                              setState(() {
                                item['checked'] = !isChecked;
                                _updatePreset(_selectedItemsTotal);
                                _qrisInvoice = null;
                              });
                            }
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isSplitBill)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Checkbox(
                                  value: isChecked,
                                  activeColor: WarmPalette.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  onChanged: (v) {
                                    setState(() {
                                      item['checked'] = v ?? false;
                                      _updatePreset(_selectedItemsTotal);
                                      _qrisInvoice = null;
                                    });
                                  },
                                ),
                              )
                            else
                              const Padding(
                                padding: EdgeInsets.only(right: 8, top: 4),
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                  color: WarmPalette.tertiary,
                                ),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${totalQty}x ${item['name'] ?? 'Item'}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: _isSplitBill && !isChecked
                                          ? WarmPalette.textSecondary
                                          : WarmPalette.textPrimary,
                                    ),
                                  ),
                                  if (notes.isNotEmpty)
                                    Text(
                                      notes,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: WarmPalette.textSecondary,
                                      ),
                                    ),
                                  if (_isSplitBill && isChecked && totalQty > 1) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('Bayar: ', style: TextStyle(fontSize: 10.5, color: WarmPalette.textSecondary)),
                                        InkWell(
                                          onTap: payQty > 1
                                              ? () {
                                                  setState(() {
                                                    item['payQty'] = payQty - 1;
                                                    _updatePreset(_selectedItemsTotal);
                                                    _qrisInvoice = null;
                                                  });
                                                }
                                              : null,
                                          borderRadius: BorderRadius.circular(6),
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: WarmPalette.surfaceMuted,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Icon(Icons.remove, size: 14, color: payQty > 1 ? WarmPalette.textPrimary : WarmPalette.textSecondary),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 6),
                                          child: Text('$payQty', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                                        ),
                                        InkWell(
                                          onTap: payQty < totalQty
                                              ? () {
                                                  setState(() {
                                                    item['payQty'] = payQty + 1;
                                                    _updatePreset(_selectedItemsTotal);
                                                    _qrisInvoice = null;
                                                  });
                                                }
                                              : null,
                                          borderRadius: BorderRadius.circular(6),
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: WarmPalette.surfaceMuted,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Icon(Icons.add, size: 14, color: payQty < totalQty ? WarmPalette.textPrimary : WarmPalette.textSecondary),
                                          ),
                                        ),
                                        Text(' dari $totalQty porsi', style: const TextStyle(fontSize: 10.5, color: WarmPalette.textSecondary)),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Text(
                              'Rp ${(itemPrice * effectiveCount).round().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: _isSplitBill && !isChecked
                                    ? WarmPalette.textSecondary
                                    : WarmPalette.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],

              const Divider(color: WarmPalette.line),
              const SizedBox(height: 6),
              _buildPriceRow(
                'Subtotal Item',
                'Rp ${_selectedItemsTotal.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
              ),
              _buildPriceRow(
                'PB1 Pajak Resto & Servis',
                _billingSettings == null
                    ? 'Termasuk'
                    : (_billingSettings!.pb1Enabled
                          ? '${(_billingSettings!.pb1Rate > 1 ? _billingSettings!.pb1Rate : _billingSettings!.pb1Rate * 100).round()}%'
                          : 'Non-aktif'),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Total Yang Harus Dibayar',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: WarmPalette.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'Rp ${_selectedItemsTotal.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: WarmPalette.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentColumn() {
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
              _buildMethodCardWidget(
                'cash',
                'Tunai / Cash',
                'Manual & Presets',
                Icons.money_rounded,
              ),
              _buildMethodCardWidget(
                'qris',
                'QRIS Dinamis',
                'Customer Display',
                Icons.qr_code_rounded,
              ),
              _buildMethodCardWidget(
                'card',
                'Debit / Kredit',
                'EDC BCA / Mandiri',
                Icons.credit_card_rounded,
              ),
              _buildMethodCardWidget(
                'ewallet',
                'E-Wallet',
                'GoPay, Shopee',
                Icons.account_balance_wallet_rounded,
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _buildMethodCardWidget(
                  'cash',
                  'Tunai / Cash',
                  'Manual & Presets',
                  Icons.money_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMethodCardWidget(
                  'qris',
                  'QRIS Dinamis',
                  'Customer Display',
                  Icons.qr_code_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMethodCardWidget(
                  'card',
                  'Debit / Kredit',
                  'EDC BCA / Mandiri',
                  Icons.credit_card_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMethodCardWidget(
                  'ewallet',
                  'E-Wallet',
                  'GoPay, Shopee',
                  Icons.account_balance_wallet_rounded,
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),

        if (_selectedMethod == 'cash') ...[
          Builder(
            builder: (ctx) {
              final t = _selectedItemsTotal;
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
                      _buildPresetCardWidget(
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
                      child: _buildPresetCardWidget(
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
              cashReceived: _cashReceived,
              onDigit: _onNumpadDigit,
              onClear: _onNumpadClear,
              onBackspace: _onNumpadBackspace,
            ),
            const SizedBox(height: 14),
            _buildCashSummaryBox(),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: CashPaymentNumpad(
                    cashReceived: _cashReceived,
                    onDigit: _onNumpadDigit,
                    onClear: _onNumpadClear,
                    onBackspace: _onNumpadBackspace,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(flex: 5, child: _buildCashSummaryBox()),
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
                  if (_generatingQris) ...[
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
                    if (_qrisInvoice?.transactionId != null) ...[
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
                          'ID: ${_qrisInvoice!.transactionId}',
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
                      'Total Tagihan: Rp ${_selectedItemsTotal.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: WarmPalette.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _qrisInvoice?.nmid != null
                          ? 'NMID: ${_qrisInvoice!.nmid} • Siap di-scan'
                          : 'Silakan scan QRIS di layar pelanggan / EDC',
                      style: const TextStyle(color: WarmPalette.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: (_submitting || _checkingQrisStatus)
                          ? null
                          : _verifyQrisStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WarmPalette.primary,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: _checkingQrisStatus
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
                      onPressed: !_submitting ? _finishPayment : null,
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

  Widget _buildCashSummaryBox() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: WarmPalette.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: WarmPalette.tertiary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calculate_outlined,
                      color: WarmPalette.tertiary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'KALKULASI KASIR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: WarmPalette.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isPaymentSufficient
                      ? WarmPalette.tertiary.withValues(alpha: 0.1)
                      : WarmPalette.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      'KEMBALIAN KONSUMEN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _isPaymentSufficient
                            ? WarmPalette.tertiary
                            : WarmPalette.danger,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Rp ${_changeAmount.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: _isPaymentSufficient
                              ? WarmPalette.tertiary
                              : WarmPalette.danger,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isPaymentSufficient
                              ? Icons.check_circle_rounded
                              : Icons.warning_amber_rounded,
                          size: 14,
                          color: _isPaymentSufficient
                              ? WarmPalette.tertiary
                              : WarmPalette.danger,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isPaymentSufficient
                              ? 'Pembayaran Cukup'
                              : 'Uang Kurang',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _isPaymentSufficient
                                ? WarmPalette.tertiary
                                : WarmPalette.danger,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildPriceRow(
                'Tagihan Bersih:',
                'Rp ${_selectedItemsTotal.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
              ),
              _buildPriceRow(
                'Uang Fisik Diterima:',
                'Rp ${_cashReceived.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
              ),
              _buildPriceRow(
                'Status Laci Kas:',
                'Siap Otomatis Buka',
                isPositive: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isPaymentSufficient && !_submitting
                ? _finishPayment
                : null,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.print_rounded, size: 20),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _submitting
                    ? 'Memproses Transaksi...'
                    : 'Selesaikan & Cetak Struk',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: WarmPalette.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodCardWidget(
    String key,
    String title,
    String sub,
    IconData icon,
  ) {
    final isSel = _selectedMethod == key;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedMethod = key);
        if (key == 'qris' && _qrisInvoice == null && !_generatingQris) {
          _loadDynamicQris();
        }
      },
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
                  color: isSel
                      ? WarmPalette.surfaceMuted
                      : WarmPalette.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetCardWidget(String title, int amount) {
    final isMatch = _cashReceived == amount;
    return GestureDetector(
      onTap: () => _setPreset(amount),
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

  Widget _buildPriceRow(String label, String value, {bool isPositive = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: WarmPalette.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isPositive
                  ? WarmPalette.tertiary
                  : WarmPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
