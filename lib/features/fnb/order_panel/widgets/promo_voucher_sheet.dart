import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../billing.dart';
import '../../fnb_register_controller.dart';

/// Bottom sheet for selecting active store promotions, inputting voucher codes,
/// or applying custom cashier discount percentages/amounts.
class PromoAndVoucherSheet extends StatefulWidget {
  const PromoAndVoucherSheet({super.key, required this.ctrl});
  final RegisterController ctrl;

  @override
  State<PromoAndVoucherSheet> createState() => _PromoAndVoucherSheetState();
}

class _PromoAndVoucherSheetState extends State<PromoAndVoucherSheet> {
  final _codeCtrl = TextEditingController();
  final _customAmountCtrl = TextEditingController();
  final _customPercentCtrl = TextEditingController();
  String? _errorMsg;
  bool _showCustom = false;
  bool _isVerifying = false;
  bool _isLoadingPromos = false;

  @override
  void initState() {
    super.initState();
    if ((widget.ctrl.billing?.activePromotions.isEmpty ?? true)) {
      _loadDiscounts();
    }
  }

  Future<void> _loadDiscounts() async {
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
    _codeCtrl.dispose();
    _customAmountCtrl.dispose();
    _customPercentCtrl.dispose();
    super.dispose();
  }

  void _applyPromo(StorePromotion promo) {
    if (promo.minOrderAmount > 0 && widget.ctrl.subtotal < promo.minOrderAmount) {
      setState(() {
        _errorMsg = 'Minimal transaksi ${CurrencyFormatter.format(promo.minOrderAmount)} untuk promo "${promo.name}"';
      });
      return;
    }
    widget.ctrl.applyPromotion(promo);
    Navigator.pop(context);
  }

  Future<void> _applyCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _isVerifying = true;
      _errorMsg = null;
    });
    try {
      final applied = await widget.ctrl.applyVoucherCode(code);
      if (applied) {
        if (mounted) Navigator.pop(context);
      } else {
        if (mounted) {
          setState(() {
            _errorMsg = 'Kode voucher "$code" tidak ditemukan atau sudah tidak aktif';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = ApiException.from(e).message;
        });
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _applyCustomNominal() {
    final amt = double.tryParse(_customAmountCtrl.text.trim()) ?? 0.0;
    if (amt <= 0) return;
    widget.ctrl.applyVoucher('MANUAL', amt);
    Navigator.pop(context);
  }

  void _applyCustomPercent() {
    final pct = double.tryParse(_customPercentCtrl.text.trim()) ?? 0.0;
    if (pct <= 0) return;
    final maxPct = widget.ctrl.billing?.maxDiscountPercent ?? 100.0;
    if (pct > maxPct) {
      setState(() {
        _errorMsg = 'Maksimal diskon kasir adalah ${maxPct.round()}%';
      });
      return;
    }
    final amt = (widget.ctrl.subtotal * (pct / 100)).toDouble();
    widget.ctrl.applyVoucher('MANUAL ${pct.round()}%', amt);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final b = widget.ctrl.billing;
    final promos = b?.activePromotions ?? const [];
    final subtotal = widget.ctrl.subtotal;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Diskon & Promosi Toko', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 18)),
                ),
                IconButton(
                  icon: _isLoadingPromos
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Tarik ulang diskon & promosi',
                  onPressed: _isLoadingPromos ? null : _loadDiscounts,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_errorMsg != null)
              Container(
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
              ),

            // Input kode promo opsional
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'Kode promo toko (opsional)',
                      prefixIcon: Icon(Icons.tag_rounded, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _applyCode(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isVerifying ? null : _applyCode,
                  child: _isVerifying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Gunakan'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (_isLoadingPromos && promos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(strokeWidth: 2),
                      SizedBox(height: 10),
                      Text('Menarik data diskon & promosi dari server...', style: TextStyle(fontSize: 12, color: WarmPalette.textSecondary)),
                    ],
                  ),
                ),
              ),

            // Daftar promosi dari sistem preferensi
            if (promos.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Promosi Aktif (${promos.length})',
                    style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: p.textSecondary),
                  ),
                  if (_isLoadingPromos)
                    const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.8)),
                ],
              ),
              const SizedBox(height: 8),
              for (final promo in promos) ...[
                Builder(
                  builder: (ctx) {
                    final eligible = promo.minOrderAmount <= 0 || subtotal >= promo.minOrderAmount;
                    final discountEst = promo.calculateDiscount(subtotal);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: eligible ? p.surface : p.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: eligible ? p.primary.withValues(alpha: 0.3) : p.line,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: eligible ? p.primary.withValues(alpha: 0.1) : p.line,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              promo.type == PromotionType.percentage ? Icons.percent_rounded : Icons.discount_outlined,
                              color: eligible ? p.primary : p.textTertiary,
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
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: eligible ? p.textPrimary : p.textSecondary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: eligible ? WarmPalette.tertiary : p.line,
                                        borderRadius: BorderRadius.circular(4),
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
                                const SizedBox(height: 2),
                                Text(
                                  promo.minOrderAmount > 0
                                      ? 'Min. transaksi ${CurrencyFormatter.format(promo.minOrderAmount)}${eligible ? " • Hemat ${CurrencyFormatter.format(discountEst)}" : " (Kurang ${CurrencyFormatter.format(promo.minOrderAmount - subtotal)})"}'
                                      : 'Tanpa min. transaksi • Hemat ${CurrencyFormatter.format(discountEst)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: eligible ? p.textSecondary : p.danger,
                                    fontWeight: eligible ? FontWeight.normal : FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
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
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: p.line),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: p.textTertiary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tidak ada promosi toko aktif saat ini. Anda tetap dapat memasukkan kode voucher atau diskon manual.',
                        style: TextStyle(fontSize: 12, color: p.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Diskon Kustom Kasir
            if (b?.allowCustomDiscount == true) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => setState(() => _showCustom = !_showCustom),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(_showCustom ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 18, color: p.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Diskon Manual Kasir (Maks. ${(b?.maxDiscountPercent ?? 100).round()}%)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showCustom) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customAmountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Potongan (Rp)',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: _applyCustomNominal,
                      child: const Text('Terapkan Rp'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customPercentCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Potongan (%)',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: _applyCustomPercent,
                      child: const Text('Terapkan %'),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
