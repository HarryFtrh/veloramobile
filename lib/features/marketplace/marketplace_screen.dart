import 'package:flutter/material.dart';
import '../../core/config/app_theme.dart';
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
      final product = _products.firstWhere((p) => p.id == entry.key, orElse: () => MarketplaceProduct(id: '', name: '', price: 0, stock: 0));
      total += product.price * entry.value;
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
            backgroundColor: const Color(0xFF131722),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF23293B)),
            ),
            title: Row(
              children: [
                const Icon(Icons.shopping_cart_checkout_rounded, color: Color(0xFF0288D1)),
                const SizedBox(width: 8),
                Text('Keranjang B2B ($_cartItemCount Item)', style: const TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: _cart.entries.map((entry) {
                    final prod = _products.firstWhere((p) => p.id == entry.key, orElse: () => MarketplaceProduct(id: '', name: 'Produk', price: 0, stock: 0));
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(prod.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: Text('${CurrencyFormatter.format(prod.price)} x ${entry.value}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
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
                          Text('${entry.value}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF0288D1), size: 20),
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
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
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
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    }
                  } catch (e) {
                    AudioHelper.errorFeedback();
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Gagal checkout: $e'), backgroundColor: Colors.red),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0288D1),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Checkout Faktur'),
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
      backgroundColor: const Color(0xFF090A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131722),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_buyerName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            Row(
              children: [
                const Icon(Icons.stars_rounded, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text('Poin Reward: $_points', style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                onPressed: _showCartDialog,
              ),
              if (_cartItemCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
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
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF131722),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('Keluar Akun B2B?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  content: const Text(
                    'Apakah Anda yakin ingin keluar dari portal pembelian grosir B2B ini?',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF0288D1),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.store_mall_directory_rounded, size: 18), text: 'Katalog PBF'),
            Tab(icon: Icon(Icons.receipt_long_rounded, size: 18), text: 'Riwayat Pesanan'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0288D1)))
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
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Cari obat, alkes, atau principal...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
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
                    Expanded(
                      child: _products.isEmpty
                          ? const Center(
                              child: Text(
                                'Tidak ada produk katalog ditemukan dari PBF rekanan.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: _products.length,
                              itemBuilder: (ctx, idx) {
                                final p = _products[idx];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF131722),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFF23293B)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E293B),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.medication_rounded, color: Color(0xFF0288D1), size: 28),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.name,
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${p.packaging ?? 'Box'} • Stok: ${p.stock}',
                                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              CurrencyFormatter.format(p.price),
                                              style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => _addToCart(p),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0288D1),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        child: const Text('Beli', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                    ? const Center(
                        child: Text(
                          'Belum ada riwayat pesanan faktur B2B.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _orderHistory.length,
                        itemBuilder: (ctx, idx) {
                          final o = _orderHistory[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF131722),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF23293B)),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFF1E293B),
                                child: Icon(Icons.receipt_rounded, color: Color(0xFF0288D1), size: 20),
                              ),
                              title: Text(o.orderNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text(
                                '${CurrencyFormatter.format(o.totalAmount)} • ${o.createdAt.day}/${o.createdAt.month}/${o.createdAt.year}',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              ),
                              trailing: DynamicIslandPill(
                                icon: Icons.check_circle_outline,
                                text: o.status.toUpperCase(),
                                backgroundColor: o.status == 'completed' ? const Color(0xFF10B981) : const Color(0xFF0288D1),
                              ),
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

