import 'package:flutter/material.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/audio_helper.dart';
import '../../../shared_pos/pos_checkout_service.dart';
import '../../services/pharmacy_clinical_safety_service.dart';

/// View Tender Pembayaran In-Place di Sisi Keranjang Apotek
class PharmacyCartTenderView extends StatefulWidget {
  final num grandTotal;
  final int totalQty;
  final String selectedPatient;
  final String queueNumber;
  final String patientAllergies;
  final List<PosCartItem> cartItems;
  final VoidCallback onBackToCart;
  final VoidCallback onOpenEtiket;
  final Function(num amount) onOpenCustomerDisplay;
  final VoidCallback onOpenFullCheckout;
  final Function({
    required int paymentMethodIndex,
    required String paymentMethodName,
    required num tenderAmount,
    required num changeAmount,
    required String bankOrInsurance,
    required String refOrSepCode,
    required bool autoPrintReceipt,
  }) onProcessSettlement;

  const PharmacyCartTenderView({
    super.key,
    required this.grandTotal,
    required this.totalQty,
    required this.selectedPatient,
    required this.queueNumber,
    required this.patientAllergies,
    required this.cartItems,
    required this.onBackToCart,
    required this.onOpenEtiket,
    required this.onOpenCustomerDisplay,
    required this.onOpenFullCheckout,
    required this.onProcessSettlement,
  });

  @override
  State<PharmacyCartTenderView> createState() => _PharmacyCartTenderViewState();
}

class _PharmacyCartTenderViewState extends State<PharmacyCartTenderView> {
  static const primaryEmerald = Color(0xFF059669);
  static const secondaryTeal = Color(0xFF0D9488);
  static const borderColor = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const canvasColor = Colors.white;

  int _selectedPaymentMethod = 0;
  num _tenderAmount = 0;
  num _splitCashAmount = 0;
  String _splitSecondaryMethod = 'QRIS Dinamis';
  String _selectedBank = 'BCA';
  String _selectedInsurance = 'BPJS Kesehatan';
  bool _autoPrintReceipt = true;
  bool _isClinicalReviewAcknowledged = false;
  bool _isProcessing = false;

  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _splitCashController = TextEditingController();
  final TextEditingController _refCodeController = TextEditingController();
  final TextEditingController _sepNumberController = TextEditingController();

  static const _paymentMethods = [
    {'name': 'Tunai', 'icon': Icons.payments_outlined},
    {'name': 'QRIS', 'icon': Icons.qr_code_2_rounded},
    {'name': 'Debit/EDC', 'icon': Icons.credit_card_rounded},
    {'name': 'BPJS/Asuransi', 'icon': Icons.health_and_safety_rounded},
    {'name': 'Split Bill', 'icon': Icons.call_split_rounded},
  ];

  static const _bankList = ['BCA', 'Mandiri', 'BRI', 'BNI', 'BSI'];
  static const _insuranceList = ['BPJS Kesehatan', 'Prudential', 'Allianz', 'AdMedika', 'Inhealth'];

  @override
  void initState() {
    super.initState();
    _tenderAmount = widget.grandTotal;
    _cashController.text = CurrencyFormatter.formatRupiah(widget.grandTotal).replaceAll('Rp', '').trim();
  }

  @override
  void dispose() {
    _cashController.dispose();
    _splitCashController.dispose();
    _refCodeController.dispose();
    _sepNumberController.dispose();
    super.dispose();
  }

  void _onCashTextChanged(String val) {
    final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
    final num amt = num.tryParse(clean) ?? 0;
    setState(() => _tenderAmount = amt);
  }

  void _onCashPresetSelected(num amt) {
    AudioHelper.tapFeedback();
    setState(() {
      _tenderAmount = amt;
      _cashController.text = CurrencyFormatter.formatRupiah(amt).replaceAll('Rp', '').trim();
    });
  }

