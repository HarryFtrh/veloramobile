import 'package:flutter/material.dart';
import '../../core/design/components.dart';
import '../../core/design/tokens.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/session_storage.dart';
import '../shared_pos/pos_checkout_service.dart';
import '../shared_pos/product_catalog_service.dart';
import '../shared_pos/receipt_printer_service.dart';
import '../shared_pos/shift_modal.dart';
import '../shared_pos/sales_history_drawer.dart';
import '../tables/table_service.dart';
import 'widgets/fnb_modifier_sheet.dart';
import 'widgets/fnb_open_bills_sheet.dart';
import 'fnb_payment_split_screen.dart';
import 'widgets/fnb_payment_sheet.dart';
import 'widgets/fnb_catalog_pane.dart';
import 'fnb_order_panel.dart';
import 'widgets/fnb_table_picker_sheet.dart';
import 'widgets/register/fnb_hold_order_dialog.dart';
import 'widgets/register/fnb_payment_success_dialog.dart';
import 'widgets/register/fnb_register_header.dart';
import 'widgets/register/fnb_shift_closed_view.dart';
import 'fnb_register_controller.dart';

export 'widgets/register/fnb_hold_order_dialog.dart';
export 'widgets/register/fnb_payment_success_dialog.dart';
export 'widgets/register/fnb_register_header.dart';
export 'widgets/register/fnb_shift_closed_view.dart';

class FnbRegisterScreen extends StatefulWidget {
  const FnbRegisterScreen({super.key, this.initialTable});

  final CafeTableInfo? initialTable;

  @override
  State<FnbRegisterScreen> createState() => _FnbRegisterScreenState();
}

class _FnbRegisterScreenState extends State<FnbRegisterScreen> {
  final _ctrl = RegisterController();

  @override
  void initState() {
    super.initState();
    _initScreen();
  }

