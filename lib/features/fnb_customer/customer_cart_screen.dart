// features/fnb_customer/customer_cart_screen.dart
import 'package:flutter/material.dart';

import '../../core/design/tokens.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/session_storage.dart';
import '../fnb/billing.dart';
import '../fnb/fnb_register_service.dart';
import '../fnb/modifiers.dart';
import 'customer_models.dart';
import 'customer_order_tracking_screen.dart';
import 'widgets/customer_cart_item_card.dart';
import 'widgets/customer_cart_bottom_bar.dart';
import 'widgets/customer_cart_order_type_bar.dart';
import 'widgets/customer_cart_payment_selector.dart';
import 'widgets/customer_cart_promo_card.dart';
import 'widgets/customer_cart_summary_card.dart';

export 'widgets/customer_cart_bottom_bar.dart';
export 'widgets/customer_cart_order_type_bar.dart';
export 'widgets/customer_cart_payment_selector.dart';
export 'widgets/customer_cart_promo_card.dart';
export 'widgets/customer_cart_summary_card.dart';
export 'widgets/customer_voucher_dialog.dart';

class CustomerCartScreen extends StatefulWidget {
  const CustomerCartScreen({
    super.key,
    required this.cartItems,
    this.tableId,
    this.tableName = 'Meja Pemesan',
    required this.onClearCart,
    required this.onUpdateCart,
  });

  final List<CustomerCartItem> cartItems;
  final String? tableId;
  final String tableName;
  final VoidCallback onClearCart;
  final ValueChanged<List<CustomerCartItem>> onUpdateCart;

  @override
  State<CustomerCartScreen> createState() => _CustomerCartScreenState();
}

class _CustomerCartScreenState extends State<CustomerCartScreen> {
  late String _orderType;
  String _paymentMethod = 'GoPay';
  bool _voucherApplied = false;
  String? _voucherCode;
  int _voucherDiscount = 0;
  bool _isSubmitting = false;
  BillingSettings? _billing;

  @override
  void initState() {
    super.initState();
    _orderType = widget.tableName.isNotEmpty
        ? 'Dine-In (${widget.tableName})'
        : 'Takeaway / Walk-In';
    _loadBilling();
  }

  Future<void> _loadBilling() async {
    try {
      final b = await BillingSettings.fetch();
      if (mounted) setState(() => _billing = b);
    } catch (e) {
      debugPrint('[CustomerCartScreen] Gagal memuat billing settings: $e');
    }
  }

  int get _subtotal =>
      widget.cartItems.fold(0, (acc, item) => acc + item.totalPrice);

  BillBreakdown get _calculatedBill {
    final b = _billing ??
        const BillingSettings(
          serviceChargeEnabled: false,
          serviceChargeRate: 0,
          pb1Enabled: false,
          pb1Rate: 0,
          pb1Inclusive: false,
          roundingEnabled: false,
          roundingStep: 100,
          roundingScope: 'both',
          roundingDirection: 'floor',
        );
    return BillCalculator.calculate(
      b,
      subtotal: _subtotal,
      discount: _voucherApplied ? _voucherDiscount : 0,
    );
  }

  int get _discount => _calculatedBill.discount.round();
  int get _grandTotal => _calculatedBill.total.round();

