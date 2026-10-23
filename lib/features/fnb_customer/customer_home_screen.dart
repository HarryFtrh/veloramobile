// features/fnb_customer/customer_home_screen.dart
import 'package:flutter/material.dart';

import '../../core/design/components.dart';
import '../../core/design/tokens.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/session_storage.dart';
import '../shared_pos/product_catalog_service.dart';
import '../tables/table_service.dart';
import 'customer_models.dart';
import 'customer_product_card.dart';
import 'customer_product_detail_sheet.dart';
import 'customer_cart_screen.dart';
import '../../core/utils/audio_helper.dart';
import '../fnb/billing.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key, this.onSwitchToStaffPos, this.onLogout});

  final VoidCallback? onSwitchToStaffPos;
  final VoidCallback? onLogout;

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  String _selectedCategory = 'Semua';
  final List<CustomerCartItem> _cart = [];
  int _navIndex = 0;
  bool _loading = true;
  String? _error;

  List<PosProduct> _allProducts = [];
  List<String> _categories = ['Semua'];
  List<CafeTableInfo> _tables = [];
  CafeTableInfo? _selectedTable;
  String _searchQuery = '';
  BillingSettings? _billing;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ProductCatalogService.instance.fetchCatalog(),
        TableService.instance.tables().catchError((_) => <CafeTableInfo>[]),
        BillingSettings.fetch().catchError((_) => const BillingSettings()),
      ]);

      final catalog = results[0] as PosCatalogData;
      final tables = results[1] as List<CafeTableInfo>;
      final billing = results[2] as BillingSettings;

      if (mounted) {
        setState(() {
          _allProducts = catalog.products;
          _categories = [
            'Semua',
            ...catalog.categories.where((c) => c != 'Semua'),
          ];
          _tables = tables;
          _billing = billing;
          if (tables.isNotEmpty) {
            _selectedTable = tables.first;
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiException.from(e).message;
          _loading = false;
        });
      }
    }
  }

  List<CustomerMenuItem> get _visibleMenuItems {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = _allProducts.where((p) {
      final inCat =
          _selectedCategory == 'Semua' || p.category == _selectedCategory;
      final inSearch =
          query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.sku.toLowerCase().contains(query);
      return inCat && inSearch;
    }).toList();

    return filtered.map((p) {
      return CustomerMenuItem(
        id: p.id,
        name: p.name,
        category: p.category,
        description:
            'Stok: ${p.stock > 0 ? p.stock.toInt() : "Habis"} • SKU: ${p.sku}',
        basePrice: p.price.toInt(),
        rating: 4.9,
        badge: p.stock <= 0 ? 'HABIS' : (p.category.toUpperCase()),
        origin: p.category.toLowerCase().contains('kopi') ? 'SPECIALTY' : null,
        imageUrl: (p.imageUrl != null && p.imageUrl!.isNotEmpty) ? p.imageUrl! : '',
      );
    }).toList();
  }

  void _openDetail(CustomerMenuItem item) {
    CustomerProductDetailSheet.show(
      context,
      product: item,
      onAddToCart: (cartItem) {
        setState(() => _cart.add(cartItem));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${cartItem.product.name} berhasil ditambahkan ke keranjang',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: WarmPalette.primary,
          ),
        );
      },
    );
  }

  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerCartScreen(
          cartItems: _cart,
          tableId: _selectedTable?.id,
          tableName: _selectedTable?.name ?? 'Meja Pemesan',
          onClearCart: () => setState(() => _cart.clear()),
          onUpdateCart: (updated) => setState(() {
            _cart
              ..clear()
              ..addAll(updated);
          }),
        ),
      ),
    );
  }

  Future<void> _pickTable() async {
    if (_tables.isEmpty) return;
    final isMobile = context.isMobile;
    final chosen = await showModalBottomSheet<CafeTableInfo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 620,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.75,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: WarmPalette.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: WarmPalette.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.table_restaurant_rounded,
                            color: WarmPalette.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pilih Meja Anda',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: WarmPalette.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Pesanan Anda akan diantar langsung ke meja ini',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: WarmPalette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: WarmPalette.textSecondary, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: WarmPalette.line),

                  // Table Grid
                  Flexible(
                    child: GridView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isMobile ? 3 : 4,
                        childAspectRatio: 0.95,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _tables.length,
                      itemBuilder: (_, i) {
                        final t = _tables[i];
                        final isSelected = _selectedTable?.id == t.id;
                        return Material(
                          color: isSelected
                              ? WarmPalette.primary.withValues(alpha: 0.08)
                              : WarmPalette.canvas,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected ? WarmPalette.primary : WarmPalette.line,
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              AudioHelper.tapFeedback();
                              Navigator.pop(ctx, t);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.table_restaurant_rounded,
                                    color: isSelected ? WarmPalette.primary : WarmPalette.textSecondary,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    t.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: isSelected ? WarmPalette.primary : WarmPalette.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${t.capacity} org',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: WarmPalette.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: WarmPalette.primary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'DIPILIH',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

    if (chosen != null) {
      setState(() => _selectedTable = chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarmPalette.canvas,
      appBar: AppBar(
        backgroundColor: WarmPalette.canvas,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: WarmPalette.textPrimary),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          SessionStorage.instance.getTenantName() ?? 'Velora Kafe',
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: WarmPalette.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          if (widget.onSwitchToStaffPos != null)
            IconButton(
              icon: const Icon(
                Icons.point_of_sale_rounded,
                color: WarmPalette.primary,
              ),
              tooltip: 'Beralih ke Layar Kasir POS',
              onPressed: widget.onSwitchToStaffPos,
            ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.shopping_bag_outlined,
                  color: WarmPalette.textPrimary,
                ),
                onPressed: _openCart,
              ),
              if (_cart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: WarmPalette.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_cart.length}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: WarmPalette.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.coffee_rounded, size: 36, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    SessionStorage.instance.getTenantName() ?? SessionStorage.instance.getLocationName() ?? 'Velora Kafe',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'Patron Customer Self-Order',
                    style: TextStyle(color: WarmPalette.surfaceMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (widget.onSwitchToStaffPos != null)
              ListTile(
                leading: const Icon(
                  Icons.storefront_rounded,
                  color: WarmPalette.primary,
                ),
                title: const Text(
                  'Buka Kasir POS & Operasional',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('Terminal — ${SessionStorage.instance.getLocationName() ?? "Outlet Utama"}'),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onSwitchToStaffPos!();
                },
              ),
            ListTile(
              leading: const Icon(Icons.refresh_rounded),
              title: const Text('Sinkronkan Menu dari Server'),
              onTap: () {
                Navigator.of(context).pop();
                _loadData();
              },
            ),
            if (widget.onLogout != null) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.red),
                title: const Text(
                  'Keluar Akun',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onLogout!();
                },
              ),
            ],
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: WarmPalette.primary),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off,
                    size: 48,
                    color: WarmPalette.danger,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WarmPalette.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Muat Ulang'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
              children: [
                // Table location & Notification bell
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickTable,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: WarmPalette.line),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 18,
                                color: Color(0xFF92400E),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Lokasi Meja',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: WarmPalette.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      _selectedTable != null
                                          ? '${SessionStorage.instance.getLocationName() ?? "Senopati, Jkt"} • ${_selectedTable!.name}'
                                          : '${SessionStorage.instance.getLocationName() ?? "Senopati, Jkt"} • Meja 04',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: WarmPalette.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: WarmPalette.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: WarmPalette.line),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_outlined,
                              color: WarmPalette.textPrimary,
                              size: 20,
                            ),
                            onPressed: _loadData,
                          ),
                          Positioned(
                            top: 10,
                            right: 12,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFFDC2626),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Search bar with dark square slider filter button
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: WarmPalette.surfaceMuted,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: WarmPalette.line),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: WarmPalette.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                onChanged: (q) => setState(() => _searchQuery = q),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: WarmPalette.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Cari kopi, pastry, atau brunch...',
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: WarmPalette.textSecondary,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C1810),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.tune_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        tooltip: 'Filter Menu',
                        onPressed: () {
                          if (_searchQuery.isNotEmpty) {
                            setState(() => _searchQuery = '');
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Hero Promo / Welcome Banner
                Builder(
                  builder: (context) {
                    final activePromos = _billing?.activePromotions ?? [];
                    final hasPromo = activePromos.isNotEmpty;
                    final promo = hasPromo ? activePromos.first : null;
                    final bannerTag = hasPromo
                        ? (promo!.code != null ? 'KODE: ${promo.code}' : 'PROMO HARI INI')
                        : 'SELAMAT DATANG';
                    final bannerTitle = hasPromo ? promo!.name : 'Pesan Langsung dari Meja';
                    final bannerSubtitle = hasPromo
                        ? (promo!.description?.isNotEmpty == true
                            ? promo.description!
                            : (promo.type == StorePromotionType.percentage
                                ? 'Diskon ${promo.value.toInt()}% untuk menu pilihan'
                                : 'Potongan Rp ${promo.value.toInt()}'))
                        : 'Pilih menu favorit Anda dan nikmati pesanan cepat tanpa antre';
                    final bannerAction = hasPromo ? 'Klaim Sekarang' : 'Pilih Menu';

                    return Container(
                      height: 168,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFF2C1810),
                            Color(0xFF5B301A),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2C1810).withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: 12,
                            top: 0,
                            bottom: 0,
                            child: Opacity(
                              opacity: 0.2,
                              child: const Icon(
                                Icons.coffee_rounded,
                                size: 140,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEA580C),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    bannerTag,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  bannerTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  bannerSubtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFE2D6CC),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    if (_visibleMenuItems.isNotEmpty) {
                                      _openDetail(_visibleMenuItems.first);
                                    }
                                  },
                                  icon: Text(
                                    bannerAction,
                                    style: const TextStyle(
                                      color: Color(0xFF2C1810),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                  label: const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: Color(0xFF2C1810),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF2C1810),
                                    elevation: 0,
                                    shape: const StadiumBorder(),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    minimumSize: Size.zero,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Categories Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kategori',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: WarmPalette.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          setState(() => _selectedCategory = 'Semua'),
                      child: const Text(
                        'Lihat Semua',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories
                        .map((c) => _buildCategoryChip(c))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Section 1: Rekomendasi Barista
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '· Rekomendasi Barista',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: WarmPalette.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Kurasi Ahli',
                        style: TextStyle(
                          color: Color(0xFF15803D),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Grid of items
                if (_visibleMenuItems.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text(
                        'Tidak ada produk pada kategori ini',
                        style: TextStyle(color: WarmPalette.textSecondary),
                      ),
                    ),
                  )
                else
                  Builder(
                    builder: (ctx) {
                      final isMobile = ctx.isMobile;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _visibleMenuItems.length,
                        gridDelegate: isMobile
                            ? const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.68,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              )
                            : const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 240,
                                mainAxisExtent: 252,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                        itemBuilder: (ctx, i) {
                          final item = _visibleMenuItems[i];
                          return CustomerProductCard(
                            item: item,
                            onTap: () => _openDetail(item),
                          );
                        },
                      );
                    },
                  ),

                // Section 2: Menu Terpopuler (when all products available)
                if (_allProducts.length > 2) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Menu Terpopuler',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: WarmPalette.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _selectedCategory = 'Semua'),
                        child: const Text(
                          'Semua',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 84,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _allProducts.length,
                      itemBuilder: (ctx, i) {
                        final p = _allProducts[i];
                        final mItem = CustomerMenuItem(
                          id: p.id,
                          name: p.name,
                          category: p.category,
                          description: 'Stok: ${p.stock > 0 ? p.stock.toInt() : "Habis"} • SKU: ${p.sku}',
                          basePrice: p.price.toInt(),
                          rating: 4.9,
                          imageUrl: p.imageUrl ?? '',
                        );
                        return _buildPopularItemTile(mItem);
                      },
                    ),
                  ),
                ],
              ],
            ),
      bottomNavigationBar: FloatingPillNavBar(
        currentIndex: _navIndex,
        onTap: (idx) {
          setState(() => _navIndex = idx);
          if (idx == 1) {
            setState(() => _selectedCategory = 'Semua');
          } else if (idx == 2) {
            _openCart();
          } else if (idx == 3) {
            Scaffold.of(context).openDrawer();
          }
        },
        items: const [
          FloatingPillNavItem(
            icon: Icons.coffee_outlined,
            activeIcon: Icons.coffee_rounded,
            label: 'Discover',
          ),
          FloatingPillNavItem(
            icon: Icons.restaurant_menu_outlined,
            activeIcon: Icons.restaurant_menu_rounded,
            label: 'Menu',
          ),
          FloatingPillNavItem(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long_rounded,
            label: 'Orders',
          ),
          FloatingPillNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('semua') || lower.contains('all')) return Icons.restaurant_rounded;
    if (lower.contains('kopi') || lower.contains('coffee') || lower.contains('signature') || lower.contains('espresso')) return Icons.coffee_rounded;
    if (lower.contains('cold') || lower.contains('es') || lower.contains('ice') || lower.contains('brew')) return Icons.ac_unit_rounded;
    if (lower.contains('pastry') || lower.contains('bakery') || lower.contains('roti') || lower.contains('cake')) return Icons.bakery_dining_rounded;
    if (lower.contains('snack') || lower.contains('cemilan') || lower.contains('bite')) return Icons.cookie_rounded;
    if (lower.contains('tea') || lower.contains('teh')) return Icons.emoji_food_beverage_rounded;
    return Icons.local_dining_rounded;
  }

  Widget _buildCategoryChip(String title) {
    final isSel = _selectedCategory == title;
    final icon = _categoryIcon(title);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = title),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFF2C1810) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSel ? const Color(0xFF2C1810) : WarmPalette.line,
            ),
            boxShadow: isSel
                ? [
                    BoxShadow(
                      color: const Color(0xFF2C1810).withValues(alpha: 0.2),
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
                size: 16,
                color: isSel ? Colors.white : WarmPalette.textPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isSel ? Colors.white : WarmPalette.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularItemTile(CustomerMenuItem item) {
    final cardWidth = (MediaQuery.of(context).size.width * 0.68).clamp(200.0, 260.0);
    return GestureDetector(
      onTap: () => _openDetail(item),
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: WarmPalette.line),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  SizedBox(
                    width: 68,
                    height: 68,
                    child: item.imageUrl.isNotEmpty
                        ? Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: WarmPalette.surfaceMuted,
                              child: const Icon(Icons.coffee, color: WarmPalette.primary),
                            ),
                          )
                        : Container(
                            color: WarmPalette.surfaceMuted,
                            child: const Icon(Icons.coffee, color: WarmPalette.primary),
                          ),
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 10, color: WarmPalette.secondary),
                          const SizedBox(width: 2),
                          Text('${item.rating}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: WarmPalette.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: WarmPalette.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${item.basePrice.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: WarmPalette.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
