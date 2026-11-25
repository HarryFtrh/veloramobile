// features/tables/tables_screen.dart
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/storage/session_storage.dart';
import '../../core/design/tokens.dart';
import '../fnb/screens/fnb_payment_split_screen.dart';
import '../fnb/widgets/fnb_payment_sheet.dart';
import '../shared_pos/services/pos_checkout_service.dart';
import '../shared_pos/services/receipt_printer_service.dart';
import 'cubit/tables_cubit.dart';
import 'cubit/tables_state.dart';
import 'widgets/table_grid_tile.dart';
import 'table_service.dart';
import 'widgets/table_add_dialog.dart';
import 'widgets/table_detail_pane.dart';
import 'widgets/table_empty_state.dart';
import 'widgets/table_filter_ribbon.dart';
import 'widgets/table_layout_header.dart';
import 'widgets/table_mobile_bottom_bar.dart';
import 'widgets/table_transfer_dialog.dart';

export 'cubit/tables_cubit.dart';
export 'cubit/tables_state.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key, this.onOpenTable});

  final void Function(CafeTableInfo table)? onOpenTable;

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  late final TablesCubit _cubit;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _cubit = TablesCubit()..startPolling();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _toast(String m) => context.showToast(m);

  Future<void> _openPayment(CafeTableInfo table, ActiveTableOrder? activeOrder) async {
    if (_isBusy) return;
    if (activeOrder?.isAlreadyPaid == true) {
      _toast('Tagihan ${table.name} sudah lunas');
      return;
    }

    _isBusy = true;
    try {
      final total = activeOrder?.totalAmount.round() ?? table.order?.total.round() ?? 0;
      final orderId = activeOrder?.id ?? table.order?.id;

      final choice = await FnbPaymentSheet.show(context, total, allowSplit: true);
      if (choice == null || !mounted) return;

      if (choice.method == 'split') {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FnbPaymentSplitScreen(
              totalAmount: total,
              tableId: table.id,
              tableName: table.name,
              orderId: orderId,
              activeOrder: activeOrder,
              customerName: activeOrder?.customerName,
              initialSplitBill: true,
              onPaymentComplete: () {
                _toast('${table.name} pembayaran selesai');
                _cubit.loadTables();
                Navigator.of(context).pop();
              },
            ),
          ),
        );
        return;
      }

      // Direct Single Payment
      final cubit = PaymentSplitCubit(
        tableId: table.id,
        activeOrder: activeOrder,
        totalAmount: total,
      );
      await cubit.ready;
      cubit.selectMethod(choice.method);
      if (choice.method == 'cash') {
        cubit.setPreset(choice.paid.toInt());
      }
      final ok = await cubit.checkout(
        fallbackTotal: total,
        orderId: orderId,
        tableId: table.id,
        customerName: activeOrder?.customerName,
        tableName: table.name,
      );
      if (!mounted) return;
      if (ok) {
        _toast('✓ ${table.name} pembayaran lunas');
        _cubit.loadTables();
      } else {
        _toast(cubit.state.error ?? 'Pembayaran meja gagal diproses');
      }
    } finally {
      _isBusy = false;
    }
  }

  Future<void> _printBill(CafeTableInfo t, ActiveTableOrder? act) async {
    final total = act?.totalAmount ?? t.order?.total ?? 0;
    final items = act?.items ?? [];
    try {
      final receiptData = ReceiptData(
        storeName: SessionStorage.instance.getLocationName() ?? 'Velora Cafe',
        tableName: t.name,
        customerName: act?.customerName,
        orderNumber: act?.id != null ? '#${act!.id}' : (t.order?.id != null ? '#${t.order!.id}' : null),
        cashierName: SessionStorage.instance.getUserName() ?? 'Kasir',
        total: total,
        timestamp: DateTime.now(),
        storeLogo: SessionStorage.instance.getStoreLogo(),
        showLogo: SessionStorage.instance.isPrinterShowLogo(),
        items: items.map((it) => PosCartItem(
          productId: it.productId,
          name: it.modifierNames.isNotEmpty ? '${it.name} (${it.modifierNames.join(", ")})' : it.name,
          price: it.price.toDouble(),
          quantity: it.quantity,
          note: it.notes,
        )).toList(),
      );

      await ReceiptPrinterService.instance.printReceipt(receiptData);
      _toast('✓ Bill ${t.name} berhasil dicetak');
    } catch (e) {
      _toast('Cetak bill: $e');
    }
  }

  Future<void> _releaseTable(CafeTableInfo t) async {
    if (_isBusy) return;
    _isBusy = true;
    try {
      final confirm = await AppConfirmDialog.show(
        context,
        title: 'Kosongkan ${t.name}?',
        message: 'Tagihan aktif pada meja ini akan diselesaikan dan status meja akan dikembalikan menjadi Meja Kosong.',
        confirmLabel: 'Kosongkan Meja',
        isDestructive: true,
      );

      if (confirm != true) return;
      await _cubit.releaseTable(t.id);
      _toast('✓ ${t.name} berhasil dikosongkan');
    } catch (e) {
      _toast('Gagal mengosongkan meja: $e');
    } finally {
      _isBusy = false;
    }
  }

  Future<void> _showTransferTableDialog(CafeTableInfo fromTable, List<CafeTableInfo> tables) async {
    final availableTables = tables
        .where((tbl) => tbl.status == TableStatus.available && tbl.id != fromTable.id)
        .toList();

    if (availableTables.isEmpty) {
      _toast('Tidak ada meja kosong lain untuk pindah');
      return;
    }

    await showTransferTableSheet(
      context,
      fromTable: fromTable,
      availableTables: availableTables,
      onTransferred: (target) {
        _toast('✓ Meja ${fromTable.name} berhasil dipindah ke ${target.name}');
        _cubit.loadTables();
      },
    );
  }

  void _showAddTableDialog() {
    showAddTableDialog(
      context,
      onTableAdded: (name) {
        _toast('✓ $name berhasil ditambahkan');
        _cubit.loadTables();
      },
      onError: (msg) => _toast(msg),
    );
  }

  Future<void> _seedDefaultTables() async {
    if (_isBusy) return;
    _isBusy = true;
    _toast('Sedang membuat meja standar (01 s/d 08)...');
    try {
      await _cubit.seedDefaultTables();
      _toast('✓ Meja standar berhasil dibuat');
    } catch (e) {
      _toast('Gagal membuat meja: $e');
    } finally {
      _isBusy = false;
    }
  }

  void _showMobileTableDetailSheet(CafeTableInfo t, ActiveTableOrder? act, bool isLoadingOrder, List<CafeTableInfo> tables) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.88,
        child: TableDetailPane(
          table: t,
          activeOrder: act,
          isLoadingActiveOrder: isLoadingOrder,
          isModal: true,
          onClose: () => Navigator.pop(sheetContext),
          onOpenPos: (table) {
            Navigator.pop(sheetContext);
            widget.onOpenTable?.call(table);
          },
          onPrintBill: (tbl) => _printBill(tbl, act),
          onTransferTable: (tbl) => _showTransferTableDialog(tbl, tables),
          onReleaseTable: _releaseTable,
          onDirectPayment: () {
            Navigator.pop(sheetContext);
            _openPayment(t, act);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<TablesCubit, TablesState>(
        builder: (context, state) {
          final tables = state.tableList;
          final filteredTables = state.filteredTables;
          final selectedTable = state.selectedTable;
          final selectedActiveOrder = state.selectedActiveOrder;
          final isLoadingActiveOrder = state.isLoadingActiveOrder;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 640;

              return Scaffold(
                backgroundColor: p.canvas,
                appBar: (!isWide || canPop)
                    ? AppBar(
                        backgroundColor: p.surface,
                        elevation: 0,
                        titleSpacing: 14,
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.table_restaurant_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Denah Meja',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: p.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF059669).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'LIVE',
                                          style: TextStyle(
                                            color: Color(0xFF059669),
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${SessionStorage.instance.getLocationName() ?? "Outlet Utama"} • Status Terkini',
                                    style: TextStyle(fontSize: 11, color: p.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          IconButton(
                            tooltip: 'Muat ulang',
                            icon: Icon(Icons.refresh_rounded, color: p.textPrimary),
                            onPressed: () => _cubit.loadTables(),
                          ),
                          IconButton(
                            tooltip: 'Tambah Meja',
                            icon: Icon(Icons.add_circle_outline_rounded, color: primaryColor),
                            onPressed: _showAddTableDialog,
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert_rounded, color: p.textPrimary),
                            onSelected: (val) {
                              if (val == 'seed') _seedDefaultTables();
                              if (val == 'reservation') _toast('Formulir reservasi baru dibuka');
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'seed',
                                child: Row(
                                  children: [
                                    Icon(Icons.auto_awesome_rounded, size: 18, color: primaryColor),
                                    const SizedBox(width: 8),
                                    const Text('Buat Meja Standar (01-08)'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'reservation',
                                child: Row(
                                  children: [
                                    Icon(Icons.bookmark_add_outlined, size: 18, color: Color(0xFF059669)),
                                    SizedBox(width: 8),
                                    Text('Buat Reservasi Baru'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : null,
                body: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Floor Canvas
                    Expanded(
                      flex: isWide ? 7 : 1,
                      child: CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              isWide ? 16 : 12,
                              isWide ? 16 : 10,
                              isWide ? 16 : 12,
                              14,
                            ),
                            sliver: SliverList.list(
                              children: [
                          if (state.error != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: p.danger.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: p.danger.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline_rounded, color: p.danger, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      state.error!,
                                      style: TextStyle(
                                        color: p.danger,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _cubit.loadTables(),
                                    child: const Text('Coba Lagi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            ),
                          if (isWide)
                            TableLayoutHeader(
                              locationName: SessionStorage.instance.getLocationName() ?? "Outlet",
                              onAddTable: _showAddTableDialog,
                              onReservation: () => _toast('Formulir reservasi baru dibuka'),
                            ),

                          // Dynamic Unified Filter Ribbon & Occupancy Pill
                          TableFilterRibbon(
                            selectedFilter: state.selectedFilter,
                            onFilterSelected: (val) => _cubit.setFilter(val),
                            allCount: state.countAll,
                            availableCount: state.countAvailable,
                            occupiedCount: state.countOccupied,
                            reservedCount: state.countReserved,
                          ),
                              ],
                            ),
                          ),

                          // Tables Grid or Empty State (virtualized SliverGrid)
                          if (tables.isEmpty && !state.isLoading)
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                isWide ? 16 : 12,
                                0,
                                isWide ? 16 : 12,
                                (!isWide && selectedTable != null) ? 80 : 20,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: TableEmptyState(
                                  onSeedDefault: _seedDefaultTables,
                                  onAddTableManual: _showAddTableDialog,
                                ),
                              ),
                            )
                          else if (filteredTables.isEmpty && !state.isLoading)
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                isWide ? 16 : 12,
                                0,
                                isWide ? 16 : 12,
                                (!isWide && selectedTable != null) ? 80 : 20,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: TableEmptyState(
                                  isFiltered: true,
                                  filterLabel: state.selectedFilter == 'available'
                                      ? 'Kosong'
                                      : (state.selectedFilter == 'occupied' ? 'Terisi' : 'Reservasi'),
                                  onSeedDefault: _seedDefaultTables,
                                  onAddTableManual: _showAddTableDialog,
                                  onResetFilter: () => _cubit.setFilter('all'),
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                isWide ? 16 : 12,
                                0,
                                isWide ? 16 : 12,
                                (!isWide && selectedTable != null) ? 80 : 20,
                              ),
                              sliver: SliverGrid(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isWide ? (constraints.maxWidth > 900 ? 3 : 2) : 2,
                                  childAspectRatio: isWide ? 1.35 : 1.16,
                                  crossAxisSpacing: isWide ? 14 : 10,
                                  mainAxisSpacing: isWide ? 14 : 10,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (ctx, i) {
                                    final t = filteredTables[i];
                                    return TableGridTile(
                                      table: t,
                                      isSelected: selectedTable?.id == t.id,
                                      onSelect: () => _cubit.selectTable(t),
                                      onOpenTable: widget.onOpenTable,
                                    );
                                  },
                                  childCount: filteredTables.length,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Right Side Panel: Detail Meja Aktif (Desktop/Tablet)
                    if (isWide) ...[
                      VerticalDivider(width: 1, color: p.line),
                      Expanded(
                        flex: 4,
                        child: Container(
                          color: p.surface,
                          child: TableDetailPane(
                            table: selectedTable,
                            activeOrder: selectedActiveOrder,
                            isLoadingActiveOrder: isLoadingActiveOrder,
                            isModal: false,
                            onClose: () => _cubit.selectTable(null),
                            onOpenPos: (table) => widget.onOpenTable?.call(table),
                            onPrintBill: (tbl) => _printBill(tbl, selectedActiveOrder),
                            onTransferTable: (tbl) => _showTransferTableDialog(tbl, tables),
                            onReleaseTable: _releaseTable,
                            onDirectPayment: () {
                              if (selectedTable != null) {
                                _openPayment(selectedTable, selectedActiveOrder);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Floating Mobile Selection Bar
                bottomSheet: (!isWide && selectedTable != null)
                    ? TableMobileBottomBar(
                        table: selectedTable,
                        activeOrder: selectedActiveOrder,
                        onTapDetails: () => _showMobileTableDetailSheet(selectedTable, selectedActiveOrder, isLoadingActiveOrder, tables),
                        onPayment: () => _openPayment(selectedTable, selectedActiveOrder),
                        onOpenPos: widget.onOpenTable != null ? () => widget.onOpenTable!(selectedTable) : null,
                        onClose: () => _cubit.selectTable(null),
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
