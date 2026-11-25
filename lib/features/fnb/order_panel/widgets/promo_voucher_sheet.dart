import 'package:material_ui/material_ui.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/utils/audio_helper.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../billing.dart';
import '../../register/fnb_register_controller.dart';

typedef PromoAndVoucherSheet = FnbDiscountSheet;

/// Lembar modal modern untuk menerapkan Diskon & Promosi Toko (dari API) atau Diskon Manual Kasir.
class FnbDiscountSheet extends StatefulWidget {
  const FnbDiscountSheet({super.key, required this.ctrl});
  final RegisterController ctrl;

  static Future<void> show(BuildContext context, RegisterController ctrl) {
    final isMobile = context.isMobile;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 540,
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.88,
        ),
        child: FnbDiscountSheet(ctrl: ctrl),
      ),
    );
  }

  @override
  State<FnbDiscountSheet> createState() => _FnbDiscountSheetState();
}

class _FnbDiscountSheetState extends State<FnbDiscountSheet> {
  // 0 = Promo Toko (API), 1 = Diskon Manual (Kasir)
  int _activeTabIndex = 0;

  bool _isLoadingPromos = false;
  String? _errorMsg;

  // Manual Discount State
  bool _isPercent = true;
  final _percentCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  double _currentPercent = 0.0;
  double _currentAmount = 0.0;

  static const _percentPresets = [5, 10, 15, 20, 25, 50];

  @override
  void initState() {
    super.initState();
    final ctrl = widget.ctrl;

    // Default selalu buka Tab 0 (Promo Toko dari API)
    _activeTabIndex = 0;

    // Siapkan nilai diskon manual jika kasir beralih ke Tab 1
    if (ctrl.manualDiscountPercent > 0) {
      _isPercent = true;
      _currentPercent = ctrl.manualDiscountPercent;
      _percentCtrl.text = _formatNumber(_currentPercent);
    } else if (ctrl.manualDiscountAmount > 0) {
      _isPercent = false;
      _currentAmount = ctrl.manualDiscountAmount;
      _amountCtrl.text = _currentAmount.toStringAsFixed(0);
    }

    // Selalu sinkronkan promosi toko dari API backend
    _loadDiscounts();
  }

  String _formatNumber(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toString();
  }

