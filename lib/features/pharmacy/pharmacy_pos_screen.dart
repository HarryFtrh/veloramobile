import 'package:flutter/material.dart';
import '../../core/config/app_theme.dart';
import '../../core/design/tokens.dart';
import '../../core/utils/audio_helper.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/storage/session_storage.dart';
import '../shared_pos/product_catalog_service.dart';
import '../shared_pos/pos_checkout_service.dart';
import '../shared_pos/shift_service.dart';
import '../shared_pos/shift_modal.dart';
import '../shared_pos/shift_badge.dart';
import '../shared_pos/universal_checkout_dialog.dart';
import '../shared_pos/sales_history_drawer.dart';
import '../shared_pos/printer_settings_modal.dart';
import 'pharmacy_patient_dialog.dart';
import 'pharmacy_drug_card.dart';
import 'pharmacy_cart_panel.dart';

class PharmacyPosScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const PharmacyPosScreen({super.key, this.onLogout});

  @override
  State<PharmacyPosScreen> createState() => _PharmacyPosScreenState();
}

class _PharmacyPosScreenState extends State<PharmacyPosScreen> {
  int _selectedCategoryIndex = 0;
  final Map<String, int> _cart = {};
  num _totalPrice = 0;
  String _searchQuery = '';
  String _selectedPatient = 'Pasien Umum / Walk-in';
  String _selectedDoctor = 'dr. Resep Luar (Umum)';
  bool _isLoadingCatalog = false;
  String? _syncError;
  bool _isGridView = true;

  final List<String> _categories = ['Semua Obat'];
  final List<Map<String, dynamic>> _drugItems = [];

  static const num _tuslahFee = 2500;

