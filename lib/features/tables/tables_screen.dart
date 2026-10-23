// features/tables/tables_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/design/tokens.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/safe_json.dart';
import '../fnb/fnb_payment_split_screen.dart';
import '../shared_pos/pos_checkout_service.dart';
import '../shared_pos/receipt_printer_service.dart';
import 'table_grid_tile.dart';
import 'table_service.dart';

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

  Color _statusColor(TableStatus s) {
    return switch (s) {
      TableStatus.available => WarmPalette.tertiary,
      TableStatus.ordered => WarmPalette.primary,
      TableStatus.occupied => WarmPalette.secondary,
      TableStatus.reserved => const Color(0xFF6A4C93),
    };
  }

  String _statusLabel(TableStatus s) {
    return switch (s) {
      TableStatus.available => 'Kosong',
      TableStatus.ordered => 'Terisi',
      TableStatus.occupied => 'Bill',
      TableStatus.reserved => 'Booking',
    };
  }

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

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pindah ${fromTable.name} ke Meja Lain', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 4),
              const Text('Pilih meja kosong tujuan perpindahan pelanggan:', style: TextStyle(fontSize: 12, color: WarmPalette.textSecondary)),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: availableTables.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, color: WarmPalette.line),
                  itemBuilder: (_, i) {
                    final target = availableTables[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: WarmPalette.tertiary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.table_restaurant_rounded, color: WarmPalette.tertiary, size: 20),
                      ),
                      title: Text(target.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: Text('Kapasitas ${target.capacity} Kursi • Kosong', style: const TextStyle(fontSize: 11, color: WarmPalette.textSecondary)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: WarmPalette.textSecondary),
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _toast('✓ Meja ${fromTable.name} berhasil dipindah ke ${target.name}');
                        _load();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTableDialog() {
    final nameCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '4');
    String position = 'indoor';
    bool busy = false;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: const Row(
            children: [
              Icon(Icons.table_restaurant_rounded, color: WarmPalette.primary),
              SizedBox(width: 8),
              Text('Tambah Meja Baru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nama Meja',
                  hintText: 'Contoh: Meja 09, VIP 1',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: capacityCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Kapasitas (Kursi / Pax)',
                  hintText: '4',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: position,
                decoration: InputDecoration(
                  labelText: 'Posisi Ruangan',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 'indoor', child: Text('Indoor / Ruang Utama')),
                  DropdownMenuItem(value: 'outdoor', child: Text('Outdoor / Teras')),
                  DropdownMenuItem(value: 'smoking', child: Text('Smoking Area')),
                  DropdownMenuItem(value: 'vip', child: Text('Ruang VIP / Meeting')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => position = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: busy
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final cap = int.tryParse(capacityCtrl.text.trim()) ?? 4;
                      if (name.isEmpty) {
                        _toast('Nama meja tidak boleh kosong');
                        return;
                      }
                      setDialogState(() => busy = true);
                      try {
                        await TableService.instance.createTable(
                          name: name,
                          capacity: cap,
                          position: position,
                        );
                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                        }
                        if (mounted) {
                          _toast('✓ $name berhasil ditambahkan');
                          _load();
                        }
                      } catch (e) {
                        setDialogState(() => busy = false);
                        _toast('Gagal menambah meja: $e');
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: WarmPalette.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              child: busy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Simpan Meja'),
            ),
          ],
        ),
      ),
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
        child: _buildTableDetailContent(isModal: true),
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
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildFilterTab(
                                'all',
                                'Semua',
                                allTables.length,
                                Icons.grid_view_rounded,
                                null,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterTab(
                                'available',
                                'Kosong',
                                availableCount,
                                Icons.check_circle_outline_rounded,
                                WarmPalette.tertiary,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterTab(
                                'occupied',
                                'Terisi',
                                occupiedCount,
                                Icons.restaurant_rounded,
                                WarmPalette.primary,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterTab(
                                'reserved',
                                'Booking',
                                reservedCount,
                                Icons.bookmark_outline_rounded,
                                const Color(0xFF6A4C93),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: WarmPalette.line),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.pie_chart_rounded,
                                      size: 13,
                                      color: WarmPalette.secondary,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      allTables.isEmpty
                                          ? '0 Meja'
                                          : '${((occupiedCount / allTables.length) * 100).round()}% Terpakai',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: WarmPalette.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                    child: _buildTableDetailContent(isModal: false),
                  ),
                ),
              ],
            ],
          ),

          // Floating Mobile Selection Bar
          bottomSheet: (!isWide && _selectedTable != null)
              ? SafeArea(
                  top: false,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: WarmPalette.line),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showMobileTableDetailSheet(_selectedTable!),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _statusColor(_selectedTable!.status).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.table_restaurant_rounded,
                                  color: _statusColor(_selectedTable!.status),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            sanitizeDisplayName(_selectedTable!.name),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14,
                                              color: WarmPalette.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: _statusColor(_selectedTable!.status).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            _statusLabel(_selectedTable!.status),
                                            style: TextStyle(
                                              color: _statusColor(_selectedTable!.status),
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedActiveOrder != null
                                          ? 'Rp ${_selectedActiveOrder!.totalAmount.round().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")} (${_selectedActiveOrder!.items.length} item)'
                                          : (_selectedTable!.order != null
                                              ? 'Rp ${_selectedTable!.order!.total.round().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")} (${_selectedTable!.order!.itemCount} item)'
                                              : 'Kapasitas ${_selectedTable!.capacity} Kursi • Kosong'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _selectedTable!.status != TableStatus.available
                                            ? WarmPalette.primary
                                            : WarmPalette.tertiary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_selectedTable!.status != TableStatus.available)
                                FilledButton(
                                  onPressed: _openPayment,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: WarmPalette.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    visualDensity: VisualDensity.compact,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Bayar', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                                )
                              else if (widget.onOpenTable != null)
                                FilledButton(
                                  onPressed: () => widget.onOpenTable!(_selectedTable!),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: WarmPalette.tertiary,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    visualDensity: VisualDensity.compact,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Buka POS', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                                ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => setState(() {
                                  _selectedTable = null;
                                  _selectedActiveOrder = null;
                                }),
                                borderRadius: BorderRadius.circular(12),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.close_rounded, size: 18, color: WarmPalette.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildTableDetailContent({required bool isModal}) {
    final t = _selectedTable;
    if (t == null) {
      return const Center(child: Text('Pilih meja untuk melihat detail'));
    }

    final act = _selectedActiveOrder;
    final total = act?.totalAmount.round() ?? t.order?.total.round() ?? 0;
    final items = act?.items ?? [];

    return Padding(
      padding: EdgeInsets.fromLTRB(16, isModal ? 4 : 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Detail ${sanitizeDisplayName(t.name)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: WarmPalette.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: _statusColor(t.status),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _statusLabel(t.status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () {
                  if (isModal) {
                    Navigator.pop(context);
                  } else {
                    setState(() {
                      _selectedTable = null;
                      _selectedActiveOrder = null;
                    });
                  }
                },
              ),
            ],
          ),
          Text(
            'Kapasitas ${t.capacity} Kursi • ${t.status == TableStatus.available ? "Tersedia" : "Terpakai"}',
            style: const TextStyle(fontSize: 11.5, color: WarmPalette.textSecondary),
          ),
          const SizedBox(height: 12),

          // Stats cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: WarmPalette.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jumlah Tamu',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: WarmPalette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${t.capacity} Pax',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                      ),
                      Text(
                        t.order?.customerName != null && t.order!.customerName!.isNotEmpty
                            ? t.order!.customerName!
                            : 'Pelanggan Umum',
                        style: const TextStyle(fontSize: 9.5, color: WarmPalette.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: WarmPalette.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Tagihan',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: WarmPalette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rp ${total.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: WarmPalette.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${items.isNotEmpty ? items.length : (t.order?.itemCount ?? 0)} item terdaftar',
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: WarmPalette.tertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Order Items Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pesanan Aktif di Meja',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: WarmPalette.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${items.isNotEmpty ? items.length : (t.order?.itemCount ?? 0)} Item',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: WarmPalette.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Order Items List
          Expanded(
            child: _isLoadingActiveOrder
                ? const Center(child: CircularProgressIndicator())
                : items.isNotEmpty
                    ? ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (ctx, idx) {
                          final it = items[idx];
                          final sub = it.modifierNames.isNotEmpty
                              ? it.modifierNames.join(' • ')
                              : (it.notes ?? 'Standar');
                          return _buildActiveOrderItem(
                            '${it.quantity}x ${it.name}',
                            sub,
                            (it.price * it.quantity).round(),
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          t.status == TableStatus.available
                              ? 'Tidak ada pesanan aktif'
                              : 'Memuat atau pesanan belum memiliki rincian',
                          style: const TextStyle(
                            color: WarmPalette.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
          ),
          const SizedBox(height: 10),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                if (isModal) Navigator.pop(context);
                widget.onOpenTable?.call(t);
              },
              icon: const Icon(Icons.add_shopping_cart_rounded, size: 17),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Buka Menu POS (+ Tambah Menu)',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: WarmPalette.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),

          if (t.status != TableStatus.available) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _printBill(t),
                    icon: const Icon(Icons.print_outlined, size: 15),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Cetak Bill', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: WarmPalette.textPrimary,
                      side: const BorderSide(color: WarmPalette.line),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showTransferTableDialog(t),
                    icon: const Icon(Icons.sync_alt_rounded, size: 15),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Pindah Meja', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: WarmPalette.textPrimary,
                      side: const BorderSide(color: WarmPalette.line),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _releaseTable(t),
                    icon: const Icon(Icons.cleaning_services_rounded, size: 15),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Kosongkan', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: WarmPalette.danger,
                      side: const BorderSide(color: WarmPalette.danger),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (isModal) Navigator.pop(context);
                      _openPayment();
                    },
                    icon: const Icon(Icons.payments_rounded, size: 16),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Langsung Bayar', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WarmPalette.secondary,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterTab(
    String key,
    String title,
    int count,
    IconData icon,
    Color? badgeColor,
  ) {
    final isSel = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
        decoration: BoxDecoration(
          color: isSel ? WarmPalette.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSel ? Colors.transparent : WarmPalette.line,
          ),
          boxShadow: isSel
              ? [
                  BoxShadow(
                    color: WarmPalette.primary.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSel ? Colors.white : (badgeColor ?? WarmPalette.textSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              '$title ($count)',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                color: isSel ? Colors.white : WarmPalette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrderItem(
    String name,
    String sub,
    int price,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: WarmPalette.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WarmPalette.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: WarmPalette.textPrimary,
                  ),
                ),
                Text(
                  sub,
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
          const SizedBox(width: 6),
          Text(
            'Rp ${price.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: WarmPalette.primary,
            ),
          ),
        ],
      ),
    );
  }
}
