import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/audio_helper.dart';

class PharmacyCartPanel extends StatefulWidget {
  final Map<String, int> cart;
  final List<Map<String, dynamic>> drugItems;
  final num totalPrice;
  final num tuslahFee;
  final String selectedPatient;
  final String selectedDoctor;
  final String queueNumber;
  final String medicalRecordNumber;
  final VoidCallback onChangePatient;
  final VoidCallback onClearCart;
  final Function(String id) onAddToCart;
  final Function(String id) onRemoveFromCart;
  final VoidCallback onCheckout;
  final VoidCallback? onClose;

  const PharmacyCartPanel({
    super.key,
    required this.cart,
    required this.drugItems,
    required this.totalPrice,
    this.tuslahFee = 0,
    required this.selectedPatient,
    required this.selectedDoctor,
    this.queueNumber = '-',
    this.medicalRecordNumber = '-',
    required this.onChangePatient,
    required this.onClearCart,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.onCheckout,
    this.onClose,
  });

  @override
  State<PharmacyCartPanel> createState() => _PharmacyCartPanelState();
}

class _PharmacyCartPanelState extends State<PharmacyCartPanel> {
  int _selectedPaymentMethod = 0; // 0: QRIS, 1: Tunai, 2: Debit/EDC, 3: Asuransi

