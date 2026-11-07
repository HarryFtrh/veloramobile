import 'package:flutter/material.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/audio_helper.dart';
import '../../core/components/dynamic_island_pill.dart';
import 'marketplace_service.dart';

class MarketplaceScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const MarketplaceScreen({
    super.key,
    required this.onLogout,
  });

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<MarketplaceProduct> _products = [];
  final Map<String, MarketplaceProduct> _productsById = {};
  List<MarketplaceOrderHistoryItem> _orderHistory = [];
  num _points = 0;
  String _buyerName = '';
  final TextEditingController _searchController = TextEditingController();

  final Map<String, int> _cart = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final tenantName = SessionStorage.instance.getTenantName() ?? 'Apotek Mandiri';
    setState(() => _buyerName = tenantName);

    try {
      final points = await MarketplaceService.instance.getPointsBalance();
      final history = await MarketplaceService.instance.getOrderHistory();
      final products = await MarketplaceService.instance.fetchCatalog();

      if (mounted) {
        setState(() {
          _points = points;
          _orderHistory = history;
          _products = products;
          _productsById.clear();
          for (final p in products) {
            _productsById[p.id] = p;
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _cartItemCount => _cart.values.fold(0, (sum, count) => sum + count);

  num get _cartTotal {
    num total = 0;
    for (final entry in _cart.entries) {
      final product = _productsById[entry.key];
      if (product != null) {
        total += product.price * entry.value;
      }
    }
    return total;
  }

  void _addToCart(MarketplaceProduct p) {
    AudioHelper.tapFeedback();
    setState(() {
      _cart[p.id] = (_cart[p.id] ?? 0) + 1;
    });
  }

  void _showCartDialog() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang belanja grosir masih kosong.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shopping_cart_checkout_rounded, color: Color(0xFF0284C7), size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'Keranjang B2B ($_cartItemCount Item)',
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: _cart.entries.map((entry) {
                    final prod = _productsById[entry.key] ??
                        MarketplaceProduct(id: entry.key, name: 'Produk', price: 0, stock: 0);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prod.name,
                                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${CurrencyFormatter.format(prod.price)} × ${entry.value}',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFDC2626), size: 20),
                            onPressed: () {
                              setDialogState(() {
                                setState(() {
                                  if (entry.value > 1) {
                                    _cart[entry.key] = entry.value - 1;
                                  } else {
                                    _cart.remove(entry.key);
                                  }
                                });
                              });
                            },
                          ),
                          Text(
                            '${entry.value}',
                            style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF0284C7), size: 20),
                            onPressed: () {
                              setDialogState(() {
                                setState(() {
                                  _cart[entry.key] = entry.value + 1;
                                });
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            actions: [
              Text(
                'Total: ${CurrencyFormatter.format(_cartTotal)}',
                style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              ),
              FilledButton(
                onPressed: () async {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);
                  try {
                    final items = _cart.entries.map((e) => {'product_id': e.key, 'quantity': e.value}).toList();
                    await MarketplaceService.instance.processCheckout(sellerId: 'PBF-DEFAULT', items: items);
                    AudioHelper.successFeedback();
                    if (mounted) {
                      setState(() => _cart.clear());
                      _loadInitialData();
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Pesanan grosir berhasil dibuat langsung ke PBF!'),
                          backgroundColor: Color(0xFF059669),
                        ),
                      );
                    }
                  } catch (e) {
                    AudioHelper.errorFeedback();
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Gagal checkout: $e'), backgroundColor: const Color(0xFFDC2626)),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('Checkout Faktur', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF0284C7),
              indicatorWeight: 3,
              labelColor: const Color(0xFF0284C7),
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.store_mall_directory_rounded, size: 18), text: 'Katalog PBF'),
                Tab(icon: Icon(Icons.receipt_long_rounded, size: 18), text: 'Riwayat Pesanan'),
              ],
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _buyerName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            Row(
              children: [
                const Icon(Icons.stars_rounded, color: Color(0xFF0284C7), size: 14),
                const SizedBox(width: 4),
                Text(
                  'Poin Reward: $_points',
                  style: const TextStyle(color: Color(0xFF0284C7), fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'Keranjang Pembelian',
                icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF0F172A)),
                onPressed: _showCartDialog,
              ),
              if (_cartItemCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_cartItemCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Keluar Akun B2B?',
                          style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    'Apakah Anda yakin ingin keluar dari portal pembelian grosir B2B ini?',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        widget.onLogout();
                      },
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Katalog PBF
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x04000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13.5),
                              decoration: InputDecoration(
                                hintText: 'Cari obat, alkes, atau principal distributor...',
                                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8), size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _loadInitialData();
                                  },
                                ),
                              ),
                              onSubmitted: (val) {
                                setState(() => _isLoading = true);
                                MarketplaceService.instance.fetchCatalog(search: val).then((list) {
                                  if (mounted) setState(() { _products = list; _isLoading = false; });
                                });
                              },
                            ),
                          ),
                        ),
                        Expanded(
                          child: _products.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.inventory_2_outlined, size: 36, color: Color(0xFF94A3B8)),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Tidak ada produk katalog ditemukan dari PBF rekanan.',
                                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  itemCount: _products.length,
                                  itemBuilder: (ctx, idx) {
                                    final p = _products[idx];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x04000000),
                                            blurRadius: 6,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 46,
                                            height: 46,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE0F2FE),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(Icons.medication_rounded, color: Color(0xFF0284C7), size: 24),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  p.name,
                                                  style: const TextStyle(
                                                    color: Color(0xFF0F172A),
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 13.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${p.packaging ?? 'Box'} • Stok PBF: ${p.stock}',
                                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  CurrencyFormatter.format(p.price),
                                                  style: const TextStyle(
                                                    color: Color(0xFF0284C7),
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 13.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          FilledButton.icon(
                                            onPressed: () => _addToCart(p),
                                            icon: const Icon(Icons.add_shopping_cart_rounded, size: 15),
                                            label: const Text('Beli', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: const Color(0xFF0284C7),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),

                    // Tab 2: Riwayat Pesanan
                    _orderHistory.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.receipt_long_outlined, size: 36, color: Color(0xFF94A3B8)),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Belum ada riwayat pesanan faktur B2B.',
                                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: _orderHistory.length,
                            itemBuilder: (ctx, idx) {
                              final o = _orderHistory[idx];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x04000000),
                                      blurRadius: 6,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE0F2FE),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.receipt_rounded, color: Color(0xFF0284C7), size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            o.orderNumber,
                                            style: const TextStyle(
                                              color: Color(0xFF0F172A),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13.5,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${CurrencyFormatter.format(o.totalAmount)} • ${o.createdAt.day}/${o.createdAt.month}/${o.createdAt.year}',
                                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DynamicIslandPill(
                                      icon: Icons.check_circle_outline,
                                      text: o.status.toUpperCase(),
                                      backgroundColor: o.status == 'completed'
                                          ? const Color(0xFF059669)
                                          : const Color(0xFF0284C7),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
