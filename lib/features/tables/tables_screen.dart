// features/tables/tables_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/design/tokens.dart';
import '../../core/storage/session_storage.dart';
import '../fnb/fnb_payment_split_screen.dart';
import '../shared_pos/pos_checkout_service.dart';
import '../shared_pos/receipt_printer_service.dart';
import '../shared_pos/shift_service.dart';
import 'table_grid_tile.dart';
import 'table_service.dart';
import 'widgets/table_add_dialog.dart';
import 'widgets/table_detail_pane.dart';
import 'widgets/table_filter_ribbon.dart';
import 'widgets/table_mobile_bottom_bar.dart';
import 'widgets/table_transfer_dialog.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key, this.onOpenTable});

  final void Function(CafeTableInfo table)? onOpenTable;

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  static const _pollInterval = Duration(seconds: 15);

  List<CafeTableInfo>? _tables;
  String? _error;
  String _selectedFilter = 'all'; // 'all', 'available', 'occupied', 'reserved'
  CafeTableInfo? _selectedTable;
  ActiveTableOrder? _selectedActiveOrder;
  bool _isLoadingActiveOrder = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(_pollInterval, (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _error = null);
    try {
      final list = await TableService.instance.tables();
      if (mounted) {
        setState(() {
          _tables = list;
          // Sync selection if current selected table still exists
          if (_selectedTable != null) {
            final refreshed = list.where((t) => t.id == _selectedTable!.id).firstOrNull;
            if (refreshed != null) {
              _selectedTable = refreshed;
              _fetchActiveOrderFor(refreshed);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat denah meja: $e';
        });
      }
    }
  }

  Future<void> _fetchActiveOrderFor(CafeTableInfo t) async {
    if (t.status == TableStatus.available) {
      setState(() {
        _selectedActiveOrder = null;
        _isLoadingActiveOrder = false;
      });
      return;
    }
    setState(() => _isLoadingActiveOrder = true);
    final order = await TableService.instance.getActiveOrder(t.id);
    if (mounted && _selectedTable?.id == t.id) {
      setState(() {
        _selectedActiveOrder = order;
        _isLoadingActiveOrder = false;
      });
    }
  }

  void _selectTable(CafeTableInfo t) {
    setState(() => _selectedTable = t);
    _fetchActiveOrderFor(t);
  }

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: WarmPalette.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

  void _openPayment() {
    final t = _selectedTable;
    if (t == null) return;
    final act = _selectedActiveOrder;
    final total = act?.totalAmount.round() ?? t.order?.total.round() ?? 0;
    final orderId = act?.id ?? t.order?.id;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FnbPaymentSplitScreen(
          orderId: orderId,
          tableId: t.id,
          tableNumber: t.name,
          totalAmount: total,
          shiftId: ShiftService.instance.currentStatus?.shiftId,
          customerName: act?.customerName,
          onPaymentComplete: () {
            _toast('${t.name} pembayaran selesai');
            _load();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<void> _printBill(CafeTableInfo t) async {
    final act = _selectedActiveOrder;
    final total = act?.totalAmount ?? t.order?.total ?? 0;
    final items = act?.items ?? [];

    final receiptData = ReceiptData(
      storeName: SessionStorage.instance.getLocationName() ?? 'Velora Cafe',
      storeAddress: 'Denah & Meja Kasir',
      storePhone: '',
      invoiceNumber: 'BILL-${t.name}',
      cashierName: SessionStorage.instance.getUserName() ?? 'Kasir',
      tableOrPatient: t.name,
      timestamp: DateTime.now(),
      items: items.map((it) => PosCartItem(
        productId: it.productId,
        name: it.modifierNames.isNotEmpty ? '${it.name} (${it.modifierNames.join(", ")})' : it.name,
        price: it.price,
        quantity: it.quantity,
      )).toList(),
      subtotal: total,
      tax: 0,
      grandTotal: total,
      paidAmount: 0,
      changeAmount: 0,
      paymentMethod: 'BILL SEMENTARA',
    );

    try {
      await ReceiptPrinterService.instance.printReceipt(receiptData);
      _toast('✓ Bill ${t.name} berhasil dicetak');
    } catch (e) {
      _toast('Cetak bill: $e');
    }
  }

  Future<void> _releaseTable(CafeTableInfo t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: WarmPalette.danger),
            const SizedBox(width: 8),
            Text('Kosongkan ${t.name}?', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Status meja akan diubah menjadi Kosong / Siap Digunakan dan pesanan aktif di meja ini akan diselesaikan.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: WarmPalette.danger,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            child: const Text('Kosongkan Meja'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await TableService.instance.release(t.id);
      _toast('✓ ${t.name} berhasil dikosongkan');
      _load();
      if (mounted) {
        setState(() {
          _selectedTable = null;
          _selectedActiveOrder = null;
        });
      }
    } catch (e) {
      _toast('Gagal mengosongkan meja: $e');
    }
  }

  Future<void> _showTransferTableDialog(CafeTableInfo fromTable) async {
    final availableTables = (_tables ?? [])
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
        _load();
      },
    );
  }

  void _showAddTableDialog() {
    showAddTableDialog(
      context,
      onTableAdded: (name) {
        if (mounted) {
          _toast('✓ $name berhasil ditambahkan');
          _load();
        }
      },
      onError: (msg) {
        if (mounted) _toast(msg);
      },
    );
  }

  Future<void> _seedDefaultTables() async {
    _toast('Sedang membuat meja standar (01 s/d 08)...');
    try {
      await TableService.instance.seedDefaultTables();
      _toast('✓ Meja standar berhasil dibuat');
      _load();
    } catch (e) {
      _toast('Gagal membuat meja: $e');
    }
  }

  void _showMobileTableDetailSheet(CafeTableInfo t) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.88,
        child: TableDetailPane(
          table: _selectedTable,
          activeOrder: _selectedActiveOrder,
          isLoadingActiveOrder: _isLoadingActiveOrder,
          isModal: true,
          onClose: () => Navigator.pop(sheetContext),
          onOpenPos: (table) {
            Navigator.pop(sheetContext);
            widget.onOpenTable?.call(table);
          },
          onPrintBill: _printBill,
          onTransferTable: _showTransferTableDialog,
          onReleaseTable: _releaseTable,
          onDirectPayment: () {
            Navigator.pop(sheetContext);
            _openPayment();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tables = _tables ?? [];
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 640;

        return Scaffold(
          backgroundColor: WarmPalette.canvas,
          appBar: (!isWide || canPop)
              ? AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  titleSpacing: 14,
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: WarmPalette.primary,
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
                                const Text(
                                  'Denah Meja',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: WarmPalette.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: WarmPalette.tertiary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'LIVE',
                                    style: TextStyle(
                                      color: WarmPalette.tertiary,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${SessionStorage.instance.getLocationName() ?? "Outlet Utama"} • Status Terkini',
                              style: const TextStyle(fontSize: 11, color: WarmPalette.textSecondary),
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
                      icon: const Icon(Icons.refresh_rounded, color: WarmPalette.textPrimary),
                      onPressed: () => _load(),
                    ),
                    IconButton(
                      tooltip: 'Tambah Meja',
                      icon: const Icon(Icons.add_circle_outline_rounded, color: WarmPalette.primary),
                      onPressed: _showAddTableDialog,
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: WarmPalette.textPrimary),
                      onSelected: (val) {
                        if (val == 'seed') _seedDefaultTables();
                        if (val == 'reservation') _toast('Formulir reservasi baru dibuka');
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'seed',
                          child: Row(
                            children: [
                              Icon(Icons.auto_awesome_rounded, size: 18, color: WarmPalette.primary),
                              SizedBox(width: 8),
                              Text('Buat Meja Standar (01-08)'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'reservation',
                          child: Row(
                            children: [
                              Icon(Icons.bookmark_add_outlined, size: 18, color: WarmPalette.tertiary),
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
                child: Builder(
                  builder: (ctx) {
                    final allTables = tables;
                    final availableCount = allTables.where((t) => t.status == TableStatus.available).length;
                    final occupiedCount = allTables.where((t) => t.status == TableStatus.occupied || t.status == TableStatus.ordered).length;
                    final reservedCount = allTables.where((t) => t.status == TableStatus.reserved).length;

                    final filteredTables = allTables.where((t) {
                      if (_selectedFilter == 'available') return t.status == TableStatus.available;
                      if (_selectedFilter == 'occupied') return t.status == TableStatus.occupied || t.status == TableStatus.ordered;
                      if (_selectedFilter == 'reserved') return t.status == TableStatus.reserved;
                      return true;
                    }).toList();

                    return ListView(
                      padding: EdgeInsets.fromLTRB(
                        isWide ? 16 : 12,
                        isWide ? 16 : 10,
                        isWide ? 16 : 12,
                        (!isWide && _selectedTable != null) ? 80 : 20,
                      ),
                      children: [
                        if (_error != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: WarmPalette.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: WarmPalette.danger.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: WarmPalette.danger, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: WarmPalette.danger,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _load(),
                                  child: const Text('Coba Lagi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ),
                        if (isWide) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Manajemen Meja & Denah Ruangan',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: WarmPalette.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: WarmPalette.tertiary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'LIVE FLOOR',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: WarmPalette.tertiary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${SessionStorage.instance.getLocationName() ?? "Outlet"} • Live Table Occupancy & Orders',
                                    style: const TextStyle(fontSize: 11, color: WarmPalette.textSecondary),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _showAddTableDialog,
                                    icon: const Icon(Icons.add_rounded, size: 16),
                                    label: const Text('Tambah Meja', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: WarmPalette.textPrimary,
                                      side: const BorderSide(color: WarmPalette.line),
                                      shape: const StadiumBorder(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _toast('Formulir reservasi baru dibuka'),
                                    icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                                    label: const Text('Reservasi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: WarmPalette.primary,
                                      foregroundColor: Colors.white,
                                      shape: const StadiumBorder(),
                                      elevation: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Dynamic Unified Filter Ribbon & Occupancy Pill
                        TableFilterRibbon(
                          selectedFilter: _selectedFilter,
                          onFilterSelected: (val) => setState(() => _selectedFilter = val),
                          allCount: allTables.length,
                          availableCount: availableCount,
                          occupiedCount: occupiedCount,
                          reservedCount: reservedCount,
                        ),
                        const SizedBox(height: 14),

                        // Tables Grid or Empty State
                        if (allTables.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: WarmPalette.line),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    color: WarmPalette.surfaceMuted,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.table_restaurant_outlined,
                                    size: 40,
                                    color: WarmPalette.primary,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Belum Ada Meja Terdaftar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: WarmPalette.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Kelola denah meja untuk pesanan makan di tempat (Dine-In). Anda dapat membuat meja otomatis atau menambahkannya manual.',
                                  style: TextStyle(fontSize: 12, color: WarmPalette.textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 18),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _seedDefaultTables,
                                      icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                                      label: const Text('Buat Meja Standar (01-08)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: WarmPalette.primary,
                                        foregroundColor: Colors.white,
                                        shape: const StadiumBorder(),
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: _showAddTableDialog,
                                      icon: const Icon(Icons.add_rounded, size: 16),
                                      label: const Text('+ Tambah Meja Manual', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: WarmPalette.textPrimary,
                                        side: const BorderSide(color: WarmPalette.line),
                                        shape: const StadiumBorder(),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        else if (filteredTables.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: WarmPalette.line),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.filter_list_off_rounded, size: 36, color: WarmPalette.textSecondary),
                                const SizedBox(height: 10),
                                const Text('Tidak Ada Meja', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                const SizedBox(height: 4),
                                const Text('Tidak ada meja yang sesuai dengan filter yang dipilih.', style: TextStyle(fontSize: 12, color: WarmPalette.textSecondary)),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () => setState(() => _selectedFilter = 'all'),
                                  child: const Text('Tampilkan Semua Meja'),
                                ),
                              ],
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredTables.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isWide ? (constraints.maxWidth > 900 ? 3 : 2) : 2,
                              childAspectRatio: isWide ? 1.35 : 1.16,
                              crossAxisSpacing: isWide ? 14 : 10,
                              mainAxisSpacing: isWide ? 14 : 10,
                            ),
                            itemBuilder: (ctx, i) {
                              final t = filteredTables[i];
                              return TableGridTile(
                                table: t,
                                isSelected: _selectedTable?.id == t.id,
                                onSelect: () => _selectTable(t),
                                onOpenTable: widget.onOpenTable,
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),
              ),

              // Right Side Panel: Detail Meja Aktif (Desktop/Tablet)
              if (isWide) ...[
                const VerticalDivider(width: 1, color: WarmPalette.line),
                Expanded(
                  flex: 4,
                  child: Container(
                    color: Colors.white,
                    child: TableDetailPane(
                      table: _selectedTable,
                      activeOrder: _selectedActiveOrder,
                      isLoadingActiveOrder: _isLoadingActiveOrder,
                      isModal: false,
                      onClose: () => setState(() {
                        _selectedTable = null;
                        _selectedActiveOrder = null;
                      }),
                      onOpenPos: (table) => widget.onOpenTable?.call(table),
                      onPrintBill: _printBill,
                      onTransferTable: _showTransferTableDialog,
                      onReleaseTable: _releaseTable,
                      onDirectPayment: _openPayment,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Floating Mobile Selection Bar
          bottomSheet: (!isWide && _selectedTable != null)
              ? TableMobileBottomBar(
                  table: _selectedTable!,
                  activeOrder: _selectedActiveOrder,
                  onTapDetails: () => _showMobileTableDetailSheet(_selectedTable!),
                  onPayment: _openPayment,
                  onOpenPos: widget.onOpenTable != null ? () => widget.onOpenTable!(_selectedTable!) : null,
                  onClose: () => setState(() {
                    _selectedTable = null;
                    _selectedActiveOrder = null;
                  }),
                )
              : null,
        );
      },
    );
  }
}
