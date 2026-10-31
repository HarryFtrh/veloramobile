import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/utils/audio_helper.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../shared_pos/pos_checkout_service.dart';
import '../../shared_pos/receipt_printer_service.dart';
import '../../shared_pos/sales_history_drawer.dart';
import '../pharmacy_service.dart';
import '../services/pharmacy_clinical_safety_service.dart';
import 'pharmacy_customer_facing_display.dart';
import 'pharmacy_etiket_dialog.dart';
import 'pharmacy_receipt_dialog.dart';

enum PharmacyCartPanelMode { cartItems, tenderPayment }

class PharmacyCartPanel extends StatefulWidget {
  final Map<String, int> cart;
  final List<Map<String, dynamic>> drugItems;
  final num totalPrice;
  final num tuslahFee;
  final String selectedPatient;
  final String selectedDoctor;
  final String queueNumber;
  final String medicalRecordNumber;
  final String patientCategory;
  final String patientAllergies;
  final VoidCallback onChangePatient;
  final VoidCallback onClearCart;
  final Function(String id) onAddToCart;
  final Function(String id) onRemoveFromCart;
  final VoidCallback onCheckout;
  final VoidCallback? onClose;
  final Function(PosCheckoutResult result, String paymentMethod)? onSettlementSuccess;
  final Function(String oldKey, String newUnit)? onChangeCartItemUnit;

  const PharmacyCartPanel({
    super.key,
    required this.cart,
    required this.drugItems,
    required this.totalPrice,
    this.tuslahFee = 0,
    required this.selectedPatient,
    required this.selectedDoctor,
    this.queueNumber = '-',
    this.medicalRecordNumber = '-',
    this.patientCategory = 'Umum',
    this.patientAllergies = '',
    required this.onChangePatient,
    required this.onClearCart,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.onCheckout,
    this.onClose,
    this.onSettlementSuccess,
    this.onChangeCartItemUnit,
  });

  @override
  State<PharmacyCartPanel> createState() => _PharmacyCartPanelState();
}

class _PharmacyCartPanelState extends State<PharmacyCartPanel> {
  static const primaryEmerald = Color(0xFF059669); // Clinical Precision Primary
  static const secondaryTeal = Color(0xFF0D9488); // Clinical Precision Secondary
  static const borderColor = Color(0xFFE2E8F0);
  static const canvasColor = Color(0xFFFAF8FF);
  static const textPrimary = Color(0xFF0F172A); // Clinical Precision Neutral
  static const textMuted = Color(0xFF6D7A72);

  PharmacyCartPanelMode _panelMode = PharmacyCartPanelMode.cartItems;
  int _selectedPaymentMethod = 0; // 0: Tunai, 1: QRIS, 2: Debit/EDC, 3: Asuransi, 4: Split

  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _refCodeController = TextEditingController();
  final TextEditingController _bpjsCardController = TextEditingController();
  final TextEditingController _sepNumberController = TextEditingController();

  // Split payment
  final TextEditingController _splitCashController = TextEditingController();
  num _splitCashAmount = 0;
  String _splitSecondaryMethod = 'QRIS Dinamis';

  String _selectedBank = 'BCA';
  final List<String> _bankList = ['BCA', 'Mandiri', 'BRI', 'BNI'];

  String _selectedInsurance = 'BPJS Kesehatan';
  final List<String> _insuranceList = ['BPJS Kesehatan', 'Mandiri Inhealth', 'Prudential', 'Allianz'];

