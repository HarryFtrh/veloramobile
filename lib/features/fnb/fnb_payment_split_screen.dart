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
import 'fnb_register_service.dart';
import 'split_bill/widgets/split_bill_left_pane.dart';
import 'split_bill/widgets/split_bill_payment_pane.dart';
import 'split_bill/widgets/split_bill_success_dialog.dart';

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
      final status = await QrisPaymentService.instance.checkStatus(inv.transactionId);
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
          'notes': l.note ?? (l.options.isNotEmpty ? l.options.map((o) => o.name).join(', ') : 'Porsi reguler'),
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
        final activeOrder = await TableService.instance.getActiveOrder(widget.tableId!);
        if (activeOrder != null && activeOrder.items.isNotEmpty) {
          _billItems = activeOrder.items.map((it) {
            final effectiveProdId = it.productId.isNotEmpty ? it.productId : it.id;
            return {
              'id': it.id,
              'order_item_id': it.id,
              'product_id': effectiveProdId,
              'name': it.name,
              'notes': it.notes ?? '',
              'price': it.price.toInt(),
              'qty': it.quantity,
              'payQty': it.quantity,
              'checked': true,
              'line': RegisterLine(
                productId: effectiveProdId,
                orderItemId: it.id,
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
      (acc, item) => acc + (((item['price'] as num?) ?? 0) * ((item['qty'] as num?)?.toInt() ?? 1)),
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
      final safePax = _paxCount > 0 ? _paxCount : 1;
      final perPerson = (totalBillAmount / safePax).ceil();
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
          final prodId = (item['product_id'] ?? item['productId'] ?? item['id'] ?? 'item-${item['name']}').toString();
          selectedLines.add(
            RegisterLine(
              productId: prodId,
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
      debugPrint('Checkout API error: $e');
      if (mounted) {
        setState(() => _submitting = false);
        final errorMsg = ApiException.from(e).message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pembayaran gagal: $errorMsg'),
            backgroundColor: WarmPalette.danger,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
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
      builder: (ctx) => SplitBillSuccessDialog(
        hasRemainingSplit: hasRemainingSplit,
        invoiceNumber: invoiceNumber,
        selectedMethod: _selectedMethod,
        selectedItemsTotal: _selectedItemsTotal,
        changeAmount: _changeAmount,
        splitMode: _splitMode,
        remainingItemsCount: remainingItems.length,
        paxToPay: _paxToPay,
        paxCount: _paxCount,
        receiptData: receiptData,
        onContinueSplit: () {
          setState(() {
            if (_splitMode == 'item') {
              _billItems = remainingItems;
              _activeBill = null;
              for (final it in _billItems) {
                it['checked'] = true;
              }
            } else {
              _paxCount = (_paxCount - _paxToPay).clamp(1, 20);
              _paxToPay = 1;
            }
            _updatePreset(_selectedItemsTotal);
            _qrisInvoice = null;
          });
        },
        onDone: () {
          if (widget.onPaymentComplete != null) {
            widget.onPaymentComplete!();
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  void _onToggleSplitBill(bool val) {
    setState(() {
      _isSplitBill = val;
      if (!val) {
        for (final it in _billItems) {
          it['checked'] = true;
          it['payQty'] = it['qty'];
        }
        _updatePreset(totalBillAmount);
      } else {
        _updatePreset(_selectedItemsTotal);
      }
      _qrisInvoice = null;
    });
  }

  void _onSelectSplitMode(String mode) {
    setState(() {
      _splitMode = mode;
      _updatePreset(_selectedItemsTotal);
      _qrisInvoice = null;
    });
  }

  void _onPaxCountChanged(int count) {
    setState(() {
      _paxCount = count;
      if (_paxToPay > _paxCount) _paxToPay = _paxCount;
      _updatePreset(_selectedItemsTotal);
      _qrisInvoice = null;
    });
  }

  void _onPaxToPayChanged(int toPay) {
    setState(() {
      _paxToPay = toPay;
      _updatePreset(_selectedItemsTotal);
      _qrisInvoice = null;
    });
  }

  void _onItemCheckToggled(int index) {
    setState(() {
      final isChecked = _billItems[index]['checked'] == true;
      _billItems[index]['checked'] = !isChecked;
      _updatePreset(_selectedItemsTotal);
      _qrisInvoice = null;
    });
  }

  void _onItemCheckChanged(int index, bool value) {
    setState(() {
      _billItems[index]['checked'] = value;
      _updatePreset(_selectedItemsTotal);
      _qrisInvoice = null;
    });
  }

  void _onItemPayQtyChanged(int index, int newQty) {
    setState(() {
      _billItems[index]['payQty'] = newQty;
      _updatePreset(_selectedItemsTotal);
      _qrisInvoice = null;
    });
  }

  void _onSelectAllItems() {
    setState(() {
      for (final it in _billItems) {
        it['checked'] = true;
      }
      _updatePreset(_selectedItemsTotal);
      _qrisInvoice = null;
    });
  }

  void _onDeselectAllItems() {
    setState(() {
      for (final it in _billItems) {
        it['checked'] = false;
      }
      _updatePreset(_selectedItemsTotal);
      _qrisInvoice = null;
    });
  }

  void _onSelectMethod(String method) {
    setState(() => _selectedMethod = method);
    if (method == 'qris' && _qrisInvoice == null && !_generatingQris) {
      _loadDynamicQris();
    }
  }

  Widget _buildLeftPane() {
    return SplitBillLeftPane(
      isSplitBill: _isSplitBill,
      onToggleSplitBill: _onToggleSplitBill,
      splitMode: _splitMode,
      onSelectSplitMode: _onSelectSplitMode,
      paxCount: _paxCount,
      onPaxCountChanged: _onPaxCountChanged,
      paxToPay: _paxToPay,
      onPaxToPayChanged: _onPaxToPayChanged,
      totalBillAmount: totalBillAmount,
      selectedItemsTotal: _selectedItemsTotal,
      billItems: _billItems,
      onItemCheckToggled: _onItemCheckToggled,
      onItemCheckChanged: _onItemCheckChanged,
      onItemPayQtyChanged: _onItemPayQtyChanged,
      onSelectAllItems: _onSelectAllItems,
      onDeselectAllItems: _onDeselectAllItems,
      billingSettings: _billingSettings,
    );
  }

  Widget _buildRightPane() {
    return SplitBillPaymentPane(
      selectedMethod: _selectedMethod,
      onSelectMethod: _onSelectMethod,
      selectedItemsTotal: _selectedItemsTotal,
      cashReceived: _cashReceived,
      onSelectPreset: _setPreset,
      isPaymentSufficient: _isPaymentSufficient,
      changeAmount: _changeAmount,
      submitting: _submitting,
      onFinishPayment: _finishPayment,
      qrisInvoice: _qrisInvoice,
      generatingQris: _generatingQris,
      checkingQrisStatus: _checkingQrisStatus,
      onVerifyQrisStatus: _verifyQrisStatus,
      onNumpadDigit: _onNumpadDigit,
      onNumpadClear: _onNumpadClear,
      onNumpadBackspace: _onNumpadBackspace,
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
            child: _buildLeftPane(),
          ),
        ),
        const VerticalDivider(width: 1, color: WarmPalette.line),
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildRightPane(),
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
          _buildLeftPane(),
          const SizedBox(height: 20),
          _buildRightPane(),
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
}
