import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../shared_pos/product_catalog_service.dart';
import '../modifiers.dart';
import 'modifier/fnb_modifier_action_footer.dart';
import 'modifier/fnb_modifier_group_section.dart';
import 'modifier/fnb_modifier_quantity_bar.dart';

export 'modifier/fnb_modifier_action_footer.dart';
export 'modifier/fnb_modifier_card_tile.dart';
export 'modifier/fnb_modifier_group_section.dart';
export 'modifier/fnb_modifier_quantity_bar.dart';

/// Hasil pemilihan modifier dari [FnbModifierSheet].
class FnbModifierSelection {
  const FnbModifierSelection({
    required this.options,
    this.quantity = 1,
    this.note,
  });

  final List<ModifierOption> options;
  final int quantity;
  final String? note;
}

/// Modal bottom sheet untuk memilih varian modifier produk (misal level gula, opsi susu, topping).
/// Menggunakan antarmuka Modern F&B Card-Tiles yang ramah sentuhan (touch-friendly),
/// dilengkapi kontrol porsi dan input catatan barista/dapur.
class FnbModifierSheet extends StatefulWidget {
  const FnbModifierSheet({
    super.key,
    required this.product,
    required this.groups,
  });

  final PosProduct product;
  final List<ModifierGroup> groups;

  /// Helper untuk menampilkan sheet secara standar di kasir F&B.
  static Future<FnbModifierSelection?> show({
    required BuildContext context,
    required PosProduct product,
    required List<ModifierGroup> groups,
  }) {
    final isMobile = context.isMobile;
    return showModalBottomSheet<FnbModifierSelection>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 600,
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.88,
        ),
        child: FnbModifierSheet(product: product, groups: groups),
      ),
    );
  }

  @override
  State<FnbModifierSheet> createState() => _FnbModifierSheetState();
}

class _FnbModifierSheetState extends State<FnbModifierSheet> {
  final Map<String, Set<String>> _selected = {};
  final TextEditingController _noteCtrl = TextEditingController();
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    // Default seleksi otomatis jika grup wajib single-choice memiliki 1 opsi saja
    for (final g in widget.groups) {
      if (g.requiredCount == 1 && g.isSingleChoice && g.options.length == 1) {
        _of(g).add(g.options.first.id);
      }
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Set<String> _of(ModifierGroup g) =>
      _selected.putIfAbsent(g.id, () => <String>{});

  bool get _valid =>
      widget.groups.every((g) => _of(g).length >= g.requiredCount);

  List<ModifierOption> get _picked => [
        for (final g in widget.groups)
          for (final o in g.options)
            if (_of(g).contains(o.id)) o,
      ];

  num get _extra => _picked.fold<num>(0, (s, o) => s + o.price);

  void _toggle(ModifierGroup g, ModifierOption o) {
    setState(() {
      final set = _of(g);
      if (g.isSingleChoice) {
        if (set.contains(o.id)) {
          if (g.requiredCount == 0) set.clear();
        } else {
          set
            ..clear()
            ..add(o.id);
        }
      } else if (set.contains(o.id)) {
        set.remove(o.id);
      } else if (set.length < g.maxSelect) {
        set.add(o.id);
      }
    });
  }

  void _incrementQty() {
    setState(() => _quantity++);
  }

  void _decrementQty() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  void _submit() {
    if (!_valid) return;
    final note = _noteCtrl.text.trim();
    Navigator.pop(
      context,
      FnbModifierSelection(
        options: _picked,
        quantity: _quantity,
        note: note.isNotEmpty ? note : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final text = Theme.of(context).textTheme;
    final isMobile = context.isMobile;
    final paddingHoriz = isMobile ? 16.0 : 20.0;
    final unitTotal = widget.product.price + _extra;
    final grandTotal = unitTotal * _quantity;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header Sheet
        Padding(
          padding: EdgeInsets.fromLTRB(paddingHoriz, 4, isMobile ? 8 : paddingHoriz, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: p.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          widget.product.imageUrl!,
                          fit: BoxFit.cover,
                          cacheWidth: 320,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.coffee_rounded,
                            color: primaryColor,
                            size: 24,
                          ),
                        ),
                      )
                    : Icon(Icons.coffee_rounded, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: isMobile ? 15 : 17,
                        color: p.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          CurrencyFormatter.format(widget.product.price),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: primaryColor,
                          ),
                        ),
                        if (widget.product.category.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: p.surfaceMuted,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: p.line),
                            ),
                            child: Text(
                              widget.product.category,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: p.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: p.textSecondary, size: 22),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Tutup',
              ),
            ],
          ),
        ),
        Divider(height: 1, color: p.line),

        // Scrollable Groups, Tiles, Quantity & Barista Note
        Flexible(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: paddingHoriz, vertical: 14),
            shrinkWrap: true,
            children: [
              for (int gi = 0; gi < widget.groups.length; gi++) ...[
                FnbModifierGroupSection(
                  group: widget.groups[gi],
                  selectedOptionIds: _of(widget.groups[gi]),
                  onToggle: (opt) => _toggle(widget.groups[gi], opt),
                ),
                const SizedBox(height: 16),
              ],

              // Divider pemisah sebelum kontrol porsi & catatan
              Divider(color: p.line, height: 24),

              // Portion & Kitchen Note
              FnbModifierQuantityBar(
                quantity: _quantity,
                noteCtrl: _noteCtrl,
                onIncrement: _incrementQty,
                onDecrement: _decrementQty,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),

        // Sticky Footer: Total & Tombol Tambah
        FnbModifierActionFooter(
          isValid: _valid,
          quantity: _quantity,
          grandTotal: grandTotal,
          horizontalPadding: paddingHoriz,
          onSubmit: _submit,
        ),
      ],
    );
  }
}
