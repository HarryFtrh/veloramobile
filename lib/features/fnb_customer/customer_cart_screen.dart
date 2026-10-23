// features/fnb_customer/customer_cart_screen.dart
import 'package:flutter/material.dart';

import '../../core/design/tokens.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/session_storage.dart';
import '../fnb/billing.dart';
import '../fnb/fnb_register_service.dart';
import 'customer_cart_item_card.dart';
import 'customer_models.dart';
import 'customer_order_tracking_screen.dart';

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
    _orderType = widget.tableName.isNotEmpty ? 'Dine-In (${widget.tableName})' : 'Takeaway / Walk-In';
    _loadBilling();
  }

  Future<void> _loadBilling() async {
    try {
      final b = await BillingSettings.fetch();
      if (mounted) setState(() => _billing = b);
    } catch (_) {}
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
      final lines = widget.cartItems
          .map(
            (ci) => RegisterLine(
              productId: ci.product.id,
              name: ci.product.name,
              price: ci.unitPrice,
              quantity: ci.quantity,
              note: ci.notes.isEmpty ? null : ci.notes,
            ),
          )
          .toList();

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
                  style: const TextStyle(fontSize: 11, color: WarmPalette.textSecondary),
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
                    style: TextStyle(color: WarmPalette.textSecondary, fontSize: 13),
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
                    constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 720),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      children: [
                // Segmented Order Type
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: WarmPalette.surfaceMuted,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      _buildTypeTab(
                        'Dine-In (${widget.tableName})',
                        Icons.restaurant_rounded,
                      ),
                      _buildTypeTab('Takeaway', Icons.shopping_bag_outlined),
                      _buildTypeTab('Delivery', Icons.delivery_dining_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daftar Menu Dipilih',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: WarmPalette.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: WarmPalette.tertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.cartItems.length} Menu',
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
                      final updated = List<CustomerCartItem>.from(widget.cartItems)..removeAt(idx);
                      widget.onUpdateCart(updated);
                    },
                    onQuantityChanged: (newQty) {
                      if (newQty <= 0) {
                        final updated = List<CustomerCartItem>.from(widget.cartItems)..removeAt(idx);
                        widget.onUpdateCart(updated);
                      } else {
                        final updated = List<CustomerCartItem>.from(widget.cartItems);
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
                      color: WarmPalette.line,
                      style: BorderStyle.solid,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),

                // Promo Card (Hanya muncul jika ada promo aktif dari toko)
                if ((_billing?.activePromotions.isNotEmpty ?? false) || _voucherApplied) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF0E3),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: WarmPalette.secondary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: WarmPalette.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.discount_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _voucherCode ?? 'Promosi Toko',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: WarmPalette.textPrimary,
                                    ),
                                  ),
                                  if (_voucherApplied) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: WarmPalette.tertiary,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'TERAPLIKASI',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _voucherApplied
                                    ? 'Potongan Rp ${_voucherDiscount.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")} diterapkan'
                                    : 'Gunakan promo diskon spesial toko',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: WarmPalette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            if (_voucherApplied) {
                              setState(() {
                                _voucherApplied = false;
                                _voucherCode = null;
                                _voucherDiscount = 0;
                              });
                              return;
                            }
                            final res = await showDialog<_PromoApplicationResult>(
                              context: context,
                              builder: (ctx) => _VoucherPromoDialog(
                                billing: _billing,
                                subtotal: _subtotal,
                              ),
                            );
                            if (res != null && mounted) {
                              setState(() {
                                _voucherApplied = true;
                                _voucherCode = res.code;
                                _voucherDiscount = res.discount;
                              });
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: WarmPalette.line),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                          ),
                          child: Text(
                            _voucherApplied ? 'Hapus' : 'Pakai Promo',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: WarmPalette.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Payment Method
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Metode Pembayaran',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: WarmPalette.textPrimary,
                      ),
                    ),
                    const Text(
                      'Pilih Salah Satu',
                      style: TextStyle(fontSize: 11, color: WarmPalette.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildPaymentOption(
                  'GoPay',
                  'E-Wallet Instan',
                  Icons.account_balance_wallet_rounded,
                ),
                _buildPaymentOption(
                  'QRIS',
                  'BCA, Mandiri, OVO, ShopeePay, dll',
                  Icons.qr_code_scanner_rounded,
                ),
                _buildPaymentOption(
                  'DANA',
                  'E-Wallet Dompet Digital',
                  Icons.wallet_rounded,
                ),
                _buildPaymentOption(
                  'Kartu Debit',
                  'Visa / Mastercard / GPN',
                  Icons.credit_card_rounded,
                ),
                const SizedBox(height: 24),

                // Payment Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: WarmPalette.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.receipt_outlined,
                            size: 18,
                            color: WarmPalette.primary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Rincian Pembayaran',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildSummaryRow(
                        'Subtotal (${widget.cartItems.length} item)',
                        'Rp ${_subtotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                      ),
                      if (_discount > 0)
                        _buildSummaryRow(
                          'Diskon Promo (${_voucherCode ?? "PROMO"})',
                          '-Rp ${_discount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                          isDiscount: true,
                        ),
                      if (_calculatedBill.serviceCharge > 0)
                        _buildSummaryRow(
                          'Biaya Layanan',
                          'Rp ${_calculatedBill.serviceCharge.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                        ),
                      if (_calculatedBill.tax > 0)
                        _buildSummaryRow(
                          'Pajak (${_billing?.taxName ?? 'PB1'})',
                          'Rp ${_calculatedBill.tax.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                        ),
                      if (_calculatedBill.rounding != 0)
                        _buildSummaryRow(
                          'Pembulatan',
                          'Rp ${_calculatedBill.rounding.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
      bottomSheet: widget.cartItems.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: WarmPalette.line)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL TAGIHAN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: WarmPalette.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Rp ${_grandTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: WarmPalette.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_discount > 0) ...[
                        const SizedBox(width: 8),
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
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                size: 14,
                                color: WarmPalette.tertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Hemat ${_discount >= 1000 ? "${(_discount / 1000).round()}k" : "Rp $_discount"}',
                                style: const TextStyle(
                                  color: WarmPalette.tertiary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _checkout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WarmPalette.primary,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock_rounded, size: 18),
                                const SizedBox(width: 8),
                                const Text(
                                  'Bayar Sekarang & Pesan',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTypeTab(String title, IconData icon) {
    final isSel = _orderType == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _orderType = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSel ? WarmPalette.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSel ? Colors.white : WarmPalette.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                      color: isSel ? Colors.white : WarmPalette.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String name, String sub, IconData icon) {
    final isSel = _paymentMethod == name;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = name),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSel ? WarmPalette.primary : WarmPalette.line,
            width: isSel ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: WarmPalette.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: WarmPalette.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: WarmPalette.textPrimary,
                    ),
                  ),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 11,
                      color: WarmPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSel
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSel ? WarmPalette.primary : WarmPalette.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: WarmPalette.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDiscount
                  ? WarmPalette.tertiary
                  : WarmPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoApplicationResult {
  const _PromoApplicationResult({
    required this.code,
    required this.discount,
    required this.name,
  });

  final String code;
  final int discount;
  final String name;
}

class _VoucherPromoDialog extends StatefulWidget {
  const _VoucherPromoDialog({this.billing, required this.subtotal});
  final BillingSettings? billing;
  final num subtotal;

  @override
  State<_VoucherPromoDialog> createState() => _VoucherPromoDialogState();
}

class _VoucherPromoDialogState extends State<_VoucherPromoDialog> {
  late final TextEditingController _codeCtrl;
  String? _errorMsg;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _applyPromo(StorePromotion promo) {
    if (promo.minOrderAmount > 0 && widget.subtotal < promo.minOrderAmount) {
      setState(() {
        _errorMsg = 'Minimal belanja Rp ${promo.minOrderAmount.toInt()} untuk promo "${promo.name}"';
      });
      return;
    }
    final discount = promo.calculateDiscount(widget.subtotal).round();
    Navigator.pop(
      context,
      _PromoApplicationResult(
        code: promo.code ?? promo.name,
        discount: discount,
        name: promo.name,
      ),
    );
  }

  Future<void> _submitCode() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty || _isVerifying) return;

    final promo = widget.billing?.findPromotionByCode(code);
    if (promo != null) {
      if (promo.minOrderAmount > 0 && widget.subtotal < promo.minOrderAmount) {
        setState(() {
          _errorMsg = 'Minimal belanja Rp ${promo.minOrderAmount.toInt()} untuk voucher ini';
        });
        return;
      }
      final disc = promo.calculateDiscount(widget.subtotal).round();
      Navigator.pop(
        context,
        _PromoApplicationResult(code: code, discount: disc, name: promo.name),
      );
      return;
    }

    // Try online verification via backend API
    setState(() {
      _isVerifying = true;
      _errorMsg = null;
    });

    try {
      final remote = await BillingSettings.verifyVoucherCodeApi(code, widget.subtotal.toDouble());
      if (!mounted) return;
      if (remote != null) {
        final disc = remote.calculateDiscount(widget.subtotal.toDouble()).round();
        Navigator.pop(
          context,
          _PromoApplicationResult(code: code, discount: disc, name: remote.name),
        );
        return;
      }
      setState(() {
        _errorMsg = 'Kode promo "$code" tidak ditemukan atau sudah tidak aktif';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'Gagal memverifikasi voucher: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final promos = widget.billing?.activePromotions ?? const [];
    final subtotal = widget.subtotal;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.discount_outlined, color: WarmPalette.primary, size: 22),
          SizedBox(width: 8),
          Expanded(
            child: Text('Voucher & Promo Toko', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMsg != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: WarmPalette.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_errorMsg!, style: const TextStyle(color: WarmPalette.danger, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            TextField(
              controller: _codeCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Kode Promo',
                hintText: 'Mis. DISKON10',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            if (promos.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Promo Tersedia:',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: WarmPalette.textSecondary),
              ),
              const SizedBox(height: 8),
              for (final promo in promos) ...[
                Builder(
                  builder: (ctx) {
                    final eligible = promo.minOrderAmount <= 0 || subtotal >= promo.minOrderAmount;
                    final disc = promo.calculateDiscount(subtotal).round();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: eligible ? WarmPalette.surface : WarmPalette.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: eligible ? WarmPalette.primary.withValues(alpha: 0.3) : WarmPalette.line),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  promo.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: eligible ? WarmPalette.textPrimary : WarmPalette.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  promo.minOrderAmount > 0
                                      ? 'Min. Rp ${promo.minOrderAmount.toInt()}${eligible ? " • Hemat Rp $disc" : " (Kurang Rp ${(promo.minOrderAmount - subtotal).toInt()})"}'
                                      : 'Hemat Rp $disc',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: eligible ? WarmPalette.textSecondary : WarmPalette.danger,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          TextButton(
                            onPressed: eligible ? () => _applyPromo(promo) : null,
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            child: const Text('Pakai', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isVerifying ? null : _submitCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: WarmPalette.primary,
            foregroundColor: Colors.white,
          ),
          child: _isVerifying
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Terapkan'),
        ),
      ],
    );
  }
}