  final List<Map<String, dynamic>> _paymentMethods = [
    {'name': 'QRIS', 'icon': Icons.qr_code_2_rounded},
    {'name': 'Tunai', 'icon': Icons.payments_outlined},
    {'name': 'Debit/EDC', 'icon': Icons.credit_card_outlined},
    {'name': 'Asuransi', 'icon': Icons.health_and_safety_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    const primaryEmerald = Color(0xFF006948);
    const secondaryTeal = Color(0xFF006A61);
    const borderColor = Color(0xFFE2E8F0);
    const canvasColor = Color(0xFFFAF8FF);
    const textPrimary = Color(0xFF131B2E);
    const textMuted = Color(0xFF6D7A72);

    final effectiveTuslah = widget.totalPrice > 0 ? widget.tuslahFee : 0;
    final grandTotal = widget.totalPrice + effectiveTuslah;
    final totalQty = widget.cart.values.fold<int>(0, (s, q) => s + q);
    final ppnEstimated = (widget.totalPrice * 0.11 / 1.11).round();

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Keranjang Kasir & Order Meta
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              color: canvasColor,
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: primaryEmerald,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.shopping_basket_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Keranjang Kasir',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              widget.cart.isEmpty ? 'Keranjang kosong' : '${widget.cart.length} item dipilih',
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                color: textMuted,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (widget.cart.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              AudioHelper.actionFeedback();
                              widget.onClearCart();
                            },
                            icon: const Icon(Icons.delete_sweep_rounded, size: 16, color: Color(0xFFBA1A1A)),
                            label: const Text(
                              'Reset',
                              style: TextStyle(
                                color: Color(0xFFBA1A1A),
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        if (widget.onClose != null) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20, color: textMuted),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: widget.onClose,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Clinical Patient Strip
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: widget.onChangePatient,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: secondaryTeal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.person_outline, size: 18, color: secondaryTeal),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.selectedPatient,
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF86F2E4).withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      widget.queueNumber,
                                      style: const TextStyle(
                                        fontFamily: 'JetBrains Mono',
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: secondaryTeal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'RM: ${widget.medicalRecordNumber} • ${widget.selectedDoctor}',
                                style: const TextStyle(fontSize: 10.5, color: textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: canvasColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: borderColor),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sync_alt_rounded, size: 12, color: primaryEmerald),
                              SizedBox(width: 4),
                              Text(
                                'Ganti',
                                style: TextStyle(
                                  color: primaryEmerald,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Cart Item List
          Expanded(
            child: widget.cart.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: canvasColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: borderColor),
                            ),
                            child: const Icon(Icons.receipt_long_outlined, size: 30, color: textMuted),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Keranjang Resep Kosong',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Pilih sediaan obat dari katalog atau scan barcode untuk memuat resep.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11.5, color: textMuted),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: widget.cart.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final id = widget.cart.keys.elementAt(index);
                      final qty = widget.cart[id]!;
                      final item = widget.drugItems.firstWhere(
                        (e) => e['id'] == id,
                        orElse: () => <String, dynamic>{},
                      );
                      final price = (item['price'] as num? ?? 0);
                      final itemTotal = price * qty;
                      final batch = item['batch']?.toString() ?? item['batchNumber']?.toString() ?? '-';
                      final isRx = item['isDotRed'] == true ||
                          item['isPrescriptionOnly'] == true ||
                          (item['category']?.toString().toLowerCase().contains('keras') ?? false);
                      final isAlkes = (item['category']?.toString().toLowerCase().contains('alkes') ?? false);

                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: isRx
                                                  ? const Color(0xFFFFDAD6)
                                                  : isAlkes
                                                      ? const Color(0xFFE0F2FE)
                                                      : const Color(0xFFE2E7FF),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isRx ? 'Rx' : isAlkes ? 'Alkes' : 'OTC',
                                              style: TextStyle(
                                                fontFamily: 'JetBrains Mono',
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: isRx
                                                    ? const Color(0xFFBA1A1A)
                                                    : isAlkes
                                                        ? const Color(0xFF0284C7)
                                                        : const Color(0xFF3D4A42),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              item['name'] ?? '',
                                              style: const TextStyle(
                                                fontFamily: 'Plus Jakarta Sans',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12.5,
                                                color: textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Batch: $batch • ${CurrencyFormatter.format(price)}/${item['unit'] ?? 'unit'}',
                                        style: const TextStyle(
                                          fontFamily: 'JetBrains Mono',
                                          fontSize: 10,
                                          color: textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () => widget.onRemoveFromCart(id),
                                  borderRadius: BorderRadius.circular(4),
                                  child: const Padding(
                                    padding: EdgeInsets.all(2),
                                    child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF6D7A72)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () => widget.onRemoveFromCart(id),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          child: Icon(Icons.remove, size: 12, color: textPrimary),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        child: Text(
                                          '$qty',
                                          style: const TextStyle(
                                            fontFamily: 'JetBrains Mono',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11.5,
                                            color: primaryEmerald,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => widget.onAddToCart(id),
                                        child: Container(
                                          height: 28,
                                          padding: const EdgeInsets.symmetric(horizontal: 6),
                                          decoration: const BoxDecoration(
                                            color: primaryEmerald,
                                            borderRadius: BorderRadius.horizontal(right: Radius.circular(5)),
                                          ),
                                          child: const Icon(Icons.add, size: 12, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(itemTotal),
                                  style: const TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action & Financial Summary Area
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: canvasColor,
              border: Border(top: BorderSide(color: borderColor, width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Financial Calculation Rows
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal ($totalQty item)', style: const TextStyle(color: textMuted, fontSize: 11.5)),
                    Text(
                      CurrencyFormatter.format(widget.totalPrice),
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tuslah & Embalase Resep', style: TextStyle(color: textMuted, fontSize: 11.5)),
                    Text(
                      CurrencyFormatter.format(effectiveTuslah),
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('PPN Farmasi (Termasuk 11%)', style: TextStyle(color: textMuted, fontSize: 11)),
                    Text(
                      CurrencyFormatter.format(ppnEstimated),
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11,
                        color: Color(0xFF6D7A72),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: borderColor, height: 1),
                ),

                // Grand Total Highlight
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL TAGIHAN',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 10,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.bold,
                            color: textMuted,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(grandTotal),
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: primaryEmerald,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryEmerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$totalQty Qty Total',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryEmerald,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Quick Payment Method Selector Pills
                Row(
                  children: List.generate(_paymentMethods.length, (idx) {
                    final item = _paymentMethods[idx];
                    final isSelected = _selectedPaymentMethod == idx;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: idx < _paymentMethods.length - 1 ? 6 : 0),
                        child: InkWell(
                          onTap: () => setState(() => _selectedPaymentMethod = idx),
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF86F2E4) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? secondaryTeal : borderColor,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item['icon'] as IconData,
                                  size: 14,
                                  color: isSelected ? const Color(0xFF006F66) : textMuted,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['name'] as String,
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 9.5,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? const Color(0xFF006F66) : textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),

                // Emerald Primary CTA Checkout Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: widget.cart.isNotEmpty ? widget.onCheckout : null,
                    icon: const Icon(Icons.payments_rounded, size: 18),
                    label: const Text(
                      'Proses Pembayaran / Bayar Cepat',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryEmerald,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                      disabledForegroundColor: const Color(0xFF94A3B8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: widget.cart.isNotEmpty ? 2 : 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