  Future<void> _checkout() async {
    setState(() => _isSubmitting = true);
    try {
      final lines = widget.cartItems.map((ci) {
        final opts = <ModifierOption>[];
        if (ci.size.isNotEmpty && ci.size != 'Regular') {
          opts.add(ModifierOption(
            id: 'size_${ci.size}',
            name: 'Ukuran: ${ci.size}',
            price: ci.sizePrice,
          ));
        }
        if (ci.sweetness.isNotEmpty && ci.sweetness != 'Normal (100%)') {
          opts.add(ModifierOption(
            id: 'sugar_${ci.sweetness}',
            name: 'Gula: ${ci.sweetness}',
            price: 0,
          ));
        }
        if (ci.iceLevel.isNotEmpty && ci.iceLevel != 'Normal Ice') {
          opts.add(ModifierOption(
            id: 'ice_${ci.iceLevel}',
            name: 'Es: ${ci.iceLevel}',
            price: 0,
          ));
        }
        for (final top in ci.toppings) {
          if (top.isNotEmpty) {
            final perTopPrice = ci.toppings.isNotEmpty && ci.toppingsPrice > 0
                ? (ci.toppingsPrice / ci.toppings.length)
                : 0;
            opts.add(ModifierOption(
              id: 'top_$top',
              name: top,
              price: perTopPrice,
            ));
          }
        }

        return RegisterLine(
          productId: ci.product.id,
          name: ci.product.name,
          price: ci.product.basePrice,
          quantity: ci.quantity,
          note: ci.notes.isEmpty ? null : ci.notes,
          options: opts,
        );
      }).toList();

      final userName = SessionStorage.instance.getUserName();
      final customerLabel = (userName != null && userName.isNotEmpty)
          ? userName
          : 'Tamu ${widget.tableName}';

      final orderId = await FnbRegisterService.instance.sendToKitchen(
        lines: lines,
        tableId: widget.tableId,
        customerName: customerLabel,
      );

      final orderNumber = orderId.isNotEmpty
          ? '#POS-$orderId'
          : '#ORDER-${DateTime.now().millisecondsSinceEpoch % 100000}';

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CustomerOrderTrackingScreen(
            orderId: orderId,
            orderNumber: orderNumber,
            tableNumber: widget.tableName,
            totalAmount: _grandTotal,
            items: widget.cartItems,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal membuat pesanan: ${ApiException.from(e).message}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarmPalette.canvas,
      appBar: AppBar(
        backgroundColor: WarmPalette.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: WarmPalette.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            const Text(
              'Pesanan Saya (Keranjang)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: WarmPalette.textPrimary,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: WarmPalette.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  SessionStorage.instance.getTenantName() ?? 'Velora Eatery',
                  style: const TextStyle(
                    fontSize: 11,
                    color: WarmPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: widget.cartItems.isEmpty ? null : widget.onClearCart,
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 16,
              color: WarmPalette.danger,
            ),
            label: const Text(
              'Hapus',
              style: TextStyle(
                color: WarmPalette.danger,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: widget.cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: Color(0xFFA09389),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Keranjang Belanja Kosong',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: WarmPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pilih minuman atau bakery favoritmu sekarang',
                    style: TextStyle(
                      color: WarmPalette.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WarmPalette.primary,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Jelajahi Menu'),
                  ),
                ],
              ),
            )
          : Builder(
              builder: (ctx) {
                final isMobile = ctx.isMobile;
                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? double.infinity : 720,
                    ),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      children: [
                        // Segmented Order Type
                        CustomerCartOrderTypeBar(
                          currentType: _orderType,
                          tableName: widget.tableName,
                          onChanged: (newType) =>
                              setState(() => _orderType = newType),
                        ),
                        const SizedBox(height: 20),

                        // Section Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Menu yang Dipesan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: WarmPalette.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: WarmPalette.tertiary
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${widget.cartItems.length} Item',
                                style: const TextStyle(
                                  color: WarmPalette.tertiary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Cart Item Cards
                        ...widget.cartItems.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          return CustomerCartItemCard(
                            item: item,
                            onRemove: () {
                              final updated =
                                  List<CustomerCartItem>.from(widget.cartItems)
                                    ..removeAt(idx);
                              widget.onUpdateCart(updated);
                            },
                            onQuantityChanged: (newQty) {
                              if (newQty <= 0) {
                                final updated =
                                    List<CustomerCartItem>.from(widget.cartItems)
                                      ..removeAt(idx);
                                widget.onUpdateCart(updated);
                              } else {
                                final updated =
                                    List<CustomerCartItem>.from(widget.cartItems);
                                updated[idx] = item.copyWith(quantity: newQty);
                                widget.onUpdateCart(updated);
                              }
                            },
                          );
                        }),

                        // Add More Button
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: const Text(
                            'Tambah Menu Lainnya',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: WarmPalette.primary,
                            side: const BorderSide(
                              color: WarmPalette.primary,
                              width: 1.2,
                              style: BorderStyle.solid,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Promo Card
                        CustomerCartPromoCard(
                          billing: _billing,
                          subtotal: _subtotal,
                          voucherApplied: _voucherApplied,
                          voucherCode: _voucherCode,
                          voucherDiscount: _voucherDiscount,
                          onApplyVoucher: (res) {
                            setState(() {
                              _voucherApplied = true;
                              _voucherCode = res.code;
                              _voucherDiscount = res.discount;
                            });
                          },
                          onRemoveVoucher: () {
                            setState(() {
                              _voucherApplied = false;
                              _voucherCode = null;
                              _voucherDiscount = 0;
                            });
                          },
                        ),
                        if ((_billing?.activePromotions.isNotEmpty ?? false) ||
                            _voucherApplied)
                          const SizedBox(height: 24),

                        // Payment Method Selector
                        CustomerCartPaymentSelector(
                          selectedMethod: _paymentMethod,
                          onChanged: (method) =>
                              setState(() => _paymentMethod = method),
                        ),
                        const SizedBox(height: 24),

                        // Payment Summary
                        CustomerCartSummaryCard(
                          itemCount: widget.cartItems.length,
                          subtotal: _subtotal,
                          discount: _discount,
                          voucherCode: _voucherCode,
                          calculatedBill: _calculatedBill,
                          taxName: _billing?.taxName,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomSheet: widget.cartItems.isEmpty
          ? null
          : CustomerCartBottomBar(
              grandTotal: _grandTotal,
              discount: _discount,
              isSubmitting: _isSubmitting,
              onCheckout: _checkout,
            ),
    );
  }
}
