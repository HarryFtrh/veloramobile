import 'package:flutter/material.dart';
import '../../core/design/components.dart';
import '../../core/design/tokens.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/audio_helper.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/storage/session_storage.dart';
import '../shared_pos/pos_checkout_service.dart';
import '../shared_pos/product_catalog_service.dart';
import '../shared_pos/receipt_printer_service.dart';
import '../shared_pos/shift_modal.dart';
import '../shared_pos/shift_badge.dart';
import '../shared_pos/shift_service.dart';
import '../shared_pos/sales_history_drawer.dart';
import '../tables/table_service.dart';
import 'fnb_modifier_sheet.dart';
import 'fnb_open_bills_sheet.dart';
import 'fnb_payment_split_screen.dart';
import 'fnb_payment_sheet.dart';
import 'fnb_catalog_pane.dart';
import 'fnb_order_panel.dart';
import 'fnb_table_picker_sheet.dart';
import 'fnb_register_controller.dart';

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
          shiftId: _ctrl.shiftId,
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
      final nameCtrl = TextEditingController(text: defaultLabel);
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.palette.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.pause_circle_outline_rounded, color: context.palette.secondary, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Simpan Antrean (Hold)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Beri nama atau penanda pelanggan untuk antrean ini:',
                style: TextStyle(fontSize: 13, color: context.palette.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Nama Pelanggan / Penanda Antrean',
                  filled: true,
                  fillColor: context.palette.surfaceMuted,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.palette.line)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Simpan Antrean'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      name = nameCtrl.text.trim();
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
        changeAmount: 0,
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
      );

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.palette.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.check_circle_rounded, color: context.palette.success, size: 24),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Pembayaran Berhasil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (out.invoice.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.palette.line),
                  ),
                  child: Text(
                    'No. Faktur: #${out.invoice}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.palette.textSecondary),
                  ),
                ),
              if (out.change > 0) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.palette.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.palette.success.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UANG KEMBALIAN',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: context.palette.success),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(out.change),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: context.palette.success),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: Gap.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ReceiptPrinterService.instance.shareReceipt(finalReceipt),
                      icon: const Icon(Icons.share_rounded, size: 15),
                      label: const Text('Bagi (WA)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: Gap.xs),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ReceiptPrinterService.instance.printReceipt(finalReceipt);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Struk dikirim ke printer')));
                        }
                      },
                      icon: const Icon(Icons.print_outlined, size: 15),
                      label: const Text('Cetak Struk', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: Gap.xs),
                  IconButton.outlined(
                    tooltip: 'Buka laci kasir',
                    onPressed: () async {
                      await ReceiptPrinterService.instance.openCashDrawer();
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Sinyal laci kasir dikirim')));
                      }
                    },
                    icon: const Icon(Icons.point_of_sale, size: 18),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Selesai / Transaksi Baru', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
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
            appBar: wide ? null : AppBar(
              titleSpacing: wide ? 16 : 8,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: WarmPalette.primary, borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.coffee_maker_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                SessionStorage.instance.getTenantName() ?? SessionStorage.instance.getLocationName() ?? 'Kasir POS',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (wide && SessionStorage.instance.getLocationName() != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: WarmPalette.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  SessionStorage.instance.getLocationName()!,
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: WarmPalette.primary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Kasir: ${SessionStorage.instance.getUserName() ?? "Kasir"}',
                                style: const TextStyle(fontSize: 10, color: WarmPalette.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (PosCheckoutService.instance.pendingOfflineCount > 0)
                              InkWell(
                                onTap: _syncOffline,
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: WarmPalette.secondary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: WarmPalette.secondary, width: 0.8),
                                  ),
                                  child: Text(
                                    'Sync (${PosCheckoutService.instance.pendingOfflineCount})',
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: WarmPalette.secondary),
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: WarmPalette.tertiary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.circle, size: 6, color: WarmPalette.tertiary),
                                    SizedBox(width: 3),
                                    Text(
                                      'ONLINE',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: WarmPalette.tertiary),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                CashierShiftBadge(
                  onShiftChanged: () => _ctrl.refreshShift(),
                ),
                if (wideActions) ...[
                  const SizedBox(width: 4),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ReceiptPrinterService.instance.openCashDrawer();
                      if (context.mounted) _toast('Perintah buka laci kasir dikirim');
                    },
                    icon: const Icon(Icons.lock_open_rounded, size: 15),
                    label: const Text('Laci', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: WarmPalette.primary,
                      side: const BorderSide(color: WarmPalette.line),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Split Bill',
                    icon: const Icon(Icons.call_split_rounded, size: 19),
                    onPressed: _ctrl.lines.isEmpty ? null : _openSplitBill,
                  ),
                  IconButton(
                    tooltip: 'Pengaturan Printer',
                    icon: const Icon(Icons.print_outlined, size: 19),
                    onPressed: () => ReceiptPrinterService.instance.openSettings(context),
                  ),
                  IconButton(
                    tooltip: 'Muat ulang menu',
                    icon: const Icon(Icons.refresh_rounded, size: 19),
                    onPressed: _ctrl.load,
                  ),
                ] else ...[
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (val) async {
                      if (val == 'split') {
                        _openSplitBill();
                      } else if (val == 'drawer') {
                        await ReceiptPrinterService.instance.openCashDrawer();
                        if (context.mounted) _toast('Perintah buka laci kasir dikirim');
                      } else if (val == 'printer') {
                        ReceiptPrinterService.instance.openSettings(context);
                      } else if (val == 'refresh') {
                        _ctrl.load();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'split', child: Text('Split Bill')),
                      const PopupMenuItem(value: 'drawer', child: Text('Buka Laci Kasir')),
                      const PopupMenuItem(value: 'printer', child: Text('Pengaturan Printer')),
                      const PopupMenuItem(value: 'refresh', child: Text('Muat Ulang Menu')),
                    ],
                  ),
                ],
                const SizedBox(width: 8),
              ],
            ),
            body: Directionality(
              textDirection: TextDirection.ltr,
              child: _ctrl.shiftId == null
                  ? _buildShiftClosedView(context, wide: wide)
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
                                    Navigator.pop(context);
                                    _openSplitBill();
                                  },
                                  onKitchen: () async {
                                    Navigator.pop(context);
                                    await _kitchen();
                                  },
                                  onHold: () async {
                                    Navigator.pop(context);
                                    await _hold();
                                  },
                                  onPay: () async {
                                    Navigator.pop(context);
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

  Widget _buildShiftClosedView(BuildContext context, {required bool wide}) {
    final p = context.palette;
    final isMobile = context.isMobile;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 36,
          vertical: 28,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: WarmPalette.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: WarmPalette.primary.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.lock_clock_rounded,
                  size: 40,
                  color: WarmPalette.primary,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: WarmPalette.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: WarmPalette.danger.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 14, color: WarmPalette.danger),
                    SizedBox(width: 6),
                    Text(
                      'STATUS: SHIFT KASIR DITUTUP',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: WarmPalette.danger,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Laci & Register Kasir Terkunci',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: WarmPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Shift kasir saat ini sedang nonaktif. Buka shift kasir baru dengan modal kas awal untuk mulai menambahkan menu ke keranjang dan memproses transaksi penjualan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: WarmPalette.textSecondary,
                ),
              ),
              const SizedBox(height: 26),
              ElevatedButton.icon(
                onPressed: () async {
                  AudioHelper.tapFeedback();
                  await ShiftDialogs.showOpenShiftDialog(
                    context,
                    onOpened: (_) => _ctrl.refreshShift(),
                  );
                },
                icon: const Icon(Icons.point_of_sale_rounded, size: 20),
                label: const Text(
                  'BUKA SHIFT KASIR BARU',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WarmPalette.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: const StadiumBorder(),
                  elevation: 1,
                  shadowColor: WarmPalette.primary.withValues(alpha: 0.4),
                ),
              ),
              if (ShiftService.instance.lastCloseSummary != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    AudioHelper.tapFeedback();
                    ShiftDialogs.showShiftReportDialog(
                      context,
                      ShiftService.instance.lastCloseSummary!,
                      onDone: () {},
                    );
                  },
                  icon: const Icon(Icons.assessment_rounded, size: 18),
                  label: const Text(
                    'Lihat / Cetak Z-Report Terakhir',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: WarmPalette.primary,
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: WarmPalette.line),
                    shape: const StadiumBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider(color: WarmPalette.line)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'PILIHAN & PENGATURAN LAINNYA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: p.textTertiary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: WarmPalette.line)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildClosedQuickCard(
                      icon: Icons.receipt_long_rounded,
                      title: 'Riwayat & Antrean',
                      subtitle: 'Cek transaksi sebelumnya',
                      onTap: _openBillsModal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildClosedQuickCard(
                      icon: Icons.print_outlined,
                      title: 'Printer Thermal',
                      subtitle: 'Konfigurasi Bluetooth / IP',
                      onTap: () => ReceiptPrinterService.instance.openSettings(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClosedQuickCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: WarmPalette.line, width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          AudioHelper.tapFeedback();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: WarmPalette.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: WarmPalette.primary),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: WarmPalette.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: WarmPalette.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