  Future<void> _loadDiscounts() async {
    if (_isLoadingPromos) return;
    setState(() {
      _isLoadingPromos = true;
      _errorMsg = null;
    });
    try {
      await widget.ctrl.refreshDiscounts();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingPromos = false);
    }
  }

  @override
  void dispose() {
    _percentCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  List<int> get _amountPresets {
    final sub = widget.ctrl.subtotal.round();
    final base = [5000, 10000, 20000, 50000, 100000];
    return base.where((b) => b < sub).toList();
  }

  double get _calculatedDiscount {
    final sub = widget.ctrl.subtotal.toDouble();
    if (sub <= 0) return 0.0;
    if (_isPercent) {
      return (sub * (_currentPercent / 100)).clamp(0.0, sub);
    } else {
      return _currentAmount.clamp(0.0, sub);
    }
  }

  double get _newSubtotal {
    final sub = widget.ctrl.subtotal.toDouble();
    return (sub - _calculatedDiscount).clamp(0.0, double.infinity);
  }

  void _applyPromo(StorePromotion promo) {
    AudioHelper.actionFeedback();
    if (promo.minOrderAmount > 0 && widget.ctrl.subtotal < promo.minOrderAmount) {
      setState(() {
        _errorMsg = 'Minimal belanja ${CurrencyFormatter.format(promo.minOrderAmount)} untuk "${promo.name}"';
      });
      return;
    }
    widget.ctrl.applyPromotion(promo);
    Navigator.pop(context);
  }

  void _removePromo() {
    AudioHelper.tapFeedback();
    widget.ctrl.removePromotion();
    Navigator.pop(context);
  }

  void _applyManualDiscount() {
    AudioHelper.actionFeedback();
    if (_isPercent) {
      widget.ctrl.applyManualDiscount(percent: _currentPercent, amount: 0);
    } else {
      widget.ctrl.applyManualDiscount(percent: 0, amount: _currentAmount);
    }
    Navigator.pop(context);
  }

  void _removeManualDiscount() {
    AudioHelper.tapFeedback();
    widget.ctrl.removeManualDiscount();
    Navigator.pop(context);
  }

  @override

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final subtotal = widget.ctrl.subtotal.toDouble();
    final promos = widget.ctrl.billing?.activePromotions ?? const [];
    final activePromo = widget.ctrl.activePromotion;
    final hasActiveManual =
        widget.ctrl.manualDiscountPercent > 0 || widget.ctrl.manualDiscountAmount > 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(p, subtotal),
            const SizedBox(height: 14),
            _buildTabSwitcher(p, primaryColor, promos.length),
            const SizedBox(height: 14),
            if (_errorMsg != null) _buildErrorBanner(p),
            if (_activeTabIndex == 0)
              ..._buildStorePromosTab(p, primaryColor, subtotal, promos, activePromo)
            else
              ..._buildManualDiscountTab(p, primaryColor, subtotal, hasActiveManual),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppPalette p, double subtotal) {
    return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.discount_rounded, color: Color(0xFFEF4444), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Diskon & Promosi',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: p.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Subtotal Belanja: ${CurrencyFormatter.format(subtotal)}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: _isLoadingPromos
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Tarik Ulang Promosi dari Server',
                  onPressed: _isLoadingPromos ? null : _loadDiscounts,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Tutup',
                ),
              ],
            );
  }

  Widget _buildTabSwitcher(AppPalette p, Color primaryColor, int promoCount) {
    return Container(
              decoration: BoxDecoration(
                color: p.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.line),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        AudioHelper.tapFeedback();
                        setState(() => _activeTabIndex = 0);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _activeTabIndex == 0 ? p.surface : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _activeTabIndex == 0
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.storefront_rounded,
                              size: 15,
                              color: _activeTabIndex == 0 ? primaryColor : p.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Promo Toko ($promoCount)',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: _activeTabIndex == 0 ? FontWeight.w800 : FontWeight.w600,
                                color: _activeTabIndex == 0 ? p.textPrimary : p.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        AudioHelper.tapFeedback();
                        setState(() => _activeTabIndex = 1);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _activeTabIndex == 1 ? p.surface : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _activeTabIndex == 1
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_note_rounded,
                              size: 16,
                              color: _activeTabIndex == 1 ? primaryColor : p.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Diskon Manual',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: _activeTabIndex == 1 ? FontWeight.w800 : FontWeight.w600,
                                color: _activeTabIndex == 1 ? p.textPrimary : p.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
  }

  Widget _buildErrorBanner(AppPalette p) {
    return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: p.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: p.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, size: 16, color: p.danger),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMsg!, style: TextStyle(color: p.danger, fontSize: 12, fontWeight: FontWeight.w600))),
                  ],
                ),
              );
  }

  List<Widget> _buildStorePromosTab(
    AppPalette p,
    Color primaryColor,
    double subtotal,
    List<StorePromotion> promos,
    StorePromotion? activePromo,
  ) {
    return [
              if (_isLoadingPromos && promos.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                        const SizedBox(height: 10),
                        Text('Menghubungkan ke API promosi toko...', style: TextStyle(fontSize: 12, color: p.textSecondary)),
                      ],
                    ),
                  ),
                )
              else if (promos.isNotEmpty) ...[
                for (final promo in promos) ...[
                  Builder(
                    builder: (ctx) {
                      final isSelected = activePromo?.id == promo.id;
                      final eligible = promo.minOrderAmount <= 0 || subtotal >= promo.minOrderAmount;
                      final discountEst = promo.calculateDiscount(subtotal);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryColor.withValues(alpha: 0.06)
                              : (eligible ? p.surface : p.surfaceMuted),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? primaryColor
                                : (eligible ? primaryColor.withValues(alpha: 0.25) : p.line),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: eligible ? primaryColor.withValues(alpha: 0.1) : p.line,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                promo.type == PromotionType.percentage ? Icons.percent_rounded : Icons.discount_rounded,
                                color: eligible ? primaryColor : p.textTertiary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          promo.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            color: eligible ? p.textPrimary : p.textSecondary,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: eligible ? const Color(0xFF10B981) : p.line,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          promo.type == PromotionType.percentage
                                              ? '${promo.value.round()}% OFF'
                                              : CurrencyFormatter.format(promo.value),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: eligible ? Colors.white : p.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    promo.minOrderAmount > 0
                                        ? 'Min. belanja ${CurrencyFormatter.format(promo.minOrderAmount)}${eligible ? " • Hemat ${CurrencyFormatter.format(discountEst)}" : " (Kurang ${CurrencyFormatter.format(promo.minOrderAmount - subtotal)})"}'
                                        : 'Tanpa min. belanja • Hemat ${CurrencyFormatter.format(discountEst)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: eligible ? p.textSecondary : p.danger,
                                      fontWeight: eligible ? FontWeight.w500 : FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isSelected)
                              OutlinedButton(
                                onPressed: _removePromo,
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  foregroundColor: p.danger,
                                  side: BorderSide(color: p.danger),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                child: const Text('Batal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                              )
                            else
                              FilledButton.tonal(
                                onPressed: eligible ? () => _applyPromo(promo) : null,
                                style: FilledButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                child: const Text('Pakai', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: p.surfaceMuted,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.line),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.discount_outlined, size: 28, color: p.textTertiary),
                      const SizedBox(height: 8),
                      Text(
                        'Belum Ada Promosi Server Aktif',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: p.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tidak ditemukan daftar promosi dari API toko. Anda dapat mengatur diskon transaksi manual di tab sebelah.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11.5, color: p.textSecondary, height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          AudioHelper.tapFeedback();
                          setState(() => _activeTabIndex = 1);
                        },
                        icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                        label: const Text('Buka Diskon Manual Kasir', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor.withValues(alpha: 0.4)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
    ];
  }

  List<Widget> _buildManualDiscountTab(
    AppPalette p,
    Color primaryColor,
    double subtotal,
    bool hasActiveManual,
  ) {
    return [
              // Sub-selector Persen vs Nominal
              Container(
                decoration: BoxDecoration(
                  color: p.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.line),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          AudioHelper.tapFeedback();
                          setState(() => _isPercent = true);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: _isPercent ? p.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Persen (%)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _isPercent ? FontWeight.w800 : FontWeight.w600,
                                color: _isPercent ? primaryColor : p.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          AudioHelper.tapFeedback();
                          setState(() => _isPercent = false);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: !_isPercent ? p.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Nominal (Rp)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: !_isPercent ? FontWeight.w800 : FontWeight.w600,
                                color: !_isPercent ? primaryColor : p.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              if (_isPercent) ...[
                // Preset Chips Persen
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final pVal in _percentPresets)
                      ChoiceChip(
                        label: Text('$pVal%', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        selected: _currentPercent == pVal,
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        selectedColor: primaryColor.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: _currentPercent == pVal ? primaryColor : p.textSecondary,
                        ),
                        side: BorderSide(color: _currentPercent == pVal ? primaryColor : p.line),
                        onSelected: (_) {
                          AudioHelper.tapFeedback();
                          setState(() {
                            _currentPercent = pVal.toDouble();
                            _percentCtrl.text = pVal.toString();
                          });
                        },
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: _percentCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  decoration: InputDecoration(
                    labelText: 'Ketik Persentase Diskon',
                    hintText: 'Contoh: 15',
                    suffixText: '%',
                    suffixStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.textPrimary),
                    filled: true,
                    fillColor: p.surfaceMuted,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.line)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.line)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (v) {
                    final parsed = double.tryParse(v.trim().replaceAll(',', '.')) ?? 0.0;
                    setState(() {
                      _currentPercent = parsed.clamp(0.0, 100.0);
                    });
                  },
                ),
              ] else ...[
                // Preset Chips Nominal
                if (_amountPresets.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final aVal in _amountPresets)
                        ChoiceChip(
                          label: Text(CurrencyFormatter.format(aVal), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                          selected: _currentAmount == aVal,
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          selectedColor: primaryColor.withValues(alpha: 0.15),
                          labelStyle: TextStyle(color: _currentAmount == aVal ? primaryColor : p.textSecondary),
                          side: BorderSide(color: _currentAmount == aVal ? primaryColor : p.line),
                          onSelected: (_) {
                            AudioHelper.tapFeedback();
                            setState(() {
                              _currentAmount = aVal.toDouble();
                              _amountCtrl.text = aVal.toString();
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  decoration: InputDecoration(
                    labelText: 'Ketik Potongan Rupiah',
                    prefixText: 'Rp ',
                    prefixStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.textPrimary),
                    filled: true,
                    fillColor: p.surfaceMuted,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.line)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.line)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (v) {
                    final clean = v.replaceAll('.', '').replaceAll(',', '').replaceAll(' ', '');
                    final parsed = double.tryParse(clean) ?? 0.0;
                    setState(() {
                      _currentAmount = parsed.clamp(0.0, subtotal);
                    });
                  },
                ),
              ],

              const SizedBox(height: 14),

              // Preview Box Diskon Manual
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.line),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal', style: TextStyle(fontSize: 12, color: p.textSecondary)),
                        Text(CurrencyFormatter.format(subtotal), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Potongan Diskon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                        Text('-${CurrencyFormatter.format(_calculatedDiscount)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFEF4444))),
                      ],
                    ),
                    const Divider(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Baru', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: p.textPrimary)),
                        Text(CurrencyFormatter.format(_newSubtotal), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: primaryColor)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  if (hasActiveManual) ...[
                    OutlinedButton.icon(
                      onPressed: _removeManualDiscount,
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _calculatedDiscount > 0 ? _applyManualDiscount : null,
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: const Text(
                        'Terapkan Diskon',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
    ];
  }
}
