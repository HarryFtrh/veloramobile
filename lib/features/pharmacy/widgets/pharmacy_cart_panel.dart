import 'package:flutter/material.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/utils/audio_helper.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/design/tokens.dart';
import '../../shared_pos/pos_checkout_service.dart';
import '../../shared_pos/product_catalog_service.dart';
import '../../shared_pos/receipt_printer_service.dart';
import '../../shared_pos/sales_history_drawer.dart';
import '../pharmacy_service.dart';
import 'pharmacy_customer_facing_display.dart';
import 'pharmacy_etiket_dialog.dart';
import 'pharmacy_receipt_dialog.dart';
import 'cart/pharmacy_cart_header.dart';
import 'cart/pharmacy_cart_item_tile.dart';
import 'cart/pharmacy_cart_summary.dart';
import 'cart/pharmacy_cart_tender_view.dart';

export 'cart/pharmacy_cart_header.dart';
export 'cart/pharmacy_cart_item_tile.dart';
export 'cart/pharmacy_cart_summary.dart';
export 'cart/pharmacy_cart_tender_view.dart';

enum PharmacyCartPanelMode { cartItems, tenderPayment }

/// Panel Keranjang Kasir Apotek (Modular, Clean, dan Terintegrasi Pembayaran)
class PharmacyCartPanel extends StatefulWidget {
  final Map<String, int> cart;
  final List<Map<String, dynamic>> drugItems;
  final Map<String, Map<String, dynamic>>? drugItemsById;
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
    this.drugItemsById,
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
  static const primaryEmerald = Color(0xFF059669);
  static const secondaryTeal = Color(0xFF0D9488);
  static const textPrimary = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);

  PharmacyCartPanelMode _panelMode = PharmacyCartPanelMode.cartItems;

  void _switchToTenderMode() {
    AudioHelper.tapFeedback();
    setState(() {
      _panelMode = PharmacyCartPanelMode.tenderPayment;
    });
  }

  void _switchToCartMode() {
    AudioHelper.tapFeedback();
    setState(() {
      _panelMode = PharmacyCartPanelMode.cartItems;
    });
  }

  List<PosCartItem> _buildCartItems() {
    return widget.cart.entries.map((e) {
      final cartKey = e.key;
      final baseId = cartKey.contains(':') ? cartKey.split(':').first : cartKey;
      final item = widget.drugItemsById != null
          ? (widget.drugItemsById![baseId.toString()] ?? <String, dynamic>{'id': baseId, 'name': 'Obat', 'price': 0})
          : widget.drugItems.firstWhere(
              (m) => m['id'].toString() == baseId.toString(),
              orElse: () => <String, dynamic>{'id': baseId, 'name': 'Obat', 'price': 0},
            );
      final currentUnit = cartKey.contains(':')
          ? cartKey.split(':').last
          : (item['selectedUnit'] ?? item['unit'] ?? 'TAB');

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
        _handleSettlement(
          paymentMethodIndex: 1,
          paymentMethodName: 'QRIS DINAMIS',
          tenderAmount: grandTotal,
          changeAmount: 0,
          bankOrInsurance: '-',
          refOrSepCode: '-',
          autoPrintReceipt: true,
          grandTotal: grandTotal,
        );
      },
    );
  }

  Future<void> _handleSettlement({
    required int paymentMethodIndex,
    required String paymentMethodName,
    required num tenderAmount,
    required num changeAmount,
    required String bankOrInsurance,
    required String refOrSepCode,
    required bool autoPrintReceipt,
    required num grandTotal,
  }) async {
    final cartItems = _buildCartItems();
    final String methodCode;

    switch (paymentMethodIndex) {
      case 0:
        methodCode = 'cash';
        break;
      case 1:
        methodCode = 'qris';
        break;
      case 2:
        methodCode = 'debit';
        break;
      case 3:
        methodCode = 'insurance';
        break;
      case 4:
        methodCode = 'split';
        break;
      default:
        methodCode = 'cash';
    }

    try {
      final res = await PosCheckoutService.instance.checkout(
        items: cartItems,
        totalAmount: grandTotal,
        paidAmount: tenderAmount,
        paymentMethod: methodCode,
        customerName: '${widget.selectedPatient} (${widget.queueNumber})',
        subtotal: widget.totalPrice,
        taxAmount: 0,
      );

      if (!mounted) return;

      if (res.success) {
        SalesHistoryDrawer.addRecord(
          CompletedSaleRecord(
            invoiceNumber: res.invoiceNumber,
            time: DateTime.now(),
            total: grandTotal,
            paymentMethod: paymentMethodName,
            tableOrCustomer: widget.selectedPatient,
            items: cartItems,
          ),
        );

        if (autoPrintReceipt) {
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
                paymentMethod: paymentMethodName,
                paidAmount: tenderAmount,
                changeAmount: res.changeAmount,
              ),
            );
          } catch (e) {
            debugPrint('⚠️ [ReceiptPrinter] Gagal auto print: $e');
          }
        }

        widget.onSettlementSuccess?.call(res, paymentMethodName);
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
          paymentMethod: paymentMethodName,
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
            ? PharmacyCartTenderView(
                grandTotal: grandTotal,
                totalQty: totalQty,
                selectedPatient: widget.selectedPatient,
                queueNumber: widget.queueNumber,
                patientAllergies: widget.patientAllergies,
                cartItems: _buildCartItems(),
                onBackToCart: _switchToCartMode,
                onOpenEtiket: _openEtiketDialog,
                onOpenCustomerDisplay: _openCustomerFacingDisplay,
                onOpenFullCheckout: widget.onCheckout,
                onProcessSettlement: ({
                  required paymentMethodIndex,
                  required paymentMethodName,
                  required tenderAmount,
                  required changeAmount,
                  required bankOrInsurance,
                  required refOrSepCode,
                  required autoPrintReceipt,
                }) =>
                    _handleSettlement(
                  paymentMethodIndex: paymentMethodIndex,
                  paymentMethodName: paymentMethodName,
                  tenderAmount: tenderAmount,
                  changeAmount: changeAmount,
                  bankOrInsurance: bankOrInsurance,
                  refOrSepCode: refOrSepCode,
                  autoPrintReceipt: autoPrintReceipt,
                  grandTotal: grandTotal,
                ),
              )
            : Column(
                key: const ValueKey('CartItemsView'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header & Pasien
                  PharmacyCartHeader(
                    cartItemCount: widget.cart.length,
                    totalQty: totalQty,
                    selectedPatient: widget.selectedPatient,
                    medicalRecordNumber: widget.medicalRecordNumber,
                    selectedDoctor: widget.selectedDoctor,
                    queueNumber: widget.queueNumber,
                    patientAllergies: widget.patientAllergies,
                    onClearCart: widget.onClearCart,
                    onChangePatient: widget.onChangePatient,
                    onClose: widget.onClose,
                  ),

                  // 2. Daftar Item Keranjang
                  Expanded(
                    child: widget.cart.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 68,
                                    height: 68,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          primaryEmerald.withValues(alpha: 0.08),
                                          secondaryTeal.withValues(alpha: 0.04),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: primaryEmerald.withValues(alpha: 0.15)),
                                    ),
                                    child: const Icon(Icons.shopping_basket_outlined, size: 30, color: primaryEmerald),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'Keranjang Masih Kosong',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Pilih sediaan obat dari katalog di samping atau scan barcode kemasan untuk memuat obat.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 11.5, color: textMuted, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Builder(
                            builder: (context) {
                              final cartKeys = widget.cart.keys.toList(growable: false);
                              return ListView.separated(
                                padding: const EdgeInsets.all(12),
                                itemCount: cartKeys.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final cartKey = cartKeys[index];
                                  final qty = widget.cart[cartKey]!;
                                  final baseId = cartKey.contains(':') ? cartKey.split(':').first : cartKey;
                                  final item = widget.drugItemsById != null
                                      ? (widget.drugItemsById![baseId.toString()] ?? <String, dynamic>{})
                                      : widget.drugItems.firstWhere(
                                          (e) => e['id'].toString() == baseId.toString(),
                                          orElse: () => <String, dynamic>{},
                                        );
                                  final currentUnit = cartKey.contains(':')
                                      ? cartKey.split(':').last
                                      : (item['selectedUnit'] ?? item['unit'] ?? 'TAB');

                              final rawUnits = item['units'];
                              final List<Map<String, dynamic>> units = [];
                              if (rawUnits is List) {
                                for (final u in rawUnits) {
                                  if (u is Map) {
                                    units.add(Map<String, dynamic>.from(u));
                                  }
                                }
                              }

                              num basePrice = (item['price'] as num? ?? 0);
                              if (units.isEmpty) {
                                units.add({'name': currentUnit, 'price': basePrice, 'conversion': 1});
                              }

                              if (units.length == 1) {
                                final uName = units.first['name']?.toString().toUpperCase() ?? 'TAB';
                                final p = (units.first['price'] as num?) ?? basePrice;
                                if (uName == 'TAB' || uName == 'TABLET' || uName == 'KAPLET' || uName == 'KAPSUL' || uName == 'PIL') {
                                  if (!units.any((u) => u['name'] == 'STRIP')) {
                                    units.add({'name': 'STRIP', 'price': (p * 10).round(), 'conversion': 10});
                                  }
                                  if (!units.any((u) => u['name'] == 'BOX')) {
                                    units.add({'name': 'BOX', 'price': (p * 100).round(), 'conversion': 100});
                                  }
                                } else if (uName == 'STRIP') {
                                  if (!units.any((u) => u['name'] == 'TAB')) {
                                    units.insert(0, {'name': 'TAB', 'price': (p / 10).round(), 'conversion': 1});
                                  }
                                  if (!units.any((u) => u['name'] == 'BOX')) {
                                    units.add({'name': 'BOX', 'price': (p * 10).round(), 'conversion': 10});
                                  }
                                } else if (!units.any((u) => u['name'] == 'BOX')) {
                                  units.add({'name': 'BOX', 'price': (p * 10).round(), 'conversion': 10});
                                }
                              }

                              num price = basePrice;
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

                              final rawImg = item['imageUrl'] ?? item['image'] ?? item['image_url'];
                              final String? imgUrl = ProductCatalogService.resolveImageUrl(rawImg?.toString());

                              return PharmacyCartItemTile(
                                cartKey: cartKey,
                                qty: qty,
                                item: item,
                                units: units,
                                currentUnit: currentUnit,
                                price: price,
                                itemTotal: itemTotal,
                                isRx: isRx,
                                isAlkes: isAlkes,
                                batch: batch,
                                imgUrl: imgUrl,
                                onAddToCart: () => widget.onAddToCart(cartKey),
                                onRemoveFromCart: () => widget.onRemoveFromCart(cartKey),
                                onShowUnitPicker: () => _showUnitPicker(context, cartKey, units, currentUnit),
                              );
                            },
                          );
                        },
                      ),
                  ),

                  // 3. Ringkasan Finansial & CTA Pembayaran
                  PharmacyCartSummary(
                    totalQty: totalQty,
                    subtotal: widget.totalPrice,
                    effectiveTuslah: effectiveTuslah,
                    taxEnabled: taxEnabled,
                    taxRate: taxRate,
                    taxName: taxName,
                    taxInclusive: taxInclusive,
                    taxAmount: taxAmount,
                    grandTotal: grandTotal,
                    hasItems: widget.cart.isNotEmpty,
                    onProceedToPayment: _switchToTenderMode,
                  ),
                ],
              ),
      ),
    );
  }
}
