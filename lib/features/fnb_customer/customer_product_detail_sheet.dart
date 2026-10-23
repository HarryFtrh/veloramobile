// features/fnb_customer/customer_product_detail_sheet.dart
import 'package:flutter/material.dart';

import '../../core/design/tokens.dart';
import '../fnb/modifiers.dart';
import 'customer_models.dart';
import 'customer_product_price_summary_bar.dart';

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
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: WarmPalette.canvas,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Top Bar with Drag Handle & Close
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: WarmPalette.textPrimary,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: WarmPalette.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.favorite_border_rounded,
                        color: WarmPalette.primary,
                      ),
                      onPressed: () {},
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
                    // Product Image Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 10,
                            child: Image.network(
                              widget.product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: WarmPalette.surfaceMuted,
                                child: const Icon(
                                  Icons.coffee,
                                  size: 64,
                                  color: WarmPalette.primary,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 12,
                            bottom: 12,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.eco_outlined,
                                        size: 14,
                                        color: WarmPalette.tertiary,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Single Origin Blend',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: WarmPalette.tertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: WarmPalette.surfaceMuted
                                        .withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    widget.product.category.isNotEmpty ? widget.product.category : 'Menu Spesial',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: WarmPalette.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Title & Price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.product.name,
                                style: text.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: WarmPalette.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  ...[
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 18,
                                      color: WarmPalette.secondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${widget.product.rating}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: WarmPalette.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      '•',
                                      style: TextStyle(
                                        color: WarmPalette.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: WarmPalette.tertiary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      widget.product.category.toUpperCase(),
                                      style: const TextStyle(
                                        color: WarmPalette.tertiary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (widget.product.badge != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: WarmPalette.secondary
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        widget.product.badge!,
                                        style: const TextStyle(
                                          color: WarmPalette.secondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Rp ${widget.product.basePrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: WarmPalette.primary,
                              ),
                            ),
                            const Text(
                              'Harga Dasar',
                              style: TextStyle(
                                fontSize: 11,
                                color: WarmPalette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.product.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: WarmPalette.textSecondary,
                        height: 1.4,
                      ),
                    ),
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
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  group.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: WarmPalette.textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: WarmPalette.surfaceMuted,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    group.isRequired
                                        ? 'Wajib (${group.maxSelect} maks)'
                                        : 'Opsional (maks ${group.maxSelect})',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: WarmPalette.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...group.options.map((opt) {
                              final isChecked = _selectedToppings.contains(
                                opt.name,
                              );
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isChecked) {
                                      _selectedToppings.remove(opt.name);
                                      _toppingsPrice -= opt.price.round();
                                    } else {
                                      if (group.isSingleChoice) {
                                        for (final o in group.options) {
                                          if (_selectedToppings.contains(
                                            o.name,
                                          )) {
                                            _selectedToppings.remove(o.name);
                                            _toppingsPrice -= o.price.round();
                                          }
                                        }
                                      }
                                      _selectedToppings.add(opt.name);
                                      _toppingsPrice += opt.price.round();
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isChecked
                                          ? WarmPalette.primary
                                          : WarmPalette.line,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: isChecked,
                                        activeColor: WarmPalette.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              if (group.isSingleChoice) {
                                                for (final o in group.options) {
                                                  if (_selectedToppings
                                                      .contains(o.name)) {
                                                    _selectedToppings.remove(
                                                      o.name,
                                                    );
                                                    _toppingsPrice -= o.price
                                                        .round();
                                                  }
                                                }
                                              }
                                              _selectedToppings.add(opt.name);
                                              _toppingsPrice += opt.price
                                                  .round();
                                            } else {
                                              _selectedToppings.remove(
                                                opt.name,
                                              );
                                              _toppingsPrice -= opt.price
                                                  .round();
                                            }
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          opt.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: WarmPalette.textPrimary,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        opt.price > 0
                                            ? '+Rp ${opt.price.round().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}'
                                            : 'Gratis',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: opt.price > 0
                                              ? WarmPalette.secondary
                                              : WarmPalette.tertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 16),
                          ],
                        );
                      }),

                    if ([
                      'coffee',
                      'kopi',
                      'tea',
                      'teh',
                      'beverage',
                      'drink',
                      'minuman',
                    ].any(
                      (k) => widget.product.category.toLowerCase().contains(k),
                    )) ...[
                      // Sweetness Level
                      const Text(
                        'Level Gula / Sweetness',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: WarmPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children:
                            [
                              'Normal (100%)',
                              'Less Sugar (50%)',
                              'No Sugar (0%)',
                            ].map((opt) {
                              final isSel = _selectedSweetness == opt;
                              return ChoiceChip(
                                label: Text(opt),
                                selected: isSel,
                                onSelected: (_) =>
                                    setState(() => _selectedSweetness = opt),
                                selectedColor: WarmPalette.primary,
                                backgroundColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: isSel
                                      ? Colors.white
                                      : WarmPalette.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                shape: const StadiumBorder(),
                                side: BorderSide(
                                  color: isSel
                                      ? Colors.transparent
                                      : WarmPalette.line,
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Ice Level
                      const Text(
                        'Level Es / Suhu',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: WarmPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildIceChip('Normal Ice', Icons.ac_unit_rounded),
                          const SizedBox(width: 8),
                          _buildIceChip('Less Ice', Icons.mode_fan_off_rounded),
                          const SizedBox(width: 8),
                          _buildIceChip('Warm / Hot', Icons.coffee_rounded),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    const SizedBox(height: 8),

                    // Quantity Stepper
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jumlah Pesanan',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: WarmPalette.textPrimary,
                              ),
                            ),
                            Text(
                              'Porsi minuman',
                              style: TextStyle(
                                fontSize: 12,
                                color: WarmPalette.textSecondary,
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
                            color: WarmPalette.surfaceMuted,
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

                    // Barista Note
                    const Row(
                      children: [
                        Icon(
                          Icons.edit_note_rounded,
                          size: 20,
                          color: WarmPalette.primary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Catatan untuk Barista',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: WarmPalette.textPrimary,
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
                          borderSide: const BorderSide(
                            color: WarmPalette.line,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: WarmPalette.line,
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

  Widget _buildIceChip(String label, IconData icon) {
    final isSel = _selectedIce == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIce = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSel ? WarmPalette.primary : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSel ? Colors.transparent : WarmPalette.line,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSel ? Colors.white : WarmPalette.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSel ? Colors.white : WarmPalette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
