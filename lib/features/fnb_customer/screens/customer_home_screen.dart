// features/fnb_customer/customer_home_screen.dart
import 'dart:async';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/session_storage.dart';
import '../../fnb/billing.dart';
import '../../fnb/services/fnb_catalog_service.dart';
import '../../shared_pos/services/product_catalog_service.dart';
import '../../tables/table_service.dart';
import 'customer_cart_screen.dart';
import '../models/customer_models.dart';
import '../widgets/customer_product_card.dart';
import '../widgets/customer_product_detail_sheet.dart';
import '../widgets/customer_category_ribbon.dart';
import '../widgets/customer_nav_drawer.dart';
import '../widgets/customer_popular_items_strip.dart';
import '../widgets/customer_promo_banner.dart';
import '../widgets/customer_table_picker_sheet.dart';

export '../widgets/customer_category_ribbon.dart';
export '../widgets/customer_nav_drawer.dart';
export '../widgets/customer_popular_items_strip.dart';
export '../widgets/customer_promo_banner.dart';
export '../widgets/customer_table_picker_sheet.dart';

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
  List<CustomerMenuItem> _visibleMenuItems = const [];
  List<String> _categories = ['Semua'];
  List<CafeTableInfo> _tables = [];
  CafeTableInfo? _selectedTable;
  String _searchQuery = '';
  Timer? _searchDebounce;
  BillingSettings? _billing;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final catalogFuture = FnbCatalogService.instance.fetchCatalog();
      final tablesFuture = TableService.instance.tables().catchError((_) => <CafeTableInfo>[]);
      final billingFuture = BillingSettings.fetch().catchError((_) => const BillingSettings());

      final catalog = await catalogFuture;
      final tables = await tablesFuture;
      final billing = await billingFuture;

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
          _visibleMenuItems = _computeVisibleMenuItems();
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

  List<CustomerMenuItem> _computeVisibleMenuItems() {
    final query = _searchQuery.trim().toLowerCase();
    final result = <CustomerMenuItem>[];
    for (final p in _allProducts) {
      final inCat =
          _selectedCategory == 'Semua' || p.category == _selectedCategory;
      if (!inCat) continue;
      final inSearch =
          query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.sku.toLowerCase().contains(query);
      if (!inSearch) continue;
      result.add(
        CustomerMenuItem(
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
        ),
      );
    }
    return result;
  }

  void _setCategory(String category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      _visibleMenuItems = _computeVisibleMenuItems();
    });
  }

  void _onSearchChanged(String q) {
    _searchQuery = q;
    _searchDebounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() => _visibleMenuItems = _computeVisibleMenuItems());
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() => _visibleMenuItems = _computeVisibleMenuItems());
    });
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
            backgroundColor: Theme.of(context).colorScheme.primary,
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
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(
        backgroundColor: p.canvas,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu_rounded, color: p.textPrimary),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          SessionStorage.instance.getTenantName() ?? 'Velora Kafe',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: p.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          if (widget.onSwitchToStaffPos != null)
            IconButton(
              icon: Icon(
                Icons.point_of_sale_rounded,
                color: primaryColor,
              ),
              tooltip: 'Beralih ke Layar Kasir POS',
              onPressed: widget.onSwitchToStaffPos,
            ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.shopping_bag_outlined,
                  color: p.textPrimary,
                ),
                onPressed: _openCart,
              ),
              if (_cart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: primaryColor,
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
          ? VeloraOrbitLoader.page(
              color: primaryColor,
              label: 'Memuat menu...',
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_off,
                        size: 48,
                        color: p.danger,
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
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Muat Ulang'),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      sliver: SliverList.list(
                        children: [
                    _buildTopLocationBar(p, primaryColor),
                    const SizedBox(height: 14),
                    _buildSearchBar(p, primaryColor),

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
                      onSelectCategory: _setCategory,
                      onViewAll: () => _setCategory('Semua'),
                    ),
                    const SizedBox(height: 20),

                    // Section 1: Rekomendasi Barista
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '· Rekomendasi Barista',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: p.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: 0.14),
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
                        ],
                      ),
                    ),

                    // Grid of items (virtualized SliverGrid)
                    if (_visibleMenuItems.isEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.all(40),
                        sliver: SliverToBoxAdapter(
                          child: Center(
                            child: Text(
                              'Tidak ada produk pada kategori ini',
                              style: TextStyle(color: p.textSecondary),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          gridDelegate: context.isMobile
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
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                              final item = _visibleMenuItems[i];
                              return CustomerProductCard(
                                item: item,
                                onTap: () => _openDetail(item),
                              );
                            },
                            childCount: _visibleMenuItems.length,
                          ),
                        ),
                      ),

                    // Section 2: Menu Terpopuler (when all products available)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                      sliver: SliverToBoxAdapter(
                        child: CustomerPopularItemsStrip(
                          products: _allProducts,
                          onTapItem: _openDetail,
                          onViewAll: () => _setCategory('Semua'),
                        ),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: FloatingPillNavBar(
        currentIndex: _navIndex,
        onTap: (idx) {
          setState(() => _navIndex = idx);
          if (idx == 1) {
            _setCategory('Semua');
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

  Widget _buildTopLocationBar(AppPalette p, Color primaryColor) {
    return Row(
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
                                color: p.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: p.line),
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
                                        Text(
                                          'Lokasi Meja',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: p.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          _selectedTable != null
                                              ? '${SessionStorage.instance.getLocationName() ?? "Senopati, Jkt"} • ${_selectedTable!.name}'
                                              : '${SessionStorage.instance.getLocationName() ?? "Senopati, Jkt"} • Meja 04',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: p.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: p.textSecondary,
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
                            color: p.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: p.line),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.notifications_outlined,
                                  color: p.textPrimary,
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
                    );
  }

  Widget _buildSearchBar(AppPalette p, Color primaryColor) {
    return Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: p.surfaceMuted,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: p.line),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                  color: p.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    onChanged: _onSearchChanged,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: p.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Cari kopi, pastry, atau brunch...',
                                      hintStyle: TextStyle(
                                        fontSize: 13,
                                        color: p.textSecondary,
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
                            color: primaryColor,
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
                                setState(() {
                                  _searchQuery = '';
                                  _visibleMenuItems = _computeVisibleMenuItems();
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    );
  }
}