  Future<void> _initScreen() async {
    await _ctrl.load();
    if (widget.initialTable != null) {
      await _ctrl.loadTableActiveOrder(widget.initialTable!);
    }
    _ensureShift();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _ensureShift() async {
    final s = await _ctrl.refreshShift();
    if (s != null && !s.isOpen && mounted) {
      await ShiftDialogs.showOpenShiftDialog(context, onOpened: (_) => _ctrl.refreshShift());
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  void _openSplitBill() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FnbPaymentSplitScreen(
          orderId: _ctrl.activeOrderId,
          tableId: _ctrl.table?.id,
          tableNumber: _ctrl.table?.name ?? (_ctrl.orderType == OrderType.dineIn ? 'Meja Kasir' : 'Takeaway'),
          totalAmount: _ctrl.bill?.total.round() ?? _ctrl.subtotal.round(),
          lines: List.from(_ctrl.lines),
          bill: _ctrl.bill,
          shiftId: int.tryParse(_ctrl.shiftId ?? ''),
          customerName: _ctrl.customerName,
          onPaymentComplete: () {
            _ctrl.reset();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<void> _kitchen() async {
    try {
      final orderId = await _ctrl.sendToKitchen();
      final displayId = orderId.isNotEmpty ? orderId : (_ctrl.existingOrderId ?? 'Berhasil');
      _ctrl.reset();
      _toast('Pesanan dikirim ke dapur (#$displayId)');
    } catch (e) {
      _toast(ApiException.from(e).message);
    }
  }

  Future<void> _hold() async {
    if (_ctrl.lines.isEmpty) return;

    if (_ctrl.orderType == OrderType.dineIn && _ctrl.table == null) {
      _toast('Pilih meja terlebih dahulu untuk pesanan Dine-In');
      _pickTable();
      return;
    }

    String? name = _ctrl.customerName;
    if (name.isEmpty && _ctrl.table == null) {
      final defaultLabel = 'Walk-In #${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      final enteredName = await FnbHoldOrderDialog.show(context, defaultLabel: defaultLabel);
      if (enteredName == null) return;
      name = enteredName;
    }

    try {
      final orderId = await _ctrl.holdOrder(name: name);
      final displayId = orderId.isNotEmpty ? orderId : (_ctrl.existingOrderId ?? 'Berhasil');
      _ctrl.reset();
      _toast('Pesanan disimpan di antrean hold (#$displayId)');
    } catch (e) {
      _toast(ApiException.from(e).message);
    }
  }

  void _openBillsModal() {
    final isMobile = context.isMobile;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: context.palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.88,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 720),
            child: FnbOpenBillsSheet(
              onSelectOrder: (order) async {
                await _ctrl.loadKitchenOrder(order);
                if (mounted) {
                  _toast('Memuat pesanan ${order.number} ke kasir');
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pay() async {
    if (_ctrl.busy) return;
    final bill = _ctrl.bill;
    if (bill == null || _ctrl.lines.isEmpty) return;

    if (_ctrl.shiftId == null) {
      final s = await _ctrl.refreshShift();
      if ((s == null || !s.isOpen || _ctrl.shiftId == null) && mounted) {
        _toast('Shift kasir belum aktif. Silakan buka shift kasir terlebih dahulu.');
        // ignore: use_build_context_synchronously
        await ShiftDialogs.showOpenShiftDialog(
          context,
          onOpened: (_) => _ctrl.refreshShift(),
        );
        if (_ctrl.shiftId == null || !mounted) return;
      }
    }

    // ignore: use_build_context_synchronously
    final choice = await FnbPaymentSheet.show(context, bill.total);
    if (choice == null || !mounted) return;

    try {
      final receiptItems = [
        for (final line in _ctrl.lines)
          PosCartItem(
            productId: line.productId,
            name: line.name,
            price: line.unitPrice,
            quantity: line.quantity,
            modifiers: line.options.isNotEmpty ? {for (final o in line.options) o.name: '+${o.price}'} : null,
          ),
      ];
      final receiptData = ReceiptData(
        storeName: SessionStorage.instance.getTenantName() ?? SessionStorage.instance.getLocationName() ?? '',
        storeAddress: SessionStorage.instance.getStoreAddress() ?? '',
        storePhone: SessionStorage.instance.getStorePhone() ?? '',
        invoiceNumber: '',
        cashierName: SessionStorage.instance.getUserName() ?? 'Kasir',
        tableOrPatient: _ctrl.table != null ? 'Meja ${_ctrl.table!.name}' : (_ctrl.customerName.isNotEmpty ? _ctrl.customerName : null),
        timestamp: DateTime.now(),
        items: receiptItems,
        subtotal: bill.subtotal,
        tax: bill.tax,
        grandTotal: bill.total,
        paidAmount: choice.paid,
        changeAmount: choice.paid > bill.total ? choice.paid - bill.total : 0,
        paymentMethod: choice.method,
      );

      final out = await _ctrl.pay(choice.method, choice.paid);

      SalesHistoryDrawer.addRecord(
        CompletedSaleRecord(
          invoiceNumber: out.invoice.isNotEmpty ? out.invoice : 'INV-${DateTime.now().millisecondsSinceEpoch}',
          time: DateTime.now(),
          total: bill.total,
          paymentMethod: choice.method,
          tableOrCustomer: _ctrl.table != null ? 'Meja ${_ctrl.table!.name}' : (_ctrl.customerName.isNotEmpty ? _ctrl.customerName : null),
          items: receiptItems,
        ),
      );

      _ctrl.reset();
      if (!mounted) return;

      final finalReceipt = ReceiptData(
        storeName: receiptData.storeName,
        storeAddress: receiptData.storeAddress,
        storePhone: receiptData.storePhone,
        invoiceNumber: out.invoice.isNotEmpty ? out.invoice : 'INV-${DateTime.now().millisecondsSinceEpoch}',
        cashierName: receiptData.cashierName,
        tableOrPatient: receiptData.tableOrPatient,
        timestamp: receiptData.timestamp,
        items: receiptData.items,
        subtotal: receiptData.subtotal,
        tax: receiptData.tax,
        grandTotal: receiptData.grandTotal,
        paidAmount: receiptData.paidAmount,
        changeAmount: out.change,
        paymentMethod: receiptData.paymentMethod,
        qrData: out.invoice.isNotEmpty ? 'https://velora.co.id/verify/${out.invoice}' : null,
      );

      await FnbPaymentSuccessDialog.show(
        context,
        invoiceNumber: out.invoice,
        changeAmount: out.change,
        finalReceipt: finalReceipt,
      );
    } catch (e) {
      _toast(ApiException.from(e).message);
    }
  }

  Future<void> _addProduct(PosProduct product) async {
    if (_ctrl.shiftId == null) {
      _toast('Buka shift kasir terlebih dahulu untuk transaksi');
      await ShiftDialogs.showOpenShiftDialog(
        context,
        onOpened: (_) => _ctrl.refreshShift(),
      );
      return;
    }
    final groups = _ctrl.groupsFor(product);
    if (groups.isEmpty) {
      _ctrl.add(product);
      return;
    }
    final res = await FnbModifierSheet.show(
      context: context,
      product: product,
      groups: groups,
    );
    if (res != null) {
      _ctrl.add(
        product,
        options: res.options,
        quantity: res.quantity,
        note: res.note,
      );
    }
  }

  Future<void> _pickTable() async {
    final chosen = await FnbTablePickerSheet.show(
      context,
      currentTable: _ctrl.table,
    );
    if (chosen != null && mounted) {
      if (chosen.id == FnbTablePickerSheet.clearTableSentinelId) {
        _ctrl.setTable(null);
        _toast('Meja dilepas (kembali ke Walk-In)');
      } else if (chosen.order != null) {
        await _ctrl.loadTableActiveOrder(chosen);
        if (mounted) {
          _toast('Memuat pesanan aktif meja ${chosen.name}');
        }
      } else {
        _ctrl.setTable(chosen);
        if (mounted) {
          _toast('Memilih meja ${chosen.name}');
        }
      }
    }
  }

  // ignore: unused_element
  Future<void> _syncOffline() async {
    final pending = PosCheckoutService.instance.pendingOfflineCount;
    if (pending == 0) {
      _toast('Semua transaksi sudah tersinkron ke cloud');
      return;
    }
    _toast('Menyinkronkan $pending transaksi offline...');
    final res = await PosCheckoutService.instance.syncOfflineQueue();
    if (mounted) {
      setState(() {});
      _toast('Sinkronisasi selesai: ${res['synced']} berhasil, ${res['failed']} gagal');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListenableBuilder(
      listenable: _ctrl,
      builder: (context, _) {
        if (_ctrl.loading) return Scaffold(backgroundColor: p.canvas, body: const SkeletonList());
        if (_ctrl.loadError != null) {
          return Scaffold(
            backgroundColor: p.canvas,
            appBar: AppBar(title: const Text('Kasir')),
            body: ErrorState(message: _ctrl.loadError!, onRetry: _ctrl.load),
          );
        }
        return LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth >= 600;
          final wideActions = c.maxWidth >= 840;
          final panelWidth = (c.maxWidth * 0.38).clamp(300.0, 420.0);
          final menu = FnbCatalogPane(
            ctrl: _ctrl,
            onAdd: _addProduct,
            maxWidth: c.maxWidth,
            onHold: _hold,
            onOpenBills: _openBillsModal,
          );
          return Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: p.canvas,
            appBar: wide
                ? null
                : FnbRegisterHeader(
                    ctrl: _ctrl,
                    wide: wide,
                    wideActions: wideActions,
                    onOpenSplitBill: _openSplitBill,
                    onOpenCashDrawer: () async {
                      await ReceiptPrinterService.instance.openCashDrawer();
                      if (context.mounted) _toast('Perintah buka laci kasir dikirim');
                    },
                  ),
            body: Directionality(
              textDirection: TextDirection.ltr,
              child: _ctrl.shiftId == null
                  ? FnbShiftClosedView(
                      onRefreshShift: () => _ctrl.refreshShift(),
                      onOpenBills: _openBillsModal,
                    )
                  : (wide
                      ? Row(
                          textDirection: TextDirection.ltr,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: menu,
                            ),
                            Container(
                              width: panelWidth,
                              decoration: BoxDecoration(color: p.surface, border: Border(left: BorderSide(color: p.line))),
                              child: FnbOrderPanel(
                                ctrl: _ctrl,
                                onPickTable: _pickTable,
                                onKitchen: _kitchen,
                                onHold: _hold,
                                onPay: _pay,
                                onOpenBills: _openBillsModal,
                                onSplitBill: _openSplitBill,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Expanded(child: menu),
                          ],
                        )),
            ),
            bottomNavigationBar: (wide || _ctrl.shiftId == null)
                ? null
                : (_ctrl.lines.isEmpty
                    ? null
                    : FnbCartBar(
                        ctrl: _ctrl,
                        onOpen: () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: false,
                          useSafeArea: true,
                          backgroundColor: p.surface,
                          clipBehavior: Clip.antiAlias,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (sheetContext) => SizedBox(
                            height: MediaQuery.sizeOf(sheetContext).height * 0.90,
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 560),
                                child: FnbOrderPanel(
                                  ctrl: _ctrl,
                                  onPickTable: _pickTable,
                                  isModal: true,
                                  onOpenBills: _openBillsModal,
                                  onSplitBill: () {
                                    Navigator.pop(sheetContext);
                                    _openSplitBill();
                                  },
                                  onKitchen: () async {
                                    Navigator.pop(sheetContext);
                                    await _kitchen();
                                  },
                                  onHold: () async {
                                    Navigator.pop(sheetContext);
                                    await _hold();
                                  },
                                  onPay: () async {
                                    Navigator.pop(sheetContext);
                                    await _pay();
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      )),
          );
        });
      },
    );
  }
}
