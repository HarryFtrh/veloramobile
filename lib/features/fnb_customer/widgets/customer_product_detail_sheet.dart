// features/fnb_customer/customer_product_detail_sheet.dart
import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../../fnb/modifiers.dart';
import '../customer_models.dart';
import 'customer_product_beverage_options.dart';
import 'customer_product_hero_header.dart';
import 'customer_product_modifier_group_card.dart';
import 'customer_product_price_summary_bar.dart';

export 'customer_product_beverage_options.dart';
export 'customer_product_hero_header.dart';
export 'customer_product_modifier_group_card.dart';
export 'customer_product_price_summary_bar.dart';

class CustomerProductDetailSheet extends StatefulWidget {
  const CustomerProductDetailSheet({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  final CustomerMenuItem product;
  final ValueChanged<CustomerCartItem> onAddToCart;

  static Future<void> show(
    BuildContext context, {
    required CustomerMenuItem product,
    required ValueChanged<CustomerCartItem> onAddToCart,
  }) {
    final isMobile = context.isMobile;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 600),
        child: CustomerProductDetailSheet(
          product: product,
          onAddToCart: onAddToCart,
        ),
      ),
    );
  }

  @override
  State<CustomerProductDetailSheet> createState() =>
      _CustomerProductDetailSheetState();
}

class _CustomerProductDetailSheetState
    extends State<CustomerProductDetailSheet> {
  final String _selectedSize = 'Regular';
  final int _sizePrice = 0;
  String _selectedSweetness = 'Normal (100%)';
  String _selectedIce = 'Normal Ice';
  final Set<String> _selectedToppings = {};
  int _toppingsPrice = 0;
  int _quantity = 1;
  final _notesCtrl = TextEditingController();
  bool _isFavorite = false;

  List<ModifierGroup> _apiModifierGroups = [];
  bool _isLoadingModifiers = true;

  @override
  void initState() {
    super.initState();
    _loadModifiers();
  }

  Future<void> _loadModifiers() async {
    try {
      final groups = await ModifierService.instance.groups();
      if (mounted) {
        setState(() {
          _apiModifierGroups = groups
              .where((g) => g.appliesTo(widget.product.category))
              .toList();
          _isLoadingModifiers = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingModifiers = false);
      }
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  int get _totalPrice {
    final unit = widget.product.basePrice + _sizePrice + _toppingsPrice;
    return unit * _quantity;
  }

  void _toggleOption(ModifierGroup group, ModifierOption opt) {
    setState(() {
      final isChecked = _selectedToppings.contains(opt.name);
      if (isChecked) {
        _selectedToppings.remove(opt.name);
        _toppingsPrice -= opt.price.round();
      } else {
        if (group.isSingleChoice) {
          for (final o in group.options) {
            if (_selectedToppings.contains(o.name)) {
              _selectedToppings.remove(o.name);
              _toppingsPrice -= o.price.round();
            }
          }
        }
        _selectedToppings.add(opt.name);
        _toppingsPrice += opt.price.round();
      }
    });
  }

  void _submit() {
    final item = CustomerCartItem(
      product: widget.product,
      size: _selectedSize,
      sizePrice: _sizePrice,
      sweetness: _selectedSweetness,
      iceLevel: _selectedIce,
      toppings: _selectedToppings.toList(),
      toppingsPrice: _toppingsPrice,
      quantity: _quantity,
      notes: _notesCtrl.text.trim(),
    );

    widget.onAddToCart(item);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$_quantity× ${widget.product.name} dimasukkan ke keranjang',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isBeverage = [
      'coffee',
      'kopi',
      'tea',
      'teh',
      'beverage',
      'drink',
      'minuman',
    ].any((k) => widget.product.category.toLowerCase().contains(k));

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Drag Handle & Favorite Button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 32),
                    Center(
                      child: Container(
                        width: 44,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: p.line,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: primaryColor,
                      ),
                      onPressed: () {
                        setState(() => _isFavorite = !_isFavorite);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isFavorite
                                  ? '${widget.product.name} ditambahkan ke favorit!'
                                  : '${widget.product.name} dihapus dari favorit',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    CustomerProductHeroHeader(product: widget.product),
                    const SizedBox(height: 20),

                    // Modifier Groups / Topping & Size Options from Server
                    if (_isLoadingModifiers)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_apiModifierGroups.isNotEmpty)
                      ..._apiModifierGroups.map((group) {
                        return CustomerProductModifierGroupCard(
                          group: group,
                          selectedToppings: _selectedToppings,
                          onToggleOption: (opt) => _toggleOption(group, opt),
                        );
                      }),

                    if (isBeverage)
                      CustomerProductBeverageOptions(
                        selectedSweetness: _selectedSweetness,
                        selectedIce: _selectedIce,
                        onSweetnessChanged: (val) => setState(() => _selectedSweetness = val),
                        onIceChanged: (val) => setState(() => _selectedIce = val),
                      ),

                    const SizedBox(height: 8),

                    // Quantity Stepper
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jumlah Pesanan',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: p.textPrimary,
                              ),
                            ),
                            Text(
                              'Porsi menu',
                              style: TextStyle(
                                fontSize: 12,
                                color: p.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: p.surfaceMuted,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 18),
                                onPressed: _quantity > 1
                                    ? () => setState(() => _quantity--)
                                    : null,
                                visualDensity: VisualDensity.compact,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  '$_quantity',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 18),
                                onPressed: () => setState(() => _quantity++),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Notes
                    Row(
                      children: [
                        Icon(Icons.edit_note, size: 20, color: primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          'Catatan Khusus',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesCtrl,
                      decoration: InputDecoration(
                        hintText: 'Contoh: sedikit es, pisahkan sirup, jangan terlalu manis...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: p.line,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: p.line,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Sticky Action Bar
              CustomerProductPriceSummaryBar(
                totalPrice: _totalPrice,
                onSubmit: _submit,
              ),
            ],
          ),
        );
      },
    );
  }
}