  Future<void> _handleSettlement() async {
    final num changeAmount = (_tenderAmount >= widget.grandTotal) ? (_tenderAmount - widget.grandTotal) : 0;
    final methodName = _paymentMethods[_selectedPaymentMethod]['name'] as String;

    String bankOrIns = '-';
    String refOrSep = '-';

    if (_selectedPaymentMethod == 2) {
      bankOrIns = _selectedBank;
      refOrSep = _refCodeController.text.trim();
    } else if (_selectedPaymentMethod == 3) {
      bankOrIns = _selectedInsurance;
      refOrSep = _sepNumberController.text.trim();
    } else if (_selectedPaymentMethod == 4) {
      bankOrIns = _splitSecondaryMethod;
      refOrSep = 'Tunai: ${_splitCashController.text}';
    }

    setState(() => _isProcessing = true);

    try {
      await widget.onProcessSettlement(
        paymentMethodIndex: _selectedPaymentMethod,
        paymentMethodName: methodName,
        tenderAmount: _tenderAmount,
        changeAmount: changeAmount,
        bankOrInsurance: bankOrIns,
        refOrSepCode: refOrSep,
        autoPrintReceipt: _autoPrintReceipt,
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final num grandTotal = widget.grandTotal;
    final num changeAmount = (_tenderAmount >= grandTotal) ? (_tenderAmount - grandTotal) : 0;
    final num shortAmount = (_tenderAmount < grandTotal) ? (grandTotal - _tenderAmount) : 0;
    final num secondarySplitAmount = (grandTotal > _splitCashAmount) ? (grandTotal - _splitCashAmount) : 0;

    final safetyAlerts = PharmacyClinicalSafetyService.instance.checkCartSafety(
      items: widget.cartItems,
      patientAllergies: widget.patientAllergies,
    );

    final cashPresets = <num>{
      grandTotal,
      (grandTotal / 10000).ceil() * 10000,
      50000,
      100000,
      200000,
      500000,
    }.where((amt) => amt >= grandTotal).toList();

    return Column(
      key: const ValueKey('TenderPaymentView'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Back to Cart Arrow & Fast Actions
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: const BoxDecoration(
            color: canvasColor,
            border: Border(bottom: BorderSide(color: borderColor, width: 1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 20, color: textPrimary),
                      tooltip: 'Kembali ke Item Keranjang',
                      onPressed: widget.onBackToCart,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Tender Pembayaran',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Pasien: ${widget.selectedPatient} (${widget.queueNumber})',
                            style: const TextStyle(fontSize: 10.5, color: textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.label_important_rounded, size: 18, color: primaryEmerald),
                    tooltip: 'Etiket Obat (Signa)',
                    onPressed: widget.onOpenEtiket,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.tv_rounded, size: 18, color: secondaryTeal),
                    tooltip: 'Layar Pasien QRIS',
                    onPressed: () => widget.onOpenCustomerDisplay(grandTotal),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.open_in_full_rounded, size: 16, color: textMuted),
                    tooltip: 'Mode Layar Penuh Dual-Pane',
                    onPressed: widget.onOpenFullCheckout,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Scrollable Tender Form
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Grand Total Mini Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: primaryEmerald.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: primaryEmerald.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL TAGIHAN RESEP',
                            style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 9.5, fontWeight: FontWeight.bold, color: textMuted),
                          ),
                          Text(
                            CurrencyFormatter.formatRupiah(grandTotal),
                            style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 18, fontWeight: FontWeight.w900, color: primaryEmerald),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          '${widget.totalQty} Item Obat',
                          style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: FontWeight.bold, color: primaryEmerald),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Clinical Safety Alert (if any)
                if (safetyAlerts.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.warning_amber_rounded, size: 16, color: ClinicalPalette.danger),
                            SizedBox(width: 6),
                            Text(
                              'Peringatan Alergi / Interaksi Obat Terdeteksi',
                              style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 11, color: ClinicalPalette.danger),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          safetyAlerts.first.message,
                          style: const TextStyle(fontSize: 10, color: Color(0xFF7F1D1D)),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => setState(() => _isClinicalReviewAcknowledged = !_isClinicalReviewAcknowledged),
                          child: Row(
                            children: [
                              SizedBox(
                                height: 18,
                                width: 18,
                                child: Checkbox(
                                  value: _isClinicalReviewAcknowledged,
                                  activeColor: primaryEmerald,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (v) => setState(() => _isClinicalReviewAcknowledged = v ?? false),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text('Telaah Apoteker: Verifikasi Aman', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: textPrimary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Payment Method Selector Tabs
                const Text('Pilih Metode Pembayaran:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textPrimary)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(_paymentMethods.length, (idx) {
                    final isSel = _selectedPaymentMethod == idx;
                    final m = _paymentMethods[idx];
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(m['icon'] as IconData, size: 13, color: isSel ? Colors.white : textMuted),
                          const SizedBox(width: 4),
                          Text(m['name'] as String),
                        ],
                      ),
                      selected: isSel,
                      selectedColor: primaryEmerald,
                      backgroundColor: const Color(0xFFF1F5F9),
                      labelStyle: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: isSel ? Colors.white : textPrimary,
                      ),
                      onSelected: (val) {
                        if (val) {
                          AudioHelper.tapFeedback();
                          setState(() {
                            _selectedPaymentMethod = idx;
                            if (idx != 0) _tenderAmount = grandTotal;
                          });
                        }
                      },
                    );
                  }),
                ),
                const SizedBox(height: 12),

                // Form Section per Payment Method
                if (_selectedPaymentMethod == 0) ...[
                  // TUNAI
                  const Text('Uang Tunai Diterima:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textPrimary)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _cashController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 16, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: _onCashTextChanged,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: cashPresets.map((amt) {
                      final isExact = amt == grandTotal;
                      final isSel = _tenderAmount == amt;
                      return InkWell(
                        onTap: () => _onCashPresetSelected(amt),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSel ? primaryEmerald : (isExact ? primaryEmerald.withValues(alpha: 0.1) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: isSel ? primaryEmerald : borderColor),
                          ),
                          child: Text(
                            isExact ? 'Uang Pas' : CurrencyFormatter.formatRupiah(amt),
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: isSel ? Colors.white : (isExact ? primaryEmerald : textPrimary),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  // Kembalian Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: shortAmount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: shortAmount > 0 ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          shortAmount > 0 ? 'Uang Kurang:' : 'Kembalian:',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                            color: shortAmount > 0 ? ClinicalPalette.danger : primaryEmerald,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatRupiah(shortAmount > 0 ? shortAmount : changeAmount),
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: shortAmount > 0 ? ClinicalPalette.danger : primaryEmerald,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (_selectedPaymentMethod == 1) ...[
                  // QRIS
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.qr_code_2_rounded, size: 100, color: textPrimary),
                        const SizedBox(height: 6),
                        const Text('Pindai QRIS dengan e-wallet/m-banking', style: TextStyle(fontSize: 10.5, color: textMuted)),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => widget.onOpenCustomerDisplay(grandTotal),
                          icon: const Icon(Icons.tv_rounded, size: 14),
                          label: const Text('Tampilkan ke Pasien'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (_selectedPaymentMethod == 2) ...[
                  // DEBIT
                  const Text('Pilih Mesin EDC:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textPrimary)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: _bankList.map((b) {
                      final isSel = _selectedBank == b;
                      return ChoiceChip(
                        label: Text(b),
                        selected: isSel,
                        selectedColor: primaryEmerald,
                        backgroundColor: const Color(0xFFF1F5F9),
                        labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSel ? Colors.white : textPrimary),
                        onSelected: (val) {
                          if (val) setState(() => _selectedBank = b);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _refCodeController,
                    decoration: InputDecoration(
                      hintText: 'Approval / Ref Code EDC',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ] else if (_selectedPaymentMethod == 3) ...[
                  // BPJS / ASURANSI
                  const Text('Penjamin Asuransi:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textPrimary)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: _insuranceList.map((ins) {
                      final isSel = _selectedInsurance == ins;
                      return ChoiceChip(
                        label: Text(ins),
                        selected: isSel,
                        selectedColor: primaryEmerald,
                        backgroundColor: const Color(0xFFF1F5F9),
                        labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSel ? Colors.white : textPrimary),
                        onSelected: (val) {
                          if (val) setState(() => _selectedInsurance = ins);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _sepNumberController,
                    decoration: InputDecoration(
                      hintText: 'Nomor Kartu / No. SEP',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ] else if (_selectedPaymentMethod == 4) ...[
                  // SPLIT
                  const Text('Porsi Tunai:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textPrimary)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _splitCashController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onChanged: (v) {
                      final clean = v.replaceAll(RegExp(r'[^0-9]'), '');
                      final num p = num.tryParse(clean) ?? 0;
                      setState(() => _splitCashAmount = p);
                    },
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sisa Tagihan (Non-Tunai):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Text(
                          CurrencyFormatter.formatRupiah(secondarySplitAmount),
                          style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13, fontWeight: FontWeight.bold, color: primaryEmerald),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: ['QRIS Dinamis', 'Debit EDC', 'Iur Biaya BPJS'].map((m) {
                      final isSel = _splitSecondaryMethod == m;
                      return ChoiceChip(
                        label: Text(m),
                        selected: isSel,
                        selectedColor: primaryEmerald,
                        backgroundColor: const Color(0xFFF1F5F9),
                        labelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSel ? Colors.white : textPrimary),
                        onSelected: (val) {
                          if (val) setState(() => _splitSecondaryMethod = m);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Action CTA Footer
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: canvasColor,
            border: Border(top: BorderSide(color: borderColor, width: 1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: Checkbox(
                          value: _autoPrintReceipt,
                          activeColor: primaryEmerald,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (v) => setState(() => _autoPrintReceipt = v ?? true),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('Auto-print struk', style: TextStyle(fontSize: 11, color: textPrimary)),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: widget.onBackToCart,
                    icon: const Icon(Icons.arrow_back, size: 14, color: textMuted),
                    label: const Text('Batal / Item', style: TextStyle(fontSize: 11, color: textMuted)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _handleSettlement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryEmerald,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isProcessing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'SELESAIKAN (${CurrencyFormatter.formatRupiah(grandTotal)})',
                              style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
