// features/fnb_customer/customer_home_screen.dart
import 'package:flutter/material.dart';

import '../../core/design/components.dart';
import '../../core/design/tokens.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/session_storage.dart';
import '../fnb/billing.dart';
import '../shared_pos/product_catalog_service.dart';
import '../tables/table_service.dart';
import 'customer_cart_screen.dart';
import 'customer_models.dart';
import 'customer_product_card.dart';
import 'customer_product_detail_sheet.dart';
import 'widgets/customer_category_ribbon.dart';
import 'widgets/customer_nav_drawer.dart';
import 'widgets/customer_popular_items_strip.dart';
import 'widgets/customer_promo_banner.dart';
import 'widgets/customer_table_picker_sheet.dart';

export 'widgets/customer_category_ribbon.dart';
export 'widgets/customer_nav_drawer.dart';
export 'widgets/customer_popular_items_strip.dart';
export 'widgets/customer_promo_banner.dart';
export 'widgets/customer_table_picker_sheet.dart';

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
    final chosen = await showCustomerTablePickerSheet(
      context,
      tables: _tables,
      selectedTable: _selectedTable,
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
      drawer: CustomerNavDrawer(
        onSwitchToStaffPos: widget.onSwitchToStaffPos,
        onSyncMenu: _loadData,
        onLogout: widget.onLogout,
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
                    CustomerPromoBanner(
                      billing: _billing,
                      onAction: () {
                        if (_visibleMenuItems.isNotEmpty) {
                          _openDetail(_visibleMenuItems.first);
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Categories Ribbon
                    CustomerCategoryRibbon(
                      categories: _categories,
                      selectedCategory: _selectedCategory,
                      onSelectCategory: (c) => setState(() => _selectedCategory = c),
                      onViewAll: () => setState(() => _selectedCategory = 'Semua'),
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
                    CustomerPopularItemsStrip(
                      products: _allProducts,
                      onTapItem: _openDetail,
                      onViewAll: () => setState(() => _selectedCategory = 'Semua'),
                    ),
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
}
