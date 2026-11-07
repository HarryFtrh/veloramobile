import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/audio_helper.dart';
import '../../core/utils/currency_formatter.dart';
import '../shared_pos/pos_checkout_service.dart';
import '../shared_pos/receipt_printer_service.dart';
import '../shared_pos/sales_history_drawer.dart';
import 'services/pharmacy_clinical_safety_service.dart';
import 'widgets/pharmacy_customer_facing_display.dart';
import 'widgets/pharmacy_etiket_dialog.dart';
import 'widgets/pharmacy_receipt_dialog.dart';
import 'widgets/checkout/pharmacy_checkout_safety_banner.dart';
import 'widgets/checkout/pharmacy_checkout_receipt_audit.dart';
import 'widgets/checkout/pharmacy_checkout_payment_forms.dart';
import 'widgets/checkout/pharmacy_checkout_action_footer.dart';
import 'widgets/checkout/pharmacy_checkout_mobile_summary.dart';

import 'models/pharmacy_payment_mode.dart';

export 'models/pharmacy_payment_mode.dart';
export 'widgets/checkout/pharmacy_checkout_safety_banner.dart';
export 'widgets/checkout/pharmacy_checkout_receipt_audit.dart';
export 'widgets/checkout/pharmacy_checkout_payment_forms.dart';
export 'widgets/checkout/pharmacy_checkout_action_footer.dart';
export 'widgets/checkout/pharmacy_checkout_mobile_summary.dart';

class PharmacyCheckoutScreen extends StatefulWidget {
  final List<PosCartItem> items;
  final num subtotal;
  final num tuslahFee;
  final num embalaseFee;
  final num taxAmount;
  final String taxName;
  final num discountAmount;
  final num grandTotal;
  final String patientName;
  final String queueNumber;
  final String medicalRecordNumber;
  final String doctorName;
  final String patientCategory;
  final String patientAllergies;
  final Function(PosCheckoutResult result, String paymentMethodName) onCompleted;

  const PharmacyCheckoutScreen({
    super.key,
    required this.items,
    required this.subtotal,
    this.tuslahFee = 0,
    this.embalaseFee = 0,
    this.taxAmount = 0,
    this.taxName = 'PPN',
    this.discountAmount = 0,
    required this.grandTotal,
    required this.patientName,
    required this.queueNumber,
    required this.medicalRecordNumber,
    required this.doctorName,
    this.patientCategory = 'Umum',
    this.patientAllergies = '',
    required this.onCompleted,
  });

  @override
  State<PharmacyCheckoutScreen> createState() => _PharmacyCheckoutScreenState();
}

class _PharmacyCheckoutScreenState extends State<PharmacyCheckoutScreen> {
  PharmacyPaymentMode _selectedMode = PharmacyPaymentMode.cash;
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _refCodeController = TextEditingController();
  final TextEditingController _bpjsCardController = TextEditingController();
  final TextEditingController _sepNumberController = TextEditingController();

  // Split payment controllers
  final TextEditingController _splitCashController = TextEditingController();
  num _splitCashAmount = 0;
  String _splitSecondaryMethod = 'QRIS Dinamis';

  String _selectedBank = 'BCA';
  final List<String> _bankList = ['BCA', 'Mandiri', 'BRI', 'BNI', 'CIMB'];

  String _selectedInsurance = 'BPJS Kesehatan';
  final List<String> _insuranceList = [
    'BPJS Kesehatan',
    'Mandiri Inhealth',
    'Prudential',
    'Allianz',
    'Sinarmas',
  ];

  num _tenderAmount = 0;
  bool _isProcessing = false;
  bool _autoPrintReceipt = true;

  // Clinical Safety Alerts
  List<ClinicalSafetyAlert> _safetyAlerts = [];
  bool _isClinicalReviewAcknowledged = false;

