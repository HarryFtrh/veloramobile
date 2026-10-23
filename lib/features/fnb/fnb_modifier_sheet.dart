import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';
import '../../core/utils/currency_formatter.dart';
import '../shared_pos/product_catalog_service.dart';
import 'modifiers.dart';

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
                  color: WarmPalette.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          widget.product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.coffee_rounded,
                            color: WarmPalette.primary,
                            size: 24,
                          ),
                        ),
                      )
                    : const Icon(Icons.coffee_rounded, color: WarmPalette.primary, size: 24),
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
                        color: WarmPalette.textPrimary,
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
                            color: WarmPalette.primary,
                          ),
                        ),
                        if (widget.product.category.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: WarmPalette.surfaceMuted,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: WarmPalette.line),
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
                icon: const Icon(Icons.close_rounded, color: WarmPalette.textSecondary, size: 22),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Tutup',
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: WarmPalette.line),

        // Scrollable Groups, Tiles, Quantity & Barista Note
        Flexible(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: paddingHoriz, vertical: 14),
            shrinkWrap: true,
            children: [
              for (int gi = 0; gi < widget.groups.length; gi++) ...[
                _buildGroupSection(context, widget.groups[gi]),
                const SizedBox(height: 16),
              ],

              // Divider pemisah sebelum kontrol porsi & catatan
              const Divider(color: WarmPalette.line, height: 24),

              // Kontrol Porsi (Quantity)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jumlah Porsi',
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: WarmPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tentukan banyak porsi dengan varian ini',
                          style: TextStyle(fontSize: 11, color: p.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: WarmPalette.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: WarmPalette.line),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          color: _quantity > 1 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                          child: InkWell(
                            onTap: _quantity > 1 ? _decrementQty : null,
                            borderRadius: BorderRadius.circular(7),
                            child: Padding(
                              padding: const EdgeInsets.all(7),
                              child: Icon(
                                Icons.remove_rounded,
                                size: 18,
                                color: _quantity > 1 ? WarmPalette.textPrimary : WarmPalette.textTertiary,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            '$_quantity',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: WarmPalette.textPrimary,
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(7),
                          child: InkWell(
                            onTap: _incrementQty,
                            borderRadius: BorderRadius.circular(7),
                            child: const Padding(
                              padding: EdgeInsets.all(7),
                              child: Icon(
                                Icons.add_rounded,
                                size: 18,
                                color: WarmPalette.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Catatan Barista / Dapur
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_note_rounded, size: 18, color: WarmPalette.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Catatan Barista / Dapur',
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: WarmPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(Opsional)',
                        style: TextStyle(fontSize: 11, color: p.textTertiary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteCtrl,
                    maxLines: 2,
                    minLines: 1,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Mis: Pisah sirup, es sedikit, less sugar...',
                      hintStyle: TextStyle(fontSize: 12, color: p.textTertiary),
                      filled: true,
                      fillColor: WarmPalette.surfaceMuted,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: WarmPalette.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: WarmPalette.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: WarmPalette.primary, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),

        // Sticky Footer: Total & Tombol Tambah
        const Divider(height: 1, color: WarmPalette.line),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              paddingHoriz,
              10,
              paddingHoriz,
              12 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_valid)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline_rounded, size: 15, color: WarmPalette.danger),
                        SizedBox(width: 6),
                        Text(
                          'Lengkapi pilihan varian wajib di atas',
                          style: TextStyle(fontSize: 11.5, color: WarmPalette.danger, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _valid ? _submit : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: WarmPalette.primary,
                      disabledBackgroundColor: WarmPalette.line,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _quantity > 1 ? 'Tambah ke Pesanan ($_quantity porsi)' : 'Tambah ke Pesanan',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
                        ),
                        Text(
                          CurrencyFormatter.format(grandTotal),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupSection(BuildContext context, ModifierGroup g) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final selectedCount = _of(g).length;
    final isSatisfied = selectedCount >= g.requiredCount;
    final isRequired = g.requiredCount > 0;

    String badgeText;
    if (isRequired) {
      badgeText = g.isSingleChoice ? 'Wajib · Pilih 1' : 'Wajib · Min ${g.requiredCount}';
    } else {
      badgeText = g.isSingleChoice ? 'Opsional · Pilih 1' : 'Opsional · Maks ${g.maxSelect}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                g.name,
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: WarmPalette.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: isRequired && !isSatisfied
                    ? WarmPalette.danger.withValues(alpha: 0.1)
                    : WarmPalette.surfaceMuted,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isRequired && !isSatisfied
                      ? WarmPalette.danger.withValues(alpha: 0.4)
                      : WarmPalette.line,
                ),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isRequired && !isSatisfied ? WarmPalette.danger : p.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Modern Card-Tiles
        LayoutBuilder(
          builder: (context, constraints) {
            // Jika lebar mencukupi (misal > 360), tampilkan 2 kolom tile, jika kecil 1 kolom
            final useTwoCols = constraints.maxWidth >= 380;
            if (useTwoCols) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final o in g.options)
                    SizedBox(
                      width: (constraints.maxWidth - 8) / 2,
                      child: _buildModifierCardTile(g, o),
                    ),
                ],
              );
            }

            return Column(
              children: [
                for (int oi = 0; oi < g.options.length; oi++) ...[
                  _buildModifierCardTile(g, g.options[oi]),
                  if (oi < g.options.length - 1) const SizedBox(height: 6),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildModifierCardTile(ModifierGroup g, ModifierOption o) {
    final isSelected = _of(g).contains(o.id);
    final hasPrice = o.price > 0;

    return Material(
      color: isSelected ? WarmPalette.primary.withValues(alpha: 0.07) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? WarmPalette.primary : WarmPalette.line,
          width: isSelected ? 1.6 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () => _toggle(g, o),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              // Selection Indicator (Radio circle for single, checkbox for multi)
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: g.isSingleChoice ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: g.isSingleChoice ? null : BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected ? WarmPalette.primary : WarmPalette.textTertiary,
                    width: isSelected ? 2 : 1.4,
                  ),
                  color: isSelected
                      ? (g.isSingleChoice ? Colors.transparent : WarmPalette.primary)
                      : Colors.transparent,
                ),
                child: isSelected
                    ? (g.isSingleChoice
                        ? Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: WarmPalette.primary,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.check_rounded,
                            size: 13,
                            color: Colors.white,
                          ))
                    : null,
              ),
              const SizedBox(width: 8),

              // Option Name
              Expanded(
                child: Text(
                  o.name,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? WarmPalette.primary : WarmPalette.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Price badge if any
              if (hasPrice) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? WarmPalette.primary.withValues(alpha: 0.15)
                        : WarmPalette.surfaceMuted,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '+${CurrencyFormatter.format(o.price)}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? WarmPalette.primary : WarmPalette.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