  num _tenderAmount = 0;
  bool _isProcessing = false;
  bool _autoPrintReceipt = true;
  bool _isClinicalReviewAcknowledged = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'name': 'Tunai', 'icon': Icons.payments_outlined},
    {'name': 'QRIS', 'icon': Icons.qr_code_2_rounded},
    {'name': 'Debit/EDC', 'icon': Icons.credit_card_outlined},
    {'name': 'BPJS/Asuransi', 'icon': Icons.health_and_safety_outlined},
    {'name': 'Split', 'icon': Icons.call_split_rounded},
  ];

  @override
  void dispose() {
    _cashController.dispose();
    _refCodeController.dispose();
    _bpjsCardController.dispose();
    _sepNumberController.dispose();
    _splitCashController.dispose();
    super.dispose();
  }

  void _switchToTenderMode(num grandTotal) {
    AudioHelper.tapFeedback();
    setState(() {
      _panelMode = PharmacyCartPanelMode.tenderPayment;
      _selectedPaymentMethod = 0; // Tunai (Cash) default
      _tenderAmount = grandTotal;
      _cashController.text = CurrencyFormatter.formatRupiah(grandTotal);

      _splitCashAmount = (grandTotal / 20000).ceil() * 10000;
      if (_splitCashAmount > grandTotal) _splitCashAmount = grandTotal;
      _splitCashController.text = CurrencyFormatter.formatRupiah(_splitCashAmount);
    });
  }

  void _switchToCartMode() {
    AudioHelper.tapFeedback();
    setState(() {
      _panelMode = PharmacyCartPanelMode.cartItems;
    });
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

  List<PosCartItem> _buildCartItems() {
    return widget.cart.entries.map((e) {
      final cartKey = e.key;
      final baseId = cartKey.contains(':') ? cartKey.split(':').first : cartKey;
      final item = widget.drugItems.firstWhere(
        (m) => m['id'] == baseId,
        orElse: () => <String, dynamic>{'id': baseId, 'name': 'Obat', 'price': 0},
      );
      final currentUnit = cartKey.contains(':') ? cartKey.split(':').last : (item['selectedUnit'] ?? item['unit'] ?? 'TAB');
      num price = (item['price'] as num?) ?? 0;
      final rawUnits = item['units'];
      if (rawUnits is List) {
        for (final u in rawUnits) {
          if (u is Map && u['name']?.toString().toUpperCase() == currentUnit.toUpperCase()) {
            price = (u['price'] as num?) ?? price;
            break;
          }
        }
      }
      return PosCartItem(
        productId: baseId,
        name: '${item['name']?.toString() ?? 'Obat'} ($currentUnit)',
        price: price,
        quantity: e.value,
        batchNumber: item['batch']?.toString(),
        expiryDate: (item['ed'] ?? item['exp'])?.toString(),
        modifiers: {'Satuan': currentUnit},
      );
    }).toList();
  }

  void _showUnitPicker(BuildContext context, String cartKey, List<Map<String, dynamic>> units, String currentUnit) {
    AudioHelper.tapFeedback();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pilih Satuan Jual',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...units.map((u) {
                  final uName = u['name']?.toString() ?? 'TAB';
                  final uPrice = (u['price'] as num?) ?? 0;
                  final isSelected = uName.toUpperCase() == currentUnit.toUpperCase();

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      color: isSelected ? primaryEmerald : textMuted,
                      size: 20,
                    ),
                    title: Text(
                      uName,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isSelected ? primaryEmerald : textPrimary,
                      ),
                    ),
                    trailing: Text(
                      CurrencyFormatter.format(uPrice),
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isSelected ? primaryEmerald : textPrimary,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      if (uName.toUpperCase() != currentUnit.toUpperCase()) {
                        widget.onChangeCartItemUnit?.call(cartKey, uName);
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openEtiketDialog() {
    AudioHelper.tapFeedback();
    PharmacyEtiketDialog.show(
      context: context,
      items: _buildCartItems(),
      patientName: widget.selectedPatient,
      queueNumber: widget.queueNumber,
      medicalRecordNumber: widget.medicalRecordNumber,
      doctorName: widget.selectedDoctor,
    );
  }

  void _openCustomerFacingDisplay(num grandTotal) {
    AudioHelper.tapFeedback();
    PharmacyCustomerFacingDisplay.show(
      context: context,
      grandTotal: grandTotal,
      patientName: widget.selectedPatient,
      queueNumber: widget.queueNumber,
      onPaymentConfirmed: () {
        setState(() => _selectedPaymentMethod = 1); // QRIS
        _processInPlaceSettlement(grandTotal);
      },
    );
  }

  Future<void> _processInPlaceSettlement(num grandTotal) async {
    if (_isProcessing) return;

    final cartItems = _buildCartItems();
    final safetyAlerts = PharmacyClinicalSafetyService.instance.checkCartSafety(
      items: cartItems,
      patientAllergies: widget.patientAllergies,
    );
    final hasContra = safetyAlerts.any((a) => a.level == ClinicalSafetyLevel.contraindication);
    if (hasContra && !_isClinicalReviewAcknowledged) {
      AudioHelper.actionFeedback();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Centang "Telaah Apoteker: Verifikasi Aman" sebelum menyelesaikan transaksi.'),
          backgroundColor: ClinicalPalette.danger,
        ),
      );
      return;
    }

    if (_selectedPaymentMethod == 0 && _tenderAmount < grandTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal uang tunai kurang dari total tagihan!'),
          backgroundColor: ClinicalPalette.danger,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    AudioHelper.tapFeedback();

    final String methodCode;
    final String methodLabel;
    num paidAmount = grandTotal;

    switch (_selectedPaymentMethod) {
      case 0: // Tunai
        methodCode = 'cash';
        methodLabel = 'TUNAI';
        paidAmount = _tenderAmount;
        break;
      case 1: // QRIS
        methodCode = 'qris';
        methodLabel = 'QRIS DINAMIS';
        break;
      case 2: // Debit
        methodCode = 'debit';
        methodLabel = 'DEBIT $_selectedBank';
        break;
      case 3: // Asuransi
        methodCode = 'insurance';
        methodLabel = _selectedInsurance.toUpperCase();
        break;
      case 4: // Split
        methodCode = 'split';
        final secondaryAmount = grandTotal - _splitCashAmount;
        methodLabel = 'SPLIT (TUNAI ${CurrencyFormatter.formatRupiah(_splitCashAmount)} + $_splitSecondaryMethod ${CurrencyFormatter.formatRupiah(secondaryAmount)})';
        break;
      default:
        methodCode = 'cash';
        methodLabel = 'TUNAI';
    }

    try {
      final res = await PosCheckoutService.instance.checkout(
        items: cartItems,
        totalAmount: grandTotal,
        paidAmount: paidAmount,
        paymentMethod: methodCode,
        customerName: '${widget.selectedPatient} (${widget.queueNumber})',
        subtotal: widget.totalPrice,
        taxAmount: 0,
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (res.success) {
        SalesHistoryDrawer.addRecord(
          CompletedSaleRecord(
            invoiceNumber: res.invoiceNumber,
            time: DateTime.now(),
            total: grandTotal,
            paymentMethod: methodLabel,
            tableOrCustomer: widget.selectedPatient,
            items: cartItems,
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
                tableOrPatient: '${widget.selectedPatient} (${widget.queueNumber})',
                timestamp: DateTime.now(),
                items: cartItems,
                subtotal: widget.totalPrice,
                tax: 0,
                grandTotal: grandTotal,
                paymentMethod: methodLabel,
                paidAmount: paidAmount,
                changeAmount: res.changeAmount,
              ),
            );
          } catch (e) {
            debugPrint('⚠️ [ReceiptPrinter] Gagal auto print: $e');
          }
        }

        widget.onSettlementSuccess?.call(res, methodLabel);
        widget.onClearCart();
        setState(() => _panelMode = PharmacyCartPanelMode.cartItems);

        if (!mounted) return;

        PharmacyReceiptDialog.show(
          context: context,
          result: res,
          patientName: widget.selectedPatient,
          queueNumber: widget.queueNumber,
          medicalRecordNumber: widget.medicalRecordNumber,
          doctorName: widget.selectedDoctor,
          items: cartItems,
          subtotal: widget.totalPrice,
          tuslahFee: widget.totalPrice > 0 ? widget.tuslahFee : 0,
          grandTotal: grandTotal,
          paymentMethod: methodLabel,
          onNewSale: () {},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.errorMessage ?? 'Gagal memproses settlement.'),
            backgroundColor: ClinicalPalette.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: ClinicalPalette.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTuslah = widget.totalPrice > 0 ? widget.tuslahFee : 0;
    final taxEnabled = PharmacyService.instance.taxEnabled.value;
    final taxRate = PharmacyService.instance.taxRate.value;
    final taxName = PharmacyService.instance.taxName.value;
    final taxInclusive = PharmacyService.instance.taxInclusive.value;

    final taxAmount = (taxEnabled && taxRate > 0)
        ? (taxInclusive
            ? (widget.totalPrice * taxRate / (1 + taxRate)).round()
            : (widget.totalPrice * taxRate).round())
        : 0;
    final grandTotal = widget.totalPrice + effectiveTuslah + (taxInclusive ? 0 : taxAmount);
    final totalQty = widget.cart.values.fold<int>(0, (s, q) => s + q);

    return Container(
      color: Colors.white,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _panelMode == PharmacyCartPanelMode.tenderPayment
            ? _buildInPlaceTenderView(
                grandTotal: grandTotal,
                totalQty: totalQty,
              )
            : _buildCartItemsView(
                grandTotal: grandTotal,
                effectiveTuslah: effectiveTuslah,
                taxEnabled: taxEnabled,
                taxRate: taxRate,
                taxName: taxName,
                taxInclusive: taxInclusive,
                taxAmount: taxAmount,
                totalQty: totalQty,
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VIEW 1: REGULAR CART ITEMS VIEW
  // ---------------------------------------------------------------------------
  Widget _buildCartItemsView({
    required num grandTotal,
    required num effectiveTuslah,
    required bool taxEnabled,
    required double taxRate,
    required String taxName,
    required bool taxInclusive,
    required num taxAmount,
    required int totalQty,
  }) {
    return Column(
      key: const ValueKey('CartItemsView'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: Keranjang Kasir & Order Meta
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            color: canvasColor,
            border: Border(bottom: BorderSide(color: borderColor, width: 1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: primaryEmerald,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.shopping_basket_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Keranjang Kasir',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                widget.cart.isEmpty ? 'Keranjang kosong' : '${widget.cart.length} item dipilih',
                                style: const TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  color: textMuted,
                                  fontSize: 10.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.cart.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            AudioHelper.actionFeedback();
                            widget.onClearCart();
                          },
                          icon: const Icon(Icons.delete_sweep_rounded, size: 16, color: Color(0xFFBA1A1A)),
                          label: const Text(
                            'Reset',
                            style: TextStyle(
                              color: Color(0xFFBA1A1A),
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      if (widget.onClose != null) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: textMuted),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: widget.onClose,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Clinical Patient Strip
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: widget.onChangePatient,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: secondaryTeal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.person_outline, size: 18, color: secondaryTeal),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.selectedPatient,
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF86F2E4).withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    widget.queueNumber,
                                    style: const TextStyle(
                                      fontFamily: 'JetBrains Mono',
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: secondaryTeal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'RM: ${widget.medicalRecordNumber} • ${widget.selectedDoctor}',
                              style: const TextStyle(fontSize: 10.5, color: textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: canvasColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: borderColor),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sync_alt_rounded, size: 12, color: primaryEmerald),
                            SizedBox(width: 4),
                            Text(
                              'Ganti',
                              style: TextStyle(
                                color: primaryEmerald,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Scrollable Cart Item List
        Expanded(
          child: widget.cart.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: canvasColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor),
                          ),
                          child: const Icon(Icons.receipt_long_outlined, size: 30, color: textMuted),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Keranjang Resep Kosong',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Pilih sediaan obat dari katalog atau scan barcode untuk memuat resep.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11.5, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: widget.cart.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final cartKey = widget.cart.keys.elementAt(index);
                    final qty = widget.cart[cartKey]!;
                    final baseId = cartKey.contains(':') ? cartKey.split(':').first : cartKey;
                    final item = widget.drugItems.firstWhere(
                      (e) => e['id'] == baseId,
                      orElse: () => <String, dynamic>{},
                    );
                    final currentUnit = cartKey.contains(':')
                        ? cartKey.split(':').last
                        : (item['selectedUnit'] ?? item['unit'] ?? 'TAB');

                    final rawUnits = item['units'];
                    final List<Map<String, dynamic>> units = (rawUnits is List)
                        ? rawUnits.whereType<Map<String, dynamic>>().toList()
                        : [];

                    num price = (item['price'] as num? ?? 0);
                    for (final u in units) {
                      if (u['name']?.toString().toUpperCase() == currentUnit.toUpperCase()) {
                        price = (u['price'] as num?) ?? price;
                        break;
                      }
                    }

                    final itemTotal = price * qty;
                    final batch = item['batch']?.toString() ?? item['batchNumber']?.toString() ?? '-';
                    final isRx = item['isDotRed'] == true ||
                        item['isPrescriptionOnly'] == true ||
                        (item['category']?.toString().toLowerCase().contains('keras') ?? false);
                    final isAlkes = (item['category']?.toString().toLowerCase().contains('alkes') ?? false);

                    final rawImg = item['imageUrl'] ?? item['image'];
                    String? imgUrl = (rawImg is String && rawImg.isNotEmpty && rawImg != '-') ? rawImg : null;
                    if (imgUrl != null) {
                      final lower = imgUrl.toLowerCase();
                      if (lower.contains('ui-avatars') ||
                          lower.contains('placeholder') ||
                          lower.contains('dummyimage') ||
                          lower.contains('dicebear') ||
                          lower.contains('avatar') ||
                          lower.contains('default')) {
                        imgUrl = null;
                      }
                    }

                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (imgUrl != null) ...[
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(5),
                                            child: Image.network(
                                              imgUrl,
                                              width: 24,
                                              height: 24,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) => const SizedBox.shrink(),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: isRx
                                                ? const Color(0xFFFFDAD6)
                                                : isAlkes
                                                    ? const Color(0xFFE0F2FE)
                                                    : const Color(0xFFE2E7FF),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isRx ? 'Rx' : isAlkes ? 'Alkes' : 'OTC',
                                            style: TextStyle(
                                              fontFamily: 'JetBrains Mono',
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: isRx
                                                  ? const Color(0xFFBA1A1A)
                                                  : isAlkes
                                                      ? const Color(0xFF0284C7)
                                                      : const Color(0xFF3D4A42),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            item['name'] ?? '',
                                            style: const TextStyle(
                                              fontFamily: 'Plus Jakarta Sans',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.5,
                                              color: textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 6,
                                      children: [
                                        Text(
                                          'Batch: $batch • ${CurrencyFormatter.format(price)}/$currentUnit',
                                          style: const TextStyle(
                                            fontFamily: 'JetBrains Mono',
                                            fontSize: 10,
                                            color: textMuted,
                                          ),
                                        ),
                                        if (units.length > 1)
                                          InkWell(
                                            onTap: () => _showUnitPicker(context, cartKey, units, currentUnit),
                                            borderRadius: BorderRadius.circular(4),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: primaryEmerald.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: primaryEmerald.withValues(alpha: 0.3)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: const [
                                                  Text(
                                                    'Ubah Satuan ▾',
                                                    style: TextStyle(
                                                      fontFamily: 'JetBrains Mono',
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                      color: primaryEmerald,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () => widget.onRemoveFromCart(cartKey),
                                borderRadius: BorderRadius.circular(4),
                                child: const Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF6D7A72)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        AudioHelper.tapFeedback();
                                        widget.onRemoveFromCart(cartKey);
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: Icon(Icons.remove, size: 14, color: textPrimary),
                                      ),
                                    ),
                                    Text(
                                      '$qty',
                                      style: const TextStyle(
                                        fontFamily: 'JetBrains Mono',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: textPrimary,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        AudioHelper.tapFeedback();
                                        widget.onAddToCart(cartKey);
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: Icon(Icons.add, size: 14, color: primaryEmerald),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(itemTotal),
                                style: const TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: primaryEmerald,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Financial Calculation & Action CTA Footer
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: canvasColor,
            border: Border(top: BorderSide(color: borderColor, width: 1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal ($totalQty item)', style: const TextStyle(color: textMuted, fontSize: 11.5)),
                  Text(
                    CurrencyFormatter.format(widget.totalPrice),
                    style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              if (effectiveTuslah > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tuslah & Embalase Resep', style: TextStyle(color: textMuted, fontSize: 11.5)),
                    Text(
                      CurrencyFormatter.format(effectiveTuslah),
                      style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
              ],
              if (taxEnabled && taxRate > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$taxName (${(taxRate * 100).toStringAsFixed(0)}%${taxInclusive ? " Termasuk" : ""})',
                      style: const TextStyle(color: textMuted, fontSize: 11),
                    ),
                    Text(
                      CurrencyFormatter.format(taxAmount),
                      style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: Color(0xFF6D7A72)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: borderColor, height: 1),
              ),

              // Grand Total Highlight
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL TAGIHAN',
                        style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, letterSpacing: 0.5, fontWeight: FontWeight.bold, color: textMuted),
                      ),
                      Text(
                        CurrencyFormatter.format(grandTotal),
                        style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 20, fontWeight: FontWeight.w800, color: primaryEmerald),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryEmerald.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$totalQty Qty Total',
                      style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: FontWeight.bold, color: primaryEmerald),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // In-Place Morph Trigger Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: widget.cart.isNotEmpty ? () => _switchToTenderMode(grandTotal) : null,
                  icon: const Icon(Icons.payments_rounded, size: 18),
                  label: Text(
                    widget.cart.isNotEmpty
                        ? 'Lanjut ke Pembayaran (${CurrencyFormatter.format(grandTotal)})'
                        : 'Keranjang Masih Kosong',
                    style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryEmerald,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: widget.cart.isNotEmpty ? 2 : 0,
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
  // VIEW 2: IN-PLACE TENDER PAYMENT VIEW (USER INNOVATION)
  // ---------------------------------------------------------------------------
  Widget _buildInPlaceTenderView({
    required num grandTotal,
    required int totalQty,
  }) {
    final num changeAmount = (_tenderAmount >= grandTotal) ? (_tenderAmount - grandTotal) : 0;
    final num shortAmount = (_tenderAmount < grandTotal) ? (grandTotal - _tenderAmount) : 0;
    final num secondarySplitAmount = (grandTotal > _splitCashAmount) ? (grandTotal - _splitCashAmount) : 0;

    final cartItems = _buildCartItems();
    final safetyAlerts = PharmacyClinicalSafetyService.instance.checkCartSafety(
      items: cartItems,
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
          decoration: BoxDecoration(
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
                      onPressed: _switchToCartMode,
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
                    onPressed: _openEtiketDialog,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.tv_rounded, size: 18, color: secondaryTeal),
                    tooltip: 'Layar Pasien QRIS',
                    onPressed: () => _openCustomerFacingDisplay(grandTotal),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.open_in_full_rounded, size: 16, color: textMuted),
                    tooltip: 'Mode Layar Penuh Dual-Pane',
                    onPressed: widget.onCheckout,
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
                            style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 18, fontWeight: FontWeight.w900, color: primaryEmerald),
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
                          '$totalQty Item Obat',
                          style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: FontWeight.bold, color: primaryEmerald),
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

                // Form Section
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
                          onPressed: () => _openCustomerFacingDisplay(grandTotal),
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
          decoration: BoxDecoration(
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
                    onPressed: _switchToCartMode,
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
                  onPressed: _isProcessing ? null : () => _processInPlaceSettlement(grandTotal),
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