  @override
  void initState() {
    super.initState();
    _tenderAmount = widget.grandTotal;
    _cashController.text = CurrencyFormatter.formatRupiah(widget.grandTotal);

    // Default split cash is 50% rounded
    _splitCashAmount = (widget.grandTotal / 20000).ceil() * 10000;
    if (_splitCashAmount > widget.grandTotal) _splitCashAmount = widget.grandTotal;
    _splitCashController.text = CurrencyFormatter.formatRupiah(_splitCashAmount);

    // Run Clinical Safety Screening
    _safetyAlerts = PharmacyClinicalSafetyService.instance.checkCartSafety(
      items: widget.items,
      patientAllergies: widget.patientAllergies,
    );
  }

  @override
  void dispose() {
    _cashController.dispose();
    _refCodeController.dispose();
    _bpjsCardController.dispose();
    _sepNumberController.dispose();
    _splitCashController.dispose();
    super.dispose();
  }

  void _onCashPresetSelected(num amount) {
    AudioHelper.tapFeedback();
    setState(() {
      _tenderAmount = amount;
      _cashController.text = CurrencyFormatter.formatRupiah(amount);
    });
  }

  void _onCashTextChanged(String val) {
    final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
    final num parsed = num.tryParse(clean) ?? 0;
    setState(() {
      _tenderAmount = parsed;
    });
  }

  void _openEtiketDialog() {
    AudioHelper.tapFeedback();
    PharmacyEtiketDialog.show(
      context: context,
      items: widget.items,
      patientName: widget.patientName,
      queueNumber: widget.queueNumber,
      medicalRecordNumber: widget.medicalRecordNumber,
      doctorName: widget.doctorName,
    );
  }

  void _openCustomerFacingDisplay() {
    AudioHelper.tapFeedback();
    PharmacyCustomerFacingDisplay.show(
      context: context,
      grandTotal: widget.grandTotal,
      patientName: widget.patientName,
      queueNumber: widget.queueNumber,
      onPaymentConfirmed: () {
        setState(() {
          _selectedMode = PharmacyPaymentMode.qris;
        });
        _processSettlement();
      },
    );
  }