  @override
  void initState() {
    super.initState();
    _fetchCatalog();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkShiftStatus();
    });
  }

  Future<void> _checkShiftStatus() async {
    try {
      final status = await ShiftService.instance.getShiftStatus();
      if (!status.isOpen && mounted) {
        ShiftDialogs.showOpenShiftDialog(
          context,
          onOpened: (_) => setState(() {}),
        );
      }
    } catch (_) {}
  }

  Future<void> _fetchCatalog() async {
    setState(() => _isLoadingCatalog = true);
    try {
      final catalog = await ProductCatalogService.instance.fetchCatalog();
      if (mounted) {
        setState(() {
          _categories.clear();
          _categories.addAll(catalog.categories);
          _drugItems.clear();
          _drugItems.addAll(catalog.products.map((p) => {
            'id': p.id,
            'name': p.name,
            'sku': p.sku.isNotEmpty ? p.sku : (p.barcode.isNotEmpty ? p.barcode : '-'),
            'category': p.category,
            'price': p.price,
            'isDotRed': p.isPrescriptionOnly,
            'batch': p.batches.isNotEmpty ? p.batches.first.batchNumber : '-',
            'ed': p.batches.isNotEmpty ? p.batches.first.expiryDate : '-',
            'stock': p.stock.toInt(),
          }));
          _isLoadingCatalog = false;
          _syncError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCatalog = false;
          _syncError = 'Gagal Sinkronisasi';
        });
      }
    }
  }

  Future<void> _syncOfflineQueue() async {
    AudioHelper.tapFeedback();
    final count = PosCheckoutService.instance.pendingOfflineCount;
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada antrean transaksi offline.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Menyinkronkan $count transaksi offline ke server...')),
    );

    final res = await PosCheckoutService.instance.syncOfflineQueue();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil sinkron: ${res['synced']} transaksi. Tersisa: ${res['remaining']}'),
          backgroundColor: res['remaining'] == 0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
        ),
      );
    }
  }

  void _changePatientDialog() {
    AudioHelper.tapFeedback();
    PharmacyPatientDialog.show(
      context: context,
      initialPatient: _selectedPatient,
      initialDoctor: _selectedDoctor,
      onSave: (data) {
        setState(() {
          _selectedPatient = data.patient;
          _selectedDoctor = data.doctor;
        });
      },
    );
  }

  void _addToCart(String id) {
    AudioHelper.tapFeedback();
    setState(() {
      _cart[id] = (_cart[id] ?? 0) + 1;
      _calculateTotal();
    });
  }

  void _removeFromCart(String id) {
    AudioHelper.tapFeedback();
    setState(() {
      final current = _cart[id] ?? 0;
      if (current <= 1) {
        _cart.remove(id);
      } else {
        _cart[id] = current - 1;
      }
      _calculateTotal();
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      _totalPrice = 0;
    });
  }

  void _calculateTotal() {
    num total = 0;
    _cart.forEach((id, qty) {
      final item = _drugItems.firstWhere(
        (e) => e['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      final price = item['price'] as num? ?? 0;
      total += price * qty;
    });
    setState(() {
      _totalPrice = total;
    });
  }

  void _showCheckoutDialog() {
    final grandTotal = _totalPrice + (_totalPrice > 0 ? _tuslahFee : 0);
    final cartItems = _cart.entries.map((e) {
      final item = _drugItems.firstWhere((m) => m['id'] == e.key);
      return PosCartItem(
        productId: e.key,
        name: item['name'] as String,
        price: item['price'] as num,
        quantity: e.value,
        batchNumber: item['batch'] as String?,
        expiryDate: (item['ed'] ?? item['exp']) as String?,
      );
    }).toList();

    UniversalCheckoutDialog.show(
      context,
      items: cartItems,
      subtotal: _totalPrice,
      tax: 0,
      grandTotal: grandTotal,
      storeName: SessionStorage.instance.getTenantName() ?? SessionStorage.instance.getLocationName() ?? '',
      storeAddress: SessionStorage.instance.getStoreAddress() ?? (SessionStorage.instance.getLocationName() ?? ''),
      storePhone: SessionStorage.instance.getStorePhone() ?? '-',
      cashierName: SessionStorage.instance.getUserName() ?? 'Apoteker',
      tableOrCustomer: _selectedPatient,
      accentColor: const Color(0xFF10B981),
      onCompleted: (result) {
        SalesHistoryDrawer.addRecord(
          CompletedSaleRecord(
            invoiceNumber: result.invoiceNumber,
            time: DateTime.now(),
            total: grandTotal,
            paymentMethod: 'TUNAI/QRIS',
            tableOrCustomer: _selectedPatient,
            items: cartItems,
          ),
        );

        final msg = result.isOffline
            ? 'Resep tersimpan offline (#${result.invoiceNumber}).'
            : '✓ Resep Selesai! #${result.invoiceNumber} • Struk Tercetak & Stok Batch Terpotong (FEFO).';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: result.isOffline ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
            duration: const Duration(seconds: 4),
          ),
        );

        setState(() {
          _cart.clear();
          _totalPrice = 0;
        });
      },
    );
  }

  void _openMobileCartSheet() {
    AudioHelper.tapFeedback();
    final isMobile = context.isMobile;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 540),
        child: DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, scrollController) => Container(
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: PharmacyCartPanel(
            cart: _cart,
            drugItems: _drugItems,
            totalPrice: _totalPrice,
            tuslahFee: _tuslahFee,
            selectedPatient: _selectedPatient,
            selectedDoctor: _selectedDoctor,
            onChangePatient: () {
              Navigator.pop(ctx);
              _changePatientDialog();
            },
            onClearCart: () {
              _clearCart();
              Navigator.pop(ctx);
            },
            onAddToCart: _addToCart,
            onRemoveFromCart: _removeFromCart,
            onCheckout: () {
              Navigator.pop(ctx);
              _showCheckoutDialog();
            },
            onClose: () => Navigator.pop(ctx),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildMobileCartBar() {
    final totalItems = _cart.values.fold<int>(0, (sum, q) => sum + q);
    final grandTotal = _totalPrice + (_totalPrice > 0 ? _tuslahFee : 0);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: const Border(top: BorderSide(color: AppTheme.border, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Badge(
                label: Text('$totalItems'),
                child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedPatient,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    CurrencyFormatter.format(grandTotal),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF10B981)),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _openMobileCartSheet,
              icon: const Icon(Icons.shopping_bag_outlined, size: 16),
              label: const Text('Lihat Resep', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.fromLTRB(isMobile ? 12 : 20, isMobile ? 12 : 20, isMobile ? 12 : 20, 12),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Row(
        children: [
          if (!isMobile) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    SessionStorage.instance.getLocationName() ?? 'Apotek Utama',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: isMobile ? 'Cari nama obat, SKU...' : 'Scan barcode atau cari nama obat, kandungan, SKU...',
                  prefixIcon: const Icon(Icons.qr_code_scanner_rounded, size: 18, color: Color(0xFF10B981)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              _isGridView ? Icons.grid_view_rounded : Icons.view_list_rounded,
              size: 18,
              color: const Color(0xFF10B981),
            ),
            tooltip: _isGridView ? 'Beralih ke Tampilan Baris List' : 'Beralih ke Tampilan Grid Cards',
            onPressed: () {
              AudioHelper.tapFeedback();
              setState(() => _isGridView = !_isGridView);
            },
          ),
          if (isMobile) ...[
            if (_cart.isNotEmpty)
              IconButton(
                icon: Badge(
                  label: Text('${_cart.values.fold<int>(0, (s, q) => s + q)}'),
                  child: const Icon(Icons.shopping_bag_outlined, size: 20, color: Color(0xFF10B981)),
                ),
                tooltip: 'Buka Keranjang Resep',
                onPressed: _openMobileCartSheet,
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppTheme.textSecondary),
              tooltip: 'Menu Kasir',
              onSelected: (val) {
                AudioHelper.tapFeedback();
                switch (val) {
                  case 'sync':
                    if (!_isLoadingCatalog) _fetchCatalog();
                    break;
                  case 'history':
                    SalesHistoryDrawer.show(
                      context,
                      storeName: SessionStorage.instance.getTenantName() ?? SessionStorage.instance.getLocationName() ?? '',
                      storeAddress: SessionStorage.instance.getStoreAddress() ?? (SessionStorage.instance.getLocationName() ?? ''),
                      storePhone: SessionStorage.instance.getStorePhone() ?? '-',
                      cashierName: SessionStorage.instance.getUserName() ?? 'Apoteker',
                      accentColor: const Color(0xFF10B981),
                    );
                    break;
                  case 'printer':
                    PrinterSettingsModal.show(context);
                    break;
                  case 'offline':
                    _syncOfflineQueue();
                    break;
                  case 'logout':
                    widget.onLogout?.call();
                    break;
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'sync',
                  child: Row(
                    children: [
                      Icon(Icons.sync_rounded, size: 18, color: _isLoadingCatalog ? Colors.grey : const Color(0xFF10B981)),
                      const SizedBox(width: 10),
                      const Text('Sinkronkan Katalog'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'history',
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 18, color: AppTheme.textSecondary),
                      SizedBox(width: 10),
                      Text('Riwayat Transaksi'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'printer',
                  child: Row(
                    children: [
                      Icon(Icons.print_outlined, size: 18, color: AppTheme.textSecondary),
                      SizedBox(width: 10),
                      Text('Pengaturan Printer'),
                    ],
                  ),
                ),
                if (PosCheckoutService.instance.pendingOfflineCount > 0)
                  PopupMenuItem(
                    value: 'offline',
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_upload_outlined, size: 18, color: Color(0xFF10B981)),
                        const SizedBox(width: 10),
                        Text('Sync Offline (${PosCheckoutService.instance.pendingOfflineCount})'),
                      ],
                    ),
                  ),
                if (widget.onLogout != null)
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
                        SizedBox(width: 10),
                        Text('Keluar Kasir', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
              ],
            ),
          ] else ...[
            IconButton(
              icon: _isLoadingCatalog
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                    )
                  : const Icon(Icons.sync_rounded, size: 18, color: AppTheme.textSecondary),
              tooltip: 'Sinkronkan Katalog Obat',
              onPressed: _isLoadingCatalog ? null : _fetchCatalog,
            ),
            if (_syncError != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 12, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      _syncError!,
                      style: const TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(width: 8),
            const CashierShiftBadge(),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.receipt_long_rounded, size: 18, color: AppTheme.textSecondary),
              tooltip: 'Riwayat Transaksi & Void',
              onPressed: () {
                AudioHelper.tapFeedback();
                SalesHistoryDrawer.show(
                  context,
                  storeName: SessionStorage.instance.getTenantName() ?? SessionStorage.instance.getLocationName() ?? '',
                  storeAddress: SessionStorage.instance.getStoreAddress() ?? (SessionStorage.instance.getLocationName() ?? ''),
                  storePhone: SessionStorage.instance.getStorePhone() ?? '-',
                  cashierName: SessionStorage.instance.getUserName() ?? 'Apoteker',
                  accentColor: const Color(0xFF10B981),
                );
              },
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.print_outlined, size: 18, color: AppTheme.textSecondary),
              tooltip: 'Pengaturan Printer & Cash Drawer',
              onPressed: () {
                AudioHelper.tapFeedback();
                PrinterSettingsModal.show(context);
              },
            ),
            if (PosCheckoutService.instance.pendingOfflineCount > 0) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: Badge(
                  label: Text('${PosCheckoutService.instance.pendingOfflineCount}'),
                  child: const Icon(Icons.cloud_upload_outlined, size: 18, color: Color(0xFF10B981)),
                ),
                tooltip: 'Sinkronkan Antrean Offline ke Server',
                onPressed: _syncOfflineQueue,
              ),
            ],
            if (widget.onLogout != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.logout_rounded, size: 18, color: AppTheme.textSecondary),
                tooltip: 'Keluar Kasir',
                onPressed: () {
                  AudioHelper.tapFeedback();
                  widget.onLogout!();
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    final filteredItems = _drugItems.where((item) {
      final matchesCategory = _selectedCategoryIndex == 0 ||
          item['category'] == _categories[_selectedCategoryIndex];
      final matchesSearch = _searchQuery.isEmpty ||
          item['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['sku'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    final catalogPane = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopBar(isMobile),
        // Pill Category Chips
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (context, idx) {
              final isSelected = idx == _selectedCategoryIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    AudioHelper.tapFeedback();
                    setState(() => _selectedCategoryIndex = idx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF10B981) : AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF10B981) : AppTheme.border,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _categories[idx],
                        style: TextStyle(
                          color: isSelected ? Colors.black : AppTheme.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Drug List
        Expanded(
          child: _isLoadingCatalog
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF10B981)),
                      SizedBox(height: 16),
                      Text(
                        'Menghubungkan ke Database Velora...',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medication_liquid_outlined, size: 48, color: Colors.grey.shade800),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Tidak ada obat yang cocok dengan "$_searchQuery"'
                                : 'Katalog Obat Belum Terisi',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _fetchCatalog,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Sinkronkan Katalog Obat'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF10B981),
                              side: const BorderSide(color: Color(0xFF10B981)),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _isGridView
                      ? GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            childAspectRatio: 0.84,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final qty = _cart[item['id']] ?? 0;
                            return PharmacyDrugCard(
                              item: item,
                              quantity: qty,
                              onAdd: () => _addToCart(item['id']),
                            );
                          },
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredItems.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final qty = _cart[item['id']] ?? 0;
                            return PharmacyDrugRow(
                              item: item,
                              quantity: qty,
                              onAdd: () => _addToCart(item['id']),
                            );
                          },
                        ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      resizeToAvoidBottomInset: false,
      body: isWide
          ? Row(
              children: [
                Expanded(
                  flex: 65,
                  child: catalogPane,
                ),
                Container(
                  width: 1,
                  color: AppTheme.border,
                ),
                Expanded(
                  flex: 35,
                  child: PharmacyCartPanel(
                    cart: _cart,
                    drugItems: _drugItems,
                    totalPrice: _totalPrice,
                    tuslahFee: _tuslahFee,
                    selectedPatient: _selectedPatient,
                    selectedDoctor: _selectedDoctor,
                    onChangePatient: _changePatientDialog,
                    onClearCart: _clearCart,
                    onAddToCart: _addToCart,
                    onRemoveFromCart: _removeFromCart,
                    onCheckout: _showCheckoutDialog,
                  ),
                ),
              ],
            )
          : catalogPane,
      bottomNavigationBar: !isWide && _cart.isNotEmpty ? _buildMobileCartBar() : null,
    );
  }
}


