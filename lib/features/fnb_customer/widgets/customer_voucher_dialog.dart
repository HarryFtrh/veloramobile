// features/fnb_customer/widgets/customer_voucher_dialog.dart
import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../../fnb/billing.dart';

class PromoApplicationResult {
  const PromoApplicationResult({
    required this.code,
    required this.discount,
    required this.name,
  });

  final String code;
  final int discount;
  final String name;
}

class CustomerVoucherPromoDialog extends StatefulWidget {
  const CustomerVoucherPromoDialog({
    super.key,
    this.billing,
    required this.subtotal,
  });

  final BillingSettings? billing;
  final num subtotal;

  @override
  State<CustomerVoucherPromoDialog> createState() =>
      _CustomerVoucherPromoDialogState();
}

class _CustomerVoucherPromoDialogState
    extends State<CustomerVoucherPromoDialog> {
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
        _errorMsg =
            'Minimal belanja Rp ${promo.minOrderAmount.toInt()} untuk promo "${promo.name}"';
      });
      return;
    }
    final discount = promo.calculateDiscount(widget.subtotal).round();
    Navigator.pop(
      context,
      PromoApplicationResult(
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
          _errorMsg =
              'Minimal belanja Rp ${promo.minOrderAmount.toInt()} untuk voucher ini';
        });
        return;
      }
      final disc = promo.calculateDiscount(widget.subtotal).round();
      Navigator.pop(
        context,
        PromoApplicationResult(code: code, discount: disc, name: promo.name),
      );
      return;
    }

    // Try online verification via backend API
    setState(() {
      _isVerifying = true;
      _errorMsg = null;
    });

    try {
      final remote = await BillingSettings.verifyVoucherCodeApi(
        code,
        widget.subtotal.toDouble(),
      );
      if (!mounted) return;
      if (remote != null) {
        final disc =
            remote.calculateDiscount(widget.subtotal.toDouble()).round();
        Navigator.pop(
          context,
          PromoApplicationResult(
            code: code,
            discount: disc,
            name: remote.name,
          ),
        );
        return;
      }
      setState(() {
        _errorMsg =
            'Kode promo "$code" tidak ditemukan atau sudah tidak aktif';
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
            child: Text(
              'Voucher & Promo Toko',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
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
                child: Text(
                  _errorMsg!,
                  style: const TextStyle(
                    color: WarmPalette.danger,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            TextField(
              controller: _codeCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Kode Promo',
                hintText: 'Mis. DISKON10',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            if (promos.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Promo Tersedia:',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: WarmPalette.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              for (final promo in promos) ...[
                Builder(
                  builder: (ctx) {
                    final eligible = promo.minOrderAmount <= 0 ||
                        subtotal >= promo.minOrderAmount;
                    final disc = promo.calculateDiscount(subtotal).round();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: eligible
                            ? WarmPalette.surface
                            : WarmPalette.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: eligible
                              ? WarmPalette.primary.withValues(alpha: 0.3)
                              : WarmPalette.line,
                        ),
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
                                    color: eligible
                                        ? WarmPalette.textPrimary
                                        : WarmPalette.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  promo.minOrderAmount > 0
                                      ? 'Min. Rp ${promo.minOrderAmount.toInt()}${eligible ? " • Hemat Rp $disc" : " (Kurang Rp ${(promo.minOrderAmount - subtotal).toInt()})"}'
                                      : 'Hemat Rp $disc',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: eligible
                                        ? WarmPalette.textSecondary
                                        : WarmPalette.danger,
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                            child: const Text(
                              'Pakai',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
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
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Terapkan'),
        ),
      ],
    );
  }
}
