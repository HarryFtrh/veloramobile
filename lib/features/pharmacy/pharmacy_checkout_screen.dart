import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/design/tokens.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/audio_helper.dart';
import '../../core/utils/currency_formatter.dart';
import '../shared_pos/pos_checkout_service.dart';
import '../shared_pos/receipt_printer_service.dart';
import '../shared_pos/sales_history_drawer.dart';
import 'widgets/pharmacy_receipt_dialog.dart';

enum PharmacyPaymentMode { cash, qris, debit, insurance }

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

  @override
  void initState() {
    super.initState();
    // Default tender amount is exact change
    _tenderAmount = widget.grandTotal;
    _cashController.text = CurrencyFormatter.formatRupiah(widget.grandTotal);
  }

  @override
  void dispose() {
    _cashController.dispose();
    _refCodeController.dispose();
    _bpjsCardController.dispose();
    _sepNumberController.dispose();
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

  Future<void> _processSettlement() async {
    if (_isProcessing) return;

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
        // Record sales history
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

        // Auto print receipt if enabled
        if (_autoPrintReceipt) {
          try {
            await ReceiptPrinterService.instance.printReceipt(
              storeName: SessionStorage.instance.getTenantName() ?? 'Velora Pharmacy',
              storeAddress: SessionStorage.instance.getStoreAddress() ?? '-',
              storePhone: SessionStorage.instance.getStorePhone() ?? '-',
              invoiceNumber: res.invoiceNumber,
              cashierName: SessionStorage.instance.getUserName() ?? 'Apoteker',
              tableName: '${widget.patientName} (${widget.queueNumber})',
              items: widget.items,
              subtotal: widget.subtotal,
              tax: widget.taxAmount,
              grandTotal: widget.grandTotal,
              paymentMethod: methodLabel,
              paidAmount: paidAmount,
              changeAmount: res.changeAmount,
            );
          } catch (e) {
            debugPrint('⚠️ [ReceiptPrinter] Gagal auto print: $e');
          }
        }

        // Notify parent callback
        widget.onCompleted(res, methodLabel);

        // Close checkout screen
        Navigator.of(context).pop(res);

        // Show official receipt dialog
        // ignore: use_build_context_synchronously
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
                      child: _buildReceiptAuditColumn(),
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
                    _buildMobileOrderSummaryCard(),
                    const SizedBox(height: 16),
                    _buildPaymentPanel(),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: !isTabletLandscape ? _buildMobileStickyBottomBar() : null,
    );
  }

  // ---------------------------------------------------------------------------
  // LEFT COLUMN: THERMAL RECEIPT VIEWPORT (STITCH CLINICAL PRECISION SCREEN 7)
  // ---------------------------------------------------------------------------
  Widget _buildReceiptAuditColumn() {
    return Column(
      children: [
        // Header Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            border: Border(bottom: BorderSide(color: ClinicalPalette.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.receipt_long_rounded, color: ClinicalPalette.primary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Pratinjau Struk & Rincian Transaksi',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: ClinicalPalette.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: ClinicalPalette.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'TERMINAL AUDIT COPY',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: ClinicalPalette.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Scrollable Receipt Paper
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 390),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ClinicalPalette.border),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Pharmacy Header
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: ClinicalPalette.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.health_and_safety_rounded, color: ClinicalPalette.primary, size: 22),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            (SessionStorage.instance.getTenantName() ?? 'VELORA PHARMACY').toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: ClinicalPalette.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            SessionStorage.instance.getLocationName() ?? 'Cabang Utama • Apotek & Klinik Terpadu',
                            style: const TextStyle(fontSize: 10.5, color: ClinicalPalette.textTertiary),
                          ),
                          Text(
                            SessionStorage.instance.getStoreAddress() ?? 'Jl. Kesehatan Medika No. 18 • Telp: (021) 7892011',
                            style: const TextStyle(fontSize: 10, color: ClinicalPalette.textTertiary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    _buildDashedLine(),
                    const SizedBox(height: 10),

                    // Metadata
                    _buildMetadataRow('Pasien / Klien:', widget.patientName, isBold: true),
                    _buildMetadataRow('No. Antrean:', widget.queueNumber),
                    _buildMetadataRow('No. Rekam Medis:', widget.medicalRecordNumber, isAccent: true),
                    _buildMetadataRow('Dokter Peresep:', widget.doctorName),
                    _buildMetadataRow('Kasir / Petugas:', SessionStorage.instance.getUserName() ?? 'Apoteker'),
                    _buildMetadataRow('Waktu Transaksi:', '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')} WIB'),

                    const SizedBox(height: 10),
                    _buildDashedLine(),
                    const SizedBox(height: 10),

                    // Items Table
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('RINCIAN OBAT & ALKES', style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: FontWeight.bold, color: ClinicalPalette.textTertiary)),
                        Text('SUBTOTAL', style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: FontWeight.bold, color: ClinicalPalette.textTertiary)),
                      ],
                    ),
                    const SizedBox(height: 6),

                    ...widget.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: ClinicalPalette.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  CurrencyFormatter.formatRupiah(item.price * item.quantity),
                                  style: const TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: ClinicalPalette.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${item.quantity}x @ ${CurrencyFormatter.formatRupiah(item.price)}',
                                  style: const TextStyle(fontSize: 10.5, color: ClinicalPalette.textTertiary),
                                ),
                                if (item.batchNumber != null && item.batchNumber != '-')
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      'B: ${item.batchNumber}',
                                      style: const TextStyle(
                                        fontFamily: 'JetBrains Mono',
                                        fontSize: 9,
                                        color: ClinicalPalette.textSecondary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 10),
                    _buildDashedLine(),
                    const SizedBox(height: 10),

                    // Financial Calculations
                    _buildFinancialRow('Subtotal Obat', widget.subtotal),
                    if (widget.tuslahFee > 0)
                      _buildFinancialRow('Jasa Tuslah / Dispensing', widget.tuslahFee, isSubtle: true),
                    if (widget.embalaseFee > 0)
                      _buildFinancialRow('Biaya Embalase & Wadah', widget.embalaseFee, isSubtle: true),
                    if (widget.taxAmount > 0)
                      _buildFinancialRow('${widget.taxName}', widget.taxAmount, isSubtle: true),
                    if (widget.discountAmount > 0)
                      _buildFinancialRow('Diskon', -widget.discountAmount, isDiscount: true),

                    const SizedBox(height: 8),
                    Container(height: 1, color: ClinicalPalette.border),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL TAGIHAN',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: ClinicalPalette.textPrimary,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatRupiah(widget.grandTotal),
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: ClinicalPalette.primary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    _buildDashedLine(),
                    const SizedBox(height: 10),

                    // Thermal Footer Note
                    Center(
                      child: Text(
                        'Obat yang sudah dibeli tidak dapat ditukar/dikembalikan.\nSemoga lekas sembuh.',
                        style: const TextStyle(fontSize: 9.5, color: ClinicalPalette.textTertiary, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // RIGHT COLUMN: PAYMENT METHODS & TENDER NUMPAD (HERO SETTLEMENT AREA)
  // ---------------------------------------------------------------------------
  Widget _buildPaymentPanel() {
    final num changeAmount = (_tenderAmount >= widget.grandTotal) ? (_tenderAmount - widget.grandTotal) : 0;
    final num shortAmount = (_tenderAmount < widget.grandTotal) ? (widget.grandTotal - _tenderAmount) : 0;

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

        // Payment Method Selector Tabs
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            children: [
              _buildPaymentTab(
                mode: PharmacyPaymentMode.cash,
                icon: Icons.payments_rounded,
                label: 'Tunai',
              ),
              const SizedBox(width: 8),
              _buildPaymentTab(
                mode: PharmacyPaymentMode.qris,
                icon: Icons.qr_code_2_rounded,
                label: 'QRIS',
              ),
              const SizedBox(width: 8),
              _buildPaymentTab(
                mode: PharmacyPaymentMode.debit,
                icon: Icons.credit_card_rounded,
                label: 'Kartu EDC',
              ),
              const SizedBox(width: 8),
              _buildPaymentTab(
                mode: PharmacyPaymentMode.insurance,
                icon: Icons.verified_user_rounded,
                label: 'BPJS / Asuransi',
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
                  _buildCashPaymentForm(changeAmount: changeAmount, shortAmount: shortAmount),
                ] else if (_selectedMode == PharmacyPaymentMode.qris) ...[
                  _buildQrisPaymentForm(),
                ] else if (_selectedMode == PharmacyPaymentMode.debit) ...[
                  _buildDebitPaymentForm(),
                ] else if (_selectedMode == PharmacyPaymentMode.insurance) ...[
                  _buildInsurancePaymentForm(),
                ],
              ],
            ),
          ),
        ),

        // Auto-print toggle & Primary Action CTA
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: ClinicalPalette.border)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
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
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _autoPrintReceipt,
                          activeColor: ClinicalPalette.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) {
                            setState(() => _autoPrintReceipt = val ?? true);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Cetak struk kasir & etiket otomatis',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: ClinicalPalette.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (_selectedMode == PharmacyPaymentMode.cash && changeAmount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Text(
                        'Kembalian: ${CurrencyFormatter.formatRupiah(changeAmount)}',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: ClinicalPalette.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Big Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processSettlement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ClinicalPalette.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: ClinicalPalette.primary.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'SELESAIKAN & CETAK STRUK (${CurrencyFormatter.formatRupiah(widget.grandTotal)})',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 0.3,
                              ),
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

  // ---------------------------------------------------------------------------
  // CASH FORM COMPONENT
  // ---------------------------------------------------------------------------
  Widget _buildCashPaymentForm({required num changeAmount, required num shortAmount}) {
    final List<num> presets = [
      widget.grandTotal,
      (widget.grandTotal / 10000).ceil() * 10000,
      50000,
      100000,
      200000,
      500000,
    ].toSet().where((amt) => amt >= widget.grandTotal || amt == widget.grandTotal).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Uang Diterima dari Pasien',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: ClinicalPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        // Cash Input Field
        TextField(
          controller: _cashController,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: ClinicalPalette.textPrimary,
          ),
          decoration: InputDecoration(
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text(
                'Rp',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ClinicalPalette.textTertiary,
                ),
              ),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear_rounded, color: ClinicalPalette.textTertiary),
              onPressed: () {
                _cashController.clear();
                _onCashTextChanged('0');
              },
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: ClinicalPalette.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: ClinicalPalette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: ClinicalPalette.primary, width: 2),
            ),
          ),
          onChanged: _onCashTextChanged,
        ),
        const SizedBox(height: 12),

        // Quick Tender Preset Buttons
        const Text(
          'Preset Uang Pas & Pecahan Cepat:',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ClinicalPalette.textTertiary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((amount) {
            final isExact = amount == widget.grandTotal;
            final isSelected = _tenderAmount == amount;
            return InkWell(
              onTap: () => _onCashPresetSelected(amount),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ClinicalPalette.primary
                      : isExact
                          ? ClinicalPalette.primary.withValues(alpha: 0.1)
                          : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? ClinicalPalette.primary : ClinicalPalette.border,
                  ),
                ),
                child: Text(
                  isExact ? 'Uang Pas (${CurrencyFormatter.formatRupiah(amount)})' : CurrencyFormatter.formatRupiah(amount),
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : isExact
                            ? ClinicalPalette.primary
                            : ClinicalPalette.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Change Calculation Display Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: shortAmount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: shortAmount > 0 ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    shortAmount > 0 ? Icons.warning_amber_rounded : Icons.price_check_rounded,
                    color: shortAmount > 0 ? ClinicalPalette.danger : ClinicalPalette.primary,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shortAmount > 0 ? 'Uang Kurang' : 'Kembalian Pasien',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: shortAmount > 0 ? ClinicalPalette.danger : ClinicalPalette.primary,
                        ),
                      ),
                      Text(
                        shortAmount > 0 ? 'Harap terima uang minimal sejumlah total tagihan' : 'Kembalikan uang fisik kepada pasien',
                        style: TextStyle(
                          fontSize: 11,
                          color: shortAmount > 0 ? ClinicalPalette.danger.withValues(alpha: 0.8) : ClinicalPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                CurrencyFormatter.formatRupiah(shortAmount > 0 ? shortAmount : changeAmount),
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: shortAmount > 0 ? ClinicalPalette.danger : ClinicalPalette.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // QRIS FORM COMPONENT
  // ---------------------------------------------------------------------------
  Widget _buildQrisPaymentForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ClinicalPalette.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.qr_code_scanner_rounded, color: ClinicalPalette.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'QRIS Dinamis Otomatis',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: ClinicalPalette.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'NMID: ID102003920194',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0369A1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Simulated QR Display
          Container(
            width: 180,
            height: 180,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ClinicalPalette.border),
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.qr_code_2_rounded, size: 156, color: ClinicalPalette.textPrimary),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                      ],
                    ),
                    child: const Icon(Icons.local_pharmacy_rounded, size: 22, color: ClinicalPalette.primary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          Text(
            'Scan dengan GoPay, OVO, Dana, BCA, Livin, atau Mobile Banking apa saja.',
            style: const TextStyle(fontSize: 11.5, color: ClinicalPalette.textTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.sync_rounded, color: ClinicalPalette.primary, size: 16),
                SizedBox(width: 6),
                Text(
                  'Deteksi Pembayaran Otomatis Aktif (Webhook Ready)',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ClinicalPalette.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DEBIT / EDC FORM COMPONENT
  // ---------------------------------------------------------------------------
  Widget _buildDebitPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Mesin EDC / Bank Penerbit',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: ClinicalPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _bankList.map((bank) {
            final isSelected = _selectedBank == bank;
            return ChoiceChip(
              label: Text(bank),
              selected: isSelected,
              selectedColor: ClinicalPalette.primary,
              backgroundColor: const Color(0xFFF1F5F9),
              labelStyle: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSelected ? Colors.white : ClinicalPalette.textPrimary,
              ),
              onSelected: (val) {
                if (val) setState(() => _selectedBank = bank);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        const Text(
          'Nomor Referensi / Approval Code EDC (Opsional)',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: ClinicalPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _refCodeController,
          decoration: InputDecoration(
            hintText: 'Contoh: REF#8892019 / 009210',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: ClinicalPalette.border),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // BPJS & INSURANCE FORM COMPONENT
  // ---------------------------------------------------------------------------
  Widget _buildInsurancePaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Penjamin / Asuransi Kesehatan',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: ClinicalPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _insuranceList.map((ins) {
            final isSelected = _selectedInsurance == ins;
            return ChoiceChip(
              label: Text(ins),
              selected: isSelected,
              selectedColor: ClinicalPalette.primary,
              backgroundColor: const Color(0xFFF1F5F9),
              labelStyle: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSelected ? Colors.white : ClinicalPalette.textPrimary,
              ),
              onSelected: (val) {
                if (val) setState(() => _selectedInsurance = ins);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        const Text(
          'Nomor Kartu Peserta / Polis',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: ClinicalPalette.textPrimary),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _bpjsCardController,
          decoration: InputDecoration(
            hintText: '0001293849102',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: ClinicalPalette.border),
            ),
          ),
        ),
        const SizedBox(height: 12),

        const Text(
          'Nomor SEP (Surat Eligibilitas Peserta)',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: ClinicalPalette.textPrimary),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _sepNumberController,
          decoration: InputDecoration(
            hintText: 'SEP-20241024-009182',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: ClinicalPalette.border),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------
  Widget _buildPaymentTab({
    required PharmacyPaymentMode mode,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          AudioHelper.tapFeedback();
          setState(() {
            _selectedMode = mode;
            if (mode != PharmacyPaymentMode.cash) {
              _tenderAmount = widget.grandTotal;
            }
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? ClinicalPalette.primary : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? ClinicalPalette.primary : ClinicalPalette.border,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? Colors.white : ClinicalPalette.textSecondary, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : ClinicalPalette.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value, {bool isBold = false, bool isAccent = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: ClinicalPalette.textTertiary)),
          Text(
            value,
            style: TextStyle(
              fontFamily: isAccent ? 'JetBrains Mono' : 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: isBold || isAccent ? FontWeight.bold : FontWeight.w500,
              color: isAccent ? ClinicalPalette.primary : ClinicalPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String label, num amount, {bool isSubtle = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: isSubtle ? ClinicalPalette.textTertiary : ClinicalPalette.textSecondary,
            ),
          ),
          Text(
            '${isDiscount ? "-" : ""}${CurrencyFormatter.formatRupiah(amount.abs())}',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDiscount ? ClinicalPalette.danger : ClinicalPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedLine() {
    return Row(
      children: List.generate(
        30,
        (i) => Expanded(
          child: Container(
            color: i % 2 == 0 ? ClinicalPalette.border : Colors.transparent,
            height: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileOrderSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ClinicalPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pasien: ${widget.patientName}',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: ClinicalPalette.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ClinicalPalette.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.queueNumber,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: ClinicalPalette.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.items.length} item obat terdaftar',
            style: const TextStyle(fontSize: 11, color: ClinicalPalette.textTertiary),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Tagihan', style: TextStyle(fontSize: 12, color: ClinicalPalette.textSecondary)),
              Text(
                CurrencyFormatter.formatRupiah(widget.grandTotal),
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: ClinicalPalette.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStickyBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: ClinicalPalette.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _processSettlement,
          style: ElevatedButton.styleFrom(
            backgroundColor: ClinicalPalette.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isProcessing
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
                  'SELESAIKAN (${CurrencyFormatter.formatRupiah(widget.grandTotal)})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
        ),
      ),
    );
  }
}
