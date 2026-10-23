import 'package:flutter/material.dart';
import '../../core/config/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/audio_helper.dart';

class PharmacyCartPanel extends StatelessWidget {
  final Map<String, int> cart;
  final List<Map<String, dynamic>> drugItems;
  final num totalPrice;
  final num tuslahFee;
  final String selectedPatient;
  final String selectedDoctor;
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
    this.tuslahFee = 2500,
    required this.selectedPatient,
    required this.selectedDoctor,
    required this.onChangePatient,
    required this.onClearCart,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.onCheckout,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTuslah = totalPrice > 0 ? tuslahFee : 0;
    final grandTotal = totalPrice + effectiveTuslah;

    return Container(
      color: const Color(0xFF0D1017),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prescription Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Faktur Resep Kasir',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (cart.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                            tooltip: 'Kosongkan',
                            onPressed: () {
                              AudioHelper.actionFeedback();
                              onClearCart();
                            },
                          ),
                        if (onClose != null)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 20),
                            tooltip: 'Tutup',
                            onPressed: onClose,
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onChangePatient,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedPatient,
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Dokter: $selectedDoctor',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFF10B981)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Cart / Prescription Item List
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medication_liquid_outlined, size: 48, color: Colors.grey.shade800),
                        const SizedBox(height: 12),
                        const Text(
                          'Resep Masih Kosong',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Scan barcode atau pilih obat di sisi kiri',
                          style: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: cart.length,
                    separatorBuilder: (_, _) => const Divider(color: AppTheme.borderSubtle, height: 16),
                    itemBuilder: (context, index) {
                      final id = cart.keys.elementAt(index);
                      final qty = cart[id]!;
                      final item = drugItems.firstWhere(
                        (e) => e['id'] == id,
                        orElse: () => <String, dynamic>{},
                      );
                      final price = (item['price'] as num? ?? 0);
                      final itemTotal = price * qty;
                      final batch = item['batch'] ?? '-';

                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  'Batch: $batch (FEFO)',
                                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 18, color: AppTheme.textSecondary),
                                onPressed: () => onRemoveFromCart(id),
                              ),
                              Text(
                                '$qty',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 18, color: Color(0xFF10B981)),
                                onPressed: () => onAddToCart(id),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: 75,
                            child: Text(
                              CurrencyFormatter.format(itemTotal),
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // Financial Breakdown & Large Checkout Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal Obat', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    Text(CurrencyFormatter.format(totalPrice), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Biaya Tuslah & Embalase', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    Text(CurrencyFormatter.format(effectiveTuslah), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Pembayaran', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    Text(
                      CurrencyFormatter.format(grandTotal),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: cart.isNotEmpty ? onCheckout : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    'CHECKOUT RESEP • ${CurrencyFormatter.format(grandTotal)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