  void _simulateShareWhatsApp() {
    AudioHelper.actionFeedback();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tautan struk digital #${DateTime.now().millisecondsSinceEpoch} dikirim ke nomor WhatsApp pasien.'),
        backgroundColor: ClinicalPalette.primary,
      ),
    );
  }

  Future<void> _processSettlement() async {
    if (_isProcessing) return;

    // Safety Contraindication Check
    final hasContraindication = _safetyAlerts.any((a) => a.level == ClinicalSafetyLevel.contraindication);
    if (hasContraindication && !_isClinicalReviewAcknowledged) {
      AudioHelper.actionFeedback();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Mohon centang "Telaah Apoteker: Verifikasi Aman" sebelum menyelesaikan transaksi.'),
          backgroundColor: ClinicalPalette.danger,
        ),
      );
      return;
    }

    if (_selectedMode == PharmacyPaymentMode.cash && _tenderAmount < widget.grandTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal uang tunai yang diterima kurang dari total tagihan!'),
          backgroundColor: ClinicalPalette.danger,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    AudioHelper.tapFeedback();

    final String methodCode;
    final String methodLabel;
    num paidAmount = widget.grandTotal;

    switch (_selectedMode) {
      case PharmacyPaymentMode.cash:
        methodCode = 'cash';
        methodLabel = 'TUNAI';
        paidAmount = _tenderAmount;
        break;
      case PharmacyPaymentMode.qris:
        methodCode = 'qris';
        methodLabel = 'QRIS DINAMIS';
        break;
      case PharmacyPaymentMode.debit:
        methodCode = 'debit';
        methodLabel = 'DEBIT $_selectedBank';
        break;
      case PharmacyPaymentMode.insurance:
        methodCode = 'insurance';
        methodLabel = _selectedInsurance.toUpperCase();
        break;
      case PharmacyPaymentMode.split:
        methodCode = 'split';
        final secondaryAmount = widget.grandTotal - _splitCashAmount;
        methodLabel = 'SPLIT (TUNAI ${CurrencyFormatter.formatRupiah(_splitCashAmount)} + $_splitSecondaryMethod ${CurrencyFormatter.formatRupiah(secondaryAmount)})';
        break;
    }

    try {
      final res = await PosCheckoutService.instance.checkout(
        items: widget.items,
        totalAmount: widget.grandTotal,
        paidAmount: paidAmount,
        paymentMethod: methodCode,
        customerName: '${widget.patientName} (${widget.queueNumber})',
        subtotal: widget.subtotal,
        taxAmount: widget.taxAmount,
        discountAmount: widget.discountAmount,
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (res.success) {
        SalesHistoryDrawer.addRecord(
          CompletedSaleRecord(
            invoiceNumber: res.invoiceNumber,
            time: DateTime.now(),
            total: widget.grandTotal,
            paymentMethod: methodLabel,
            tableOrCustomer: widget.patientName,
            items: widget.items,
          ),
        );

        if (_autoPrintReceipt) {
          try {
            await ReceiptPrinterService.instance.printReceipt(
              ReceiptData(
                storeName: SessionStorage.instance.getTenantName() ?? 'Velora Pharmacy',
                storeAddress: SessionStorage.instance.getStoreAddress() ?? '-',
                storePhone: SessionStorage.instance.getStorePhone() ?? '-',
                invoiceNumber: res.invoiceNumber,
                cashierName: SessionStorage.instance.getUserName() ?? 'Apoteker',
                tableOrPatient: '${widget.patientName} (${widget.queueNumber})',
                timestamp: DateTime.now(),
                items: widget.items,
                subtotal: widget.subtotal,
                tax: widget.taxAmount,
                grandTotal: widget.grandTotal,
                paymentMethod: methodLabel,
                paidAmount: paidAmount,
                changeAmount: res.changeAmount,
              ),
            );
          } catch (e) {
            debugPrint('⚠️ [ReceiptPrinter] Gagal auto print: $e');
          }
        }

        widget.onCompleted(res, methodLabel);

        if (!mounted) return;
        Navigator.of(context).pop(res);

        PharmacyReceiptDialog.show(
          context: context,
          result: res,
          patientName: widget.patientName,
          queueNumber: widget.queueNumber,
          medicalRecordNumber: widget.medicalRecordNumber,
          doctorName: widget.doctorName,
          items: widget.items,
          subtotal: widget.subtotal,
          tuslahFee: widget.tuslahFee,
          grandTotal: widget.grandTotal,
          paymentMethod: methodLabel,
          onNewSale: () {},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.errorMessage ?? 'Gagal memproses settlement pembayaran.'),
            backgroundColor: ClinicalPalette.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: ClinicalPalette.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTabletLandscape = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: ClinicalPalette.canvas,
      appBar: AppBar(
        backgroundColor: ClinicalPalette.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ClinicalPalette.textPrimary),
          tooltip: 'Kembali ke Kasir POS',
          onPressed: () {
            AudioHelper.tapFeedback();
            Navigator.of(context).pop();
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: ClinicalPalette.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.point_of_sale_rounded, color: ClinicalPalette.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Settlement Pembayaran Farmasi',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: ClinicalPalette.textPrimary,
                  ),
                ),
                Text(
                  '${SessionStorage.instance.getUserName() ?? "Apoteker"} • Pasien: ${widget.patientName} (${widget.queueNumber})',
                  style: const TextStyle(
                    fontSize: 11,
                    color: ClinicalPalette.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Action 1: Generator Etiket Obat (Signa)
          TextButton.icon(
            onPressed: _openEtiketDialog,
            icon: const Icon(Icons.label_important_rounded, size: 16, color: ClinicalPalette.primary),
            label: const Text(
              'Etiket Obat',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: ClinicalPalette.primary,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: ClinicalPalette.primary.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          ),
          const SizedBox(width: 8),

          // Action 2: Customer-Facing Display (Layar Pasien QRIS)
          IconButton(
            onPressed: _openCustomerFacingDisplay,
            icon: const Icon(Icons.tv_rounded, color: ClinicalPalette.secondary),
            tooltip: 'Layar Tampilan Pasien (QRIS Standee)',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFE0F2FE),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 8),

          // Status Badge
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ClinicalPalette.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ClinicalPalette.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: ClinicalPalette.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'SIAP SETTLEMENT',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: ClinicalPalette.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: ClinicalPalette.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: isTabletLandscape
            ? Row(
                children: [
                  // Left Column: Thermal Receipt Preview & Order Summary
                  Expanded(
                    flex: 5,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: ClinicalPalette.canvas,
                        border: Border(right: BorderSide(color: ClinicalPalette.border)),
                      ),
                      child: PharmacyCheckoutReceiptAudit(
                        items: widget.items,
                        subtotal: widget.subtotal,
                        tuslahFee: widget.tuslahFee,
                        embalaseFee: widget.embalaseFee,
                        taxAmount: widget.taxAmount,
                        taxName: widget.taxName,
                        discountAmount: widget.discountAmount,
                        grandTotal: widget.grandTotal,
                        patientName: widget.patientName,
                        queueNumber: widget.queueNumber,
                        medicalRecordNumber: widget.medicalRecordNumber,
                        doctorName: widget.doctorName,
                        onShareWhatsApp: _simulateShareWhatsApp,
                      ),
                    ),
                  ),
                  // Right Column: Payment Method Selection & Tender Form
                  Expanded(
                    flex: 7,
                    child: Container(
                      color: ClinicalPalette.surface,
                      child: _buildPaymentPanel(),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    PharmacyCheckoutSafetyBanner(
                      safetyAlerts: _safetyAlerts,
                      isClinicalReviewAcknowledged: _isClinicalReviewAcknowledged,
                      onToggleAcknowledged: (val) {
                        setState(() => _isClinicalReviewAcknowledged = val);
                      },
                      margin: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 12),
                    PharmacyCheckoutMobileSummary(
                      patientName: widget.patientName,
                      queueNumber: widget.queueNumber,
                      items: widget.items,
                      grandTotal: widget.grandTotal,
                    ),
                    const SizedBox(height: 16),
                    _buildPaymentPanel(),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: !isTabletLandscape
          ? PharmacyCheckoutMobileStickyBottomBar(
              isProcessing: _isProcessing,
              grandTotal: widget.grandTotal,
              onProcessSettlement: _processSettlement,
            )
          : null,
    );
  }

  // Right Column: Payment Methods & Tender Numpad
  Widget _buildPaymentPanel() {
    final num changeAmount = (_tenderAmount >= widget.grandTotal) ? (_tenderAmount - widget.grandTotal) : 0;

    return Column(
      children: [
        // Grand Total Header Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(bottom: BorderSide(color: ClinicalPalette.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'TOTAL PEMBAYARAN',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: ClinicalPalette.textTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Pilih metode pelunasan transaksi',
                    style: TextStyle(
                      fontSize: 12,
                      color: ClinicalPalette.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                CurrencyFormatter.formatRupiah(widget.grandTotal),
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  color: ClinicalPalette.primary,
                ),
              ),
            ],
          ),
        ),

        // Clinical Safety Banner (Tablet View)
        if (MediaQuery.of(context).size.width >= 768)
          PharmacyCheckoutSafetyBanner(
            safetyAlerts: _safetyAlerts,
            isClinicalReviewAcknowledged: _isClinicalReviewAcknowledged,
            onToggleAcknowledged: (val) {
              setState(() => _isClinicalReviewAcknowledged = val);
            },
          ),

        // Payment Method Selector Tabs
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          child: Row(
            children: [
              PharmacyPaymentTab(
                mode: PharmacyPaymentMode.cash,
                selectedMode: _selectedMode,
                icon: Icons.payments_rounded,
                label: 'Tunai',
                onSelect: (m) => _switchPaymentMode(m),
              ),
              const SizedBox(width: 6),
              PharmacyPaymentTab(
                mode: PharmacyPaymentMode.qris,
                selectedMode: _selectedMode,
                icon: Icons.qr_code_2_rounded,
                label: 'QRIS',
                onSelect: (m) => _switchPaymentMode(m),
              ),
              const SizedBox(width: 6),
              PharmacyPaymentTab(
                mode: PharmacyPaymentMode.debit,
                selectedMode: _selectedMode,
                icon: Icons.credit_card_rounded,
                label: 'Kartu EDC',
                onSelect: (m) => _switchPaymentMode(m),
              ),
              const SizedBox(width: 6),
              PharmacyPaymentTab(
                mode: PharmacyPaymentMode.insurance,
                selectedMode: _selectedMode,
                icon: Icons.verified_user_rounded,
                label: 'BPJS / Asuransi',
                onSelect: (m) => _switchPaymentMode(m),
              ),
              const SizedBox(width: 6),
              PharmacyPaymentTab(
                mode: PharmacyPaymentMode.split,
                selectedMode: _selectedMode,
                icon: Icons.call_split_rounded,
                label: 'Split Bayar',
                onSelect: (m) => _switchPaymentMode(m),
              ),
            ],
          ),
        ),

        // Method-Specific Interactive Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_selectedMode == PharmacyPaymentMode.cash) ...[
                  PharmacyCashPaymentForm(
                    cashController: _cashController,
                    grandTotal: widget.grandTotal,
                    tenderAmount: _tenderAmount,
                    onPresetSelected: _onCashPresetSelected,
                    onCashChanged: _onCashTextChanged,
                  ),
                ] else if (_selectedMode == PharmacyPaymentMode.qris) ...[
                  PharmacyQrisPaymentForm(
                    onOpenCustomerFacingDisplay: _openCustomerFacingDisplay,
                  ),
                ] else if (_selectedMode == PharmacyPaymentMode.debit) ...[
                  PharmacyDebitPaymentForm(
                    bankList: _bankList,
                    selectedBank: _selectedBank,
                    refCodeController: _refCodeController,
                    onSelectBank: (b) => setState(() => _selectedBank = b),
                  ),
                ] else if (_selectedMode == PharmacyPaymentMode.insurance) ...[
                  PharmacyInsurancePaymentForm(
                    insuranceList: _insuranceList,
                    selectedInsurance: _selectedInsurance,
                    bpjsCardController: _bpjsCardController,
                    sepNumberController: _sepNumberController,
                    onSelectInsurance: (ins) => setState(() => _selectedInsurance = ins),
                  ),
                ] else if (_selectedMode == PharmacyPaymentMode.split) ...[
                  PharmacySplitPaymentForm(
                    splitCashController: _splitCashController,
                    grandTotal: widget.grandTotal,
                    splitCashAmount: _splitCashAmount,
                    secondaryMethod: _splitSecondaryMethod,
                    onSplitCashChanged: (val) => setState(() => _splitCashAmount = val),
                    onSecondaryMethodChanged: (m) => setState(() => _splitSecondaryMethod = m),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Auto-print toggle & Primary Action CTA
        PharmacyCheckoutActionFooter(
          autoPrintReceipt: _autoPrintReceipt,
          onToggleAutoPrint: (val) => setState(() => _autoPrintReceipt = val),
          selectedMode: _selectedMode,
          changeAmount: changeAmount,
          grandTotal: widget.grandTotal,
          isProcessing: _isProcessing,
          onProcessSettlement: _processSettlement,
        ),
      ],
    );
  }

  void _switchPaymentMode(PharmacyPaymentMode mode) {
    AudioHelper.tapFeedback();
    setState(() {
      _selectedMode = mode;
      if (mode != PharmacyPaymentMode.cash) {
        _tenderAmount = widget.grandTotal;
      }
    });
  }
}
