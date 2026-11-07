import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';
import '../../core/utils/audio_helper.dart';
import '../../core/storage/session_storage.dart';
import '../shared_pos/product_catalog_service.dart';
import '../shared_pos/pos_checkout_service.dart';
import '../shared_pos/shift_service.dart';
import '../shared_pos/shift_modal.dart';
import '../shared_pos/sales_history_drawer.dart';
import '../shared_pos/printer_settings_modal.dart';
import 'services/pharmacy_catalog_service.dart';
import 'widgets/pharmacy_patient_dialog.dart';
import 'widgets/pharmacy_cart_panel.dart';
import 'widgets/pharmacy_queue_modal.dart';
import 'widgets/pharmacy_stock_alert_modal.dart';
import 'widgets/pharmacy_shift_report_modal.dart';
import 'widgets/pharmacy_prescription_review_modal.dart';
import 'widgets/pharmacy_medical_records_modal.dart';
import 'widgets/pos/pharmacy_pos_header.dart';
import 'widgets/pos/pharmacy_patient_banner.dart';
import 'widgets/pos/pharmacy_search_and_categories.dart';
import 'widgets/pos/pharmacy_floating_cart_drawer.dart';
import 'widgets/pos/pharmacy_barcode_dialog.dart';
import 'widgets/pos/pharmacy_patient_source_sheet.dart';
import 'widgets/pos/pharmacy_catalog_view.dart';
import 'widgets/pos/pharmacy_pos_cart_bridge.dart';
import 'pharmacy_service.dart';
import 'pharmacy_checkout_screen.dart';

export 'widgets/pos/pharmacy_pos_cart_bridge.dart';

class PharmacyPosScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const PharmacyPosScreen({super.key, this.onLogout});

  @override
  State<PharmacyPosScreen> createState() => _PharmacyPosScreenState();
}

class _PharmacyPosScreenState extends State<PharmacyPosScreen> {
  int _selectedCategoryIndex = 0;
  final Map<String, int> _cart = {};
  num _totalPrice = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Clinical Patient Context
  String _selectedPatient = 'Pelanggan Umum (Walk-in)';
  String _selectedDoctor = '-';
  String _queueNumber = '-';
  String _medicalRecordNumber = '-';
  String _patientCategory = 'Umum';
  String _patientAllergies = '';
  bool _isPrescriptionValidated = false;

  bool get _isClinicPatientLoaded =>
      (_queueNumber != '-' && _queueNumber.isNotEmpty) ||
      (_medicalRecordNumber != '-' && _medicalRecordNumber.isNotEmpty) ||
      (_selectedPatient != 'Pelanggan Umum (Walk-in)' && _selectedPatient.isNotEmpty);

  bool _isLoadingCatalog = false;
  bool _isSearchingRemote = false;
  Timer? _searchDebounce;
  String? _syncError; // ignore: unused_field
  bool _isGridView = true;

  // Selected quick payment mode in mobile floating drawer
  int _mobilePaymentMode = 0; // 0: Tunai, 1: QRIS, 2: Debit, 3: Asuransi

  List<String> _categories = const ['Semua'];
  final List<Map<String, dynamic>> _drugItems = [];
  final Map<String, Map<String, dynamic>> _drugItemsById = {};
  final Map<String, Map<String, dynamic>> _drugItemsByCode = {};
  final Map<String, int> _drugQuantityCache = {};
  final Set<String> _remoteSearchMatchIds = {};

  void _syncDrugItemsIndex() {
    _drugItemsById.clear();
    _drugItemsByCode.clear();
    for (final item in _drugItems) {
      final id = item['id']?.toString();
      if (id != null) {
        _drugItemsById[id] = item;
        _drugItemsByCode[id.toLowerCase()] = item;
      }
      final sku = item['sku']?.toString().toLowerCase().trim();
      if (sku != null && sku.isNotEmpty && sku != '-') {
        _drugItemsByCode[sku] = item;
      }
      final barcode = item['barcode']?.toString().toLowerCase().trim();
      if (barcode != null && barcode.isNotEmpty && barcode != '-') {
        _drugItemsByCode[barcode] = item;
      }
    }
  }

  void _syncCartQuantityCache() {
    _drugQuantityCache.clear();
    _drugQuantityCache.addAll(PharmacyPosCartBridge.buildCartQuantityMap(_cart));
  }

  List<String> _ensureCategories(List<String> raw) {
    final list = <String>['Semua'];
    for (final c in raw) {
      final clean = c.trim();
      if (clean.isNotEmpty && clean != 'Semua' && clean != 'Umum') {
        if (!list.contains(clean)) list.add(clean);
      }
    }
    return list;
  }

  /// Tuslah/embalase dari konfigurasi tenant (/v1/pos/config), bukan hardcode.
  num get _tuslahFee => PharmacyService.instance.tuslahFee.value;

  @override
  void initState() {
    super.initState();
    PharmacyService.instance.activePatient.addListener(_onActivePatientChanged);
    PharmacyService.instance.fetchTuslahFee().then((_) {
      if (mounted) setState(() {});
    });
    _fetchCatalog().then((_) {
      if (mounted) _restoreCart();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkShiftStatus();
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    PharmacyCatalogService.instance.clearMemoryCache();
    _fetchCatalog();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    PharmacyService.instance.activePatient.removeListener(_onActivePatientChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onActivePatientChanged() {
    final data = PharmacyService.instance.activePatient.value;
    if (data != null && mounted) {
      setState(() {
        _selectedPatient = data.patient;
        _selectedDoctor = data.doctor;
        _queueNumber = data.queueNumber;
        _medicalRecordNumber = data.medicalRecordNumber;
        _patientCategory = data.patientCategory;
        _patientAllergies = data.allergies;

        // Auto-populate obat resep dokter yang telah diverifikasi ke keranjang kasir
        if (data.prescribedDrugs.isNotEmpty && _drugItems.isNotEmpty) {
          for (final drugStr in data.prescribedDrugs) {
            final cleanDrugName = drugStr.contains('(')
                ? drugStr.split('(').first.trim().toLowerCase()
                : drugStr.trim().toLowerCase();

            int requestedQty = 1;
            final qtyMatch = RegExp(r'(\d+)\s*(?:sediaan|tablet|tab|kapsul|pcs|strip|bungkus|unit)', caseSensitive: false).firstMatch(drugStr);
            if (qtyMatch != null && qtyMatch.group(1) != null) {
              requestedQty = int.tryParse(qtyMatch.group(1)!) ?? 1;
            }

            final match = _drugItems.firstWhere(
              (item) {
                final itemName = (item['name'] ?? '').toString().toLowerCase();
                return itemName.contains(cleanDrugName) || cleanDrugName.contains(itemName);
              },
              orElse: () => <String, dynamic>{},
            );

            if (match.isNotEmpty) {
              final baseId = match['id'].toString();
              final targetUnit = match['selectedUnit'] ?? match['unit'] ?? 'TAB';
              final fullKey = '$baseId:$targetUnit';
              _cart[fullKey] = requestedQty;
            }
          }
          _calculateTotal();
          _persistCart();
        }
      });
    }
  }

  void _persistCart() {
    if (_cart.isEmpty) {
      SessionStorage.instance.clearDraftCart('pharmacy');
    } else {
      SessionStorage.instance.saveDraftCart('pharmacy', jsonEncode(_cart));
    }
  }

  void _restoreCart() {
    try {
      final str = SessionStorage.instance.getDraftCart('pharmacy');
      if (str != null && str.isNotEmpty && _cart.isEmpty) {
        final decoded = jsonDecode(str);
        if (decoded is Map) {
          setState(() {
            for (final entry in decoded.entries) {
              final qty = int.tryParse(entry.value.toString()) ?? 0;
              if (qty > 0) {
                _cart[entry.key.toString()] = qty;
              }
            }
            _calculateTotal();
          });
        }
      }
    } catch (e) {
      debugPrint('[PharmacyPosScreen] Gagal memulihkan draft cart: $e');
    }
  }

  Future<void> _checkShiftStatus() async {
    try {
      final status = await ShiftService.instance.getShiftStatus();
      if (!status.isOpen && mounted) {
        ShiftDialogs.showOpenShiftDialog(
          context,
          onOpened: (_) => setState(() {}),
        );
      }
    } catch (e) {
      debugPrint('[PharmacyPosScreen] Gagal cek status shift: $e');
    }
  }

  Map<String, dynamic> _posProductToDrugMap(PosProduct p) =>
      PharmacyPosCartBridge.posProductToDrugMap(p);

  void _mergeRemoteProducts(List<PosProduct> products) {
    if (products.isEmpty || !mounted) return;
    final existingIds = _drugItems.map((e) => e['id'].toString()).toSet();
    final newCategories = Set<String>.from(_categories);
    bool changed = false;

    for (final p in products) {
      final mapped = _posProductToDrugMap(p);
      if (existingIds.contains(p.id)) {
        final idx = _drugItems.indexWhere((e) => e['id'].toString() == p.id);
        if (idx != -1) {
          _drugItems[idx] = mapped;
          changed = true;
        }
      } else {
        _drugItems.add(mapped);
        existingIds.add(p.id);
        if (p.category.isNotEmpty && p.category != 'Semua' && p.category != 'Umum') {
          newCategories.add(p.category);
        }
        changed = true;
      }
    }

    if (changed && mounted) {
      _syncDrugItemsIndex();
      setState(() {
        _categories = _ensureCategories(newCategories.toList());
      });
    }
  }

  void _onSearchChanged(String val) {
    setState(() {
      _searchQuery = val;
      if (val.trim().length < 2) {
        _remoteSearchMatchIds.clear();
      }
    });
    _searchDebounce?.cancel();
    final trimmed = val.trim();
    if (trimmed.length < 2) {
      if (_isSearchingRemote) {
        setState(() => _isSearchingRemote = false);
      }
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 320), () async {
      if (!mounted) return;
      setState(() => _isSearchingRemote = true);
      try {
        final results = await PharmacyCatalogService.instance.searchProductsRemote(trimmed);
        if (mounted && _searchQuery.trim() == trimmed) {
          _remoteSearchMatchIds
            ..clear()
            ..addAll(results.map((p) => p.id.toString()));
          _mergeRemoteProducts(results);
          setState(() {});
        }
      } finally {
        if (mounted) {
          setState(() => _isSearchingRemote = false);
        }
      }
    });
  }

  Future<void> _fetchCatalog() async {
    setState(() => _isLoadingCatalog = true);
    try {
      final catalog = await PharmacyCatalogService.instance.fetchCatalog();
      if (mounted) {
        setState(() {
          _categories = _ensureCategories(catalog.categories);
          _selectedCategoryIndex = 0;
          _drugItems.clear();
          _drugItems.addAll(catalog.products.map(_posProductToDrugMap));
          _syncDrugItemsIndex();
          _isLoadingCatalog = false;
          _syncError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCatalog = false;
          _syncError = 'Gagal Sinkronisasi';
        });
      }
    }
  }

  Future<void> _syncOfflineQueue() async {
    AudioHelper.tapFeedback();
    final count = PosCheckoutService.instance.pendingOfflineCount;
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada antrean transaksi offline.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Menyinkronkan $count transaksi offline ke server...')),
    );

    final res = await PosCheckoutService.instance.syncOfflineQueue();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil sinkron: ${res['synced']} transaksi. Tersisa: ${res['remaining']}'),
          backgroundColor: res['remaining'] == 0 ? const Color(0xFF059669) : const Color(0xFFEA580C),
        ),
      );
    }
  }

  void _showChangePatientOptions() {
    PharmacyPatientSourceSheet.show(
      context: context,
      isClinicPatientLoaded: _isClinicPatientLoaded,
      onOpenQueue: _openQueueModal,
      onOpenManualDialog: _changePatientDialog,
      onResetToWalkIn: () {
        setState(() {
          _selectedPatient = 'Pelanggan Umum (Walk-in)';
          _selectedDoctor = '-';
          _queueNumber = '-';
          _medicalRecordNumber = '-';
          _patientCategory = 'Umum';
          _patientAllergies = '';
          _isPrescriptionValidated = false;
        });
      },
    );
  }

  void _openQueueModal() {
    AudioHelper.tapFeedback();
    PharmacyQueueModal.show(
      context,
      onSelectPatient: (data) {
        setState(() {
          _selectedPatient = data.patient;
          _selectedDoctor = data.doctor;
          _queueNumber = data.queueNumber;
          _medicalRecordNumber = data.medicalRecordNumber;
          _patientCategory = data.patientCategory;
          _patientAllergies = data.allergies;
          _isPrescriptionValidated = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pasien antrean ${data.queueNumber} (${data.patient}) berhasil dimuat ke kasir.'),
            backgroundColor: const Color(0xFF059669),
            duration: const Duration(seconds: 3),
          ),
        );
      },
    );
  }

  void _openStockAlertModal() {
    AudioHelper.tapFeedback();
    PharmacyStockAlertModal.show(
      context,
      catalogItems: _drugItems,
      onSelectDrug: (id) {
        _addToCart(id);
      },
    );
  }

  void _openPrescriptionReviewModal() {
    AudioHelper.tapFeedback();
    final patientData = PharmacyPatientData(
      patient: _selectedPatient,
      doctor: _selectedDoctor,
      queueNumber: _queueNumber,
      medicalRecordNumber: _medicalRecordNumber,
      patientCategory: _patientCategory,
      allergies: _patientAllergies,
    );
    final cartItems = _buildPosCartItems();

    PharmacyPrescriptionReviewModal.show(
      context,
      patientData: patientData,
      cartItems: cartItems,
      onApprove: () {
        setState(() => _isPrescriptionValidated = true);
        if (_cart.isEmpty && _drugItems.isNotEmpty) {
          _addToCart(_drugItems.first['id'].toString());
        }
      },
    );
  }

  void _openMedicalRecordsModal() {
    AudioHelper.tapFeedback();
    final patientData = PharmacyPatientData(
      patient: _selectedPatient,
      doctor: _selectedDoctor,
      queueNumber: _queueNumber,
      medicalRecordNumber: _medicalRecordNumber,
      patientCategory: _patientCategory,
      allergies: _patientAllergies,
    );
    PharmacyMedicalRecordsModal.show(
      context,
      initialRm: _medicalRecordNumber,
      patientName: _selectedPatient,
      patientData: patientData,
    );
  }

  void _openShiftReportModal() {
    AudioHelper.tapFeedback();
    PharmacyShiftReportModal.show(
      context,
      onShiftClosed: () {
        setState(() {});
      },
    );
  }

  void _changePatientDialog() {
    AudioHelper.tapFeedback();
    PharmacyPatientDialog.show(
      context: context,
      initialPatient: _selectedPatient,
      initialDoctor: _selectedDoctor,
      initialQueueNumber: _queueNumber,
      initialMedicalRecordNumber: _medicalRecordNumber,
      initialAllergies: _patientAllergies,
      onSave: (data) {
        setState(() {
          _selectedPatient = data.patient;
          _selectedDoctor = data.doctor;
          _queueNumber = data.queueNumber;
          _medicalRecordNumber = data.medicalRecordNumber;
          _patientCategory = data.patientCategory;
          _patientAllergies = data.allergies;
          _isPrescriptionValidated = false;
        });
      },
    );
  }

  Future<bool> _resolveAndAddBarcode(String rawCode) async {
    final code = rawCode.trim().toLowerCase();
    if (code.isEmpty) return false;

    final match = _drugItemsByCode[code] ??
        _drugItems.firstWhere(
          (it) =>
              it['sku']?.toString().toLowerCase() == code ||
              it['barcode']?.toString().toLowerCase() == code ||
              it['id']?.toString().toLowerCase() == code,
          orElse: () => <String, dynamic>{},
        );

    if (match.isNotEmpty) {
      _addToCart(match['id'].toString());
      AudioHelper.actionFeedback();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${match['name']} ditambahkan ke keranjang resep.'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
      return true;
    }

    // Jika belum ada di memori lokal, cari lewat endpoint scan/Scout server Apotek
    final remoteProduct = await PharmacyCatalogService.instance.scanBarcodeRemote(rawCode.trim());
    if (remoteProduct != null && mounted) {
      _mergeRemoteProducts([remoteProduct]);
      _addToCart(remoteProduct.id);
      AudioHelper.actionFeedback();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ ${remoteProduct.name} ditemukan dari katalog & ditambahkan ke keranjang.'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
      return true;
    }

    return false;
  }

  void _openBarcodeScanner() {
    PharmacyBarcodeDialog.show(
      context: context,
      onScanBarcode: _resolveAndAddBarcode,
    );
  }

  num _getPriceForCartKey(String key, Map<String, dynamic> item) =>
      PharmacyPosCartBridge.getPriceForCartKey(key, item);

  int _getCartQuantityForDrug(dynamic id) =>
      PharmacyPosCartBridge.getCartQuantityForDrug(id, _cart, quantityCache: _drugQuantityCache);

  List<PosCartItem> _buildPosCartItems() =>
      PharmacyPosCartBridge.buildPosCartItems(_cart, _drugItems, drugItemsById: _drugItemsById);

  void _onChangeCartItemUnit(String oldKey, String newUnit) {
    AudioHelper.tapFeedback();
    setState(() {
      final qty = _cart.remove(oldKey) ?? 1;
      final baseId = oldKey.contains(':') ? oldKey.split(':').first : oldKey;
      final newKey = '$baseId:$newUnit';
      _cart[newKey] = (_cart[newKey] ?? 0) + qty;
      _calculateTotal();
      _persistCart();
    });
  }

  void _addToCart(String id, [String? unit]) {
    final baseId = id.contains(':') ? id.split(':').first : id;
    final item = _drugItemsById[baseId.toString()] ??
        _drugItems.firstWhere(
          (e) => e['id'].toString() == baseId.toString(),
          orElse: () => <String, dynamic>{},
        );
    final stock = (item['stock'] as num? ?? 0).toInt();
    if (stock <= 0) {
      AudioHelper.errorFeedback();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Stok ${item['name'] ?? 'obat'} sedang habis.'),
            backgroundColor: const Color(0xFFBA1A1A),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    AudioHelper.tapFeedback();
    setState(() {
      final targetUnit = unit ??
          (id.contains(':')
              ? id.split(':').last
              : (item['selectedUnit'] ?? item['unit'] ?? 'TAB'));

      item['selectedUnit'] = targetUnit;
      final fullKey = '$baseId:$targetUnit';

      _cart[fullKey] = (_cart[fullKey] ?? 0) + 1;
      _calculateTotal();
      _persistCart();
    });
  }

  void _removeFromCart(String key) {
    AudioHelper.tapFeedback();
    setState(() {
      String actualKey = key;
      if (!_cart.containsKey(key)) {
        final match = _cart.keys.firstWhere(
          (k) => k == key || k.startsWith('$key:'),
          orElse: () => '',
        );
        if (match.isNotEmpty) actualKey = match;
      }
      final current = _cart[actualKey] ?? 0;
      if (current <= 1) {
        _cart.remove(actualKey);
      } else {
        _cart[actualKey] = current - 1;
      }
      _calculateTotal();
      _persistCart();
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      _drugQuantityCache.clear();
      _totalPrice = 0;
      _persistCart();
    });
  }

  void _calculateTotal() {
    _syncCartQuantityCache();
    num total = 0;
    _cart.forEach((key, qty) {
      final item = PharmacyPosCartBridge.getItemFromCartKeyFast(key, _drugItemsById);
      final price = _getPriceForCartKey(key, item);
      total += price * qty;
    });
    setState(() {
      _totalPrice = total;
    });
  }

  void _showCheckoutDialog() {
    if (_cart.isEmpty) return;

    final tuslah = _totalPrice > 0 ? PharmacyService.instance.tuslahFee.value : 0;
    final isTaxOn = PharmacyService.instance.taxEnabled.value;
    final taxRate = PharmacyService.instance.taxRate.value;
    final taxName = PharmacyService.instance.taxName.value;
    final isInclusive = PharmacyService.instance.taxInclusive.value;
    final taxAmount = (_totalPrice > 0 && isTaxOn && !isInclusive)
        ? (_totalPrice * (taxRate / 100))
        : 0;
    final grandTotal = _totalPrice + tuslah + taxAmount;

    final cartItems = _buildPosCartItems();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => PharmacyCheckoutScreen(
          items: cartItems,
          subtotal: _totalPrice,
          tuslahFee: tuslah,
          embalaseFee: 0,
          taxAmount: taxAmount,
          taxName: taxName,
          grandTotal: grandTotal,
          patientName: _selectedPatient,
          queueNumber: _queueNumber,
          medicalRecordNumber: _medicalRecordNumber,
          doctorName: _selectedDoctor,
          patientCategory: _patientCategory,
          patientAllergies: _patientAllergies,
          onCompleted: _onSettlementCompleted,
        ),
      ),
    );
  }

  void _onSettlementCompleted(PosCheckoutResult result, String paymentMethodName) {
    if (_queueNumber != '-' && _queueNumber.isNotEmpty) {
      PharmacyService.instance.completeQueueItem(
        queueNumber: _queueNumber,
        patientName: _selectedPatient,
      );
    }
    PharmacyService.instance.activePatient.value = null;

    setState(() {
      _cart.clear();
      _totalPrice = 0;
      _selectedPatient = 'Pelanggan Umum (Walk-in)';
      _selectedDoctor = '-';
      _queueNumber = '-';
      _medicalRecordNumber = '-';
      _patientCategory = 'Umum';
      _patientAllergies = '';
      _persistCart();
    });
  }

  void _openMobileCartSheet() {
    AudioHelper.tapFeedback();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 540,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: PharmacyCartPanel(
            cart: _cart,
            drugItems: _drugItems,
            drugItemsById: _drugItemsById,
            totalPrice: _totalPrice,
            tuslahFee: _tuslahFee,
            selectedPatient: _selectedPatient,
            selectedDoctor: _selectedDoctor,
            queueNumber: _queueNumber,
            medicalRecordNumber: _medicalRecordNumber,
            patientCategory: _patientCategory,
            patientAllergies: _patientAllergies,
            onChangePatient: () {
              Navigator.pop(ctx);
              _showChangePatientOptions();
            },
            onClearCart: () {
              _clearCart();
              Navigator.pop(ctx);
            },
            onAddToCart: _addToCart,
            onRemoveFromCart: _removeFromCart,
            onChangeCartItemUnit: _onChangeCartItemUnit,
            onCheckout: () {
              Navigator.pop(ctx);
              _showCheckoutDialog();
            },
            onClose: () => Navigator.pop(ctx),
            onSettlementSuccess: (result, method) {
              Navigator.pop(ctx);
              _onSettlementCompleted(result, method);
            },
          ),
        ),
      ),
    );
  }

  // Mobile Floating Cart Drawer (Sticky above Bottom Nav)
  Widget _buildMobileFloatingCartDrawer() {
    final totalItems = _cart.values.fold<int>(0, (sum, q) => sum + q);
    final grandTotal = _totalPrice + (_totalPrice > 0 ? _tuslahFee : 0);

    return PharmacyFloatingCartDrawer(
      totalItems: totalItems,
      grandTotal: grandTotal,
      selectedPaymentMode: _mobilePaymentMode,
      onSelectPaymentMode: (index) => setState(() => _mobilePaymentMode = index),
      onOpenCartSheet: _openMobileCartSheet,
      onCheckout: _showCheckoutDialog,
    );
  }

  // Top App Bar Header
  Widget _buildTopHeader(bool isMobile, double screenWidth) {
    final tenant = SessionStorage.instance.getTenantName() ?? 'Velora Pharmacy';
    final location = SessionStorage.instance.getLocationName() ?? tenant;
    final shift = ShiftService.instance.currentStatus;
    final isShiftOpen = shift?.isOpen == true;
    final cashier = (shift?.cashierName?.isNotEmpty == true ? shift?.cashierName : null) ??
        SessionStorage.instance.getUserName() ??
        'Kasir';
    final shiftText = isShiftOpen
        ? (shift?.openedAt != null
            ? 'Shift Aktif • ${shift!.openedAt!.hour.toString().padLeft(2, '0')}:${shift.openedAt!.minute.toString().padLeft(2, '0')}'
            : (shift?.shiftId != null ? 'Shift #${shift!.shiftId}' : 'Shift Aktif'))
        : 'Shift Tutup';

    return PharmacyPosHeader(
      isMobile: isMobile,
      screenWidth: screenWidth,
      tenant: tenant,
      location: location,
      isShiftOpen: isShiftOpen,
      shiftText: shiftText,
      cashier: cashier,
      isGridView: _isGridView,
      isLoadingCatalog: _isLoadingCatalog,
      pendingOfflineCount: PosCheckoutService.instance.pendingOfflineCount,
      onOpenShiftReport: _openShiftReportModal,
      onOpenQueue: _openQueueModal,
      onOpenHistory: () {
        AudioHelper.tapFeedback();
        SalesHistoryDrawer.show(
          context,
          storeName: tenant,
          storeAddress: SessionStorage.instance.getStoreAddress() ?? '',
          storePhone: SessionStorage.instance.getStorePhone() ?? '-',
          cashierName: SessionStorage.instance.getUserName() ?? 'Apoteker',
          accentColor: ClinicalPalette.primary,
        );
      },
      onToggleViewMode: () {
        AudioHelper.tapFeedback();
        setState(() => _isGridView = !_isGridView);
      },
      onSyncCatalog: () {
        if (!_isLoadingCatalog) _fetchCatalog();
      },
      onOpenPrescriptionReview: _openPrescriptionReviewModal,
      onOpenStockAlert: _openStockAlertModal,
      onOpenPrinterSettings: () => PrinterSettingsModal.show(context),
      onSyncOffline: _syncOfflineQueue,
      onLogout: widget.onLogout,
    );
  }

  // Clinical Context Patient Strip & Prescription Validation
  Widget _buildPatientBanner(bool isWide) {
    return PharmacyPatientBanner(
      isClinicPatientLoaded: _isClinicPatientLoaded,
      selectedPatient: _selectedPatient,
      queueNumber: _queueNumber,
      medicalRecordNumber: _medicalRecordNumber,
      selectedDoctor: _selectedDoctor,
      patientAllergies: _patientAllergies,
      isPrescriptionValidated: _isPrescriptionValidated,
      onOpenMedicalRecords: _openMedicalRecordsModal,
      onChangePatient: !_isClinicPatientLoaded ? _openQueueModal : _showChangePatientOptions,
      onReviewPrescription: _openPrescriptionReviewModal,
      isWide: isWide,
    );
  }

  // Search Field & Category Tabs
  Widget _buildSearchAndCategories() {
    return PharmacySearchAndCategories(
      searchController: _searchController,
      searchQuery: _searchQuery,
      isSearchingRemote: _isSearchingRemote,
      onSearchChanged: _onSearchChanged,
      onSearchSubmitted: (val) async {
        final trimmed = val.trim();
        if (trimmed.isEmpty) return;
        final isLikelyBarcode = !trimmed.contains(' ') &&
            (RegExp(r'^[0-9]{6,}$').hasMatch(trimmed) ||
                trimmed.toUpperCase().startsWith('VP-') ||
                _drugItems.any((item) {
                  final code = trimmed.toLowerCase();
                  return (item['barcode']?.toString().toLowerCase() == code) ||
                      (item['sku']?.toString().toLowerCase() == code);
                }));
        if (isLikelyBarcode) {
          final added = await _resolveAndAddBarcode(trimmed);
          if (added && mounted) {
            _searchController.clear();
            setState(() => _searchQuery = '');
          }
          return;
        }
        _searchDebounce?.cancel();
        setState(() => _isSearchingRemote = true);
        try {
          final results = await PharmacyCatalogService.instance.searchProductsRemote(trimmed);
          if (mounted && _searchQuery.trim() == trimmed) {
            _remoteSearchMatchIds
              ..clear()
              ..addAll(results.map((e) => e.id));
            _mergeRemoteProducts(results);
          }
        } finally {
          if (mounted) {
            setState(() => _isSearchingRemote = false);
          }
        }
      },
      onClearSearch: () {
        _searchDebounce?.cancel();
        _searchController.clear();
        setState(() {
          _searchQuery = '';
          _remoteSearchMatchIds.clear();
          _isSearchingRemote = false;
        });
      },
      onOpenBarcodeScanner: _openBarcodeScanner,
      categories: _categories,
      selectedCategoryIndex: _selectedCategoryIndex,
      onSelectCategory: (idx) {
        setState(() => _selectedCategoryIndex = idx);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 768;
    final isMobile = screenWidth < 600;

    final selectedCategoryName = _selectedCategoryIndex < _categories.length
        ? _categories[_selectedCategoryIndex]
        : 'Semua';

    final filteredItems = _drugItems.where((item) {
      final q = _searchQuery.toLowerCase().trim();
      final itemId = item['id'].toString();

      if (q.isNotEmpty && _remoteSearchMatchIds.contains(itemId)) {
        return true;
      }

      bool matchesCategory = true;
      if (_selectedCategoryIndex > 0 && selectedCategoryName != 'Semua') {
        final itemCat = (item['category'] ?? '').toString().toLowerCase().trim();
        final selCat = selectedCategoryName.toLowerCase().trim();

        final isItemBebasTerbatas = itemCat.contains('terbatas') || itemCat.contains('biru');
        final isItemBebas = (itemCat.contains('bebas') && !isItemBebasTerbatas) || itemCat.contains('hijau');
        final isItemKeras = !isItemBebas && !isItemBebasTerbatas && (
            item['isDotRed'] == true ||
            item['isPrescriptionOnly'] == true ||
            itemCat.contains('keras') ||
            itemCat.contains('rx')
        );

        if (selCat.contains('terbatas')) {
          matchesCategory = isItemBebasTerbatas;
        } else if (selCat == 'bebas' || selCat.contains('bebas') || selCat.contains('otc')) {
          matchesCategory = isItemBebas;
        } else if (selCat == 'keras' || selCat.contains('keras') || selCat.contains('rx')) {
          matchesCategory = isItemKeras;
        } else {
          matchesCategory = itemCat == selCat || itemCat.contains(selCat);
        }
      }

      if (q.isEmpty) return matchesCategory;

      final searchableBlob = [
        item['name'],
        item['sku'],
        item['barcode'],
        item['description'],
        item['fungsi'],
        item['kandungan'],
        item['klasifikasi'],
        item['sediaan'],
        item['category'],
      ].where((e) => e != null).map((e) => e.toString().toLowerCase()).join(' ');

      final expandedQ = PharmacyCatalogService.expandPharmacyQuery(q);
      final tokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
      final matchesSearch = searchableBlob.contains(q) ||
          (expandedQ != q && searchableBlob.contains(expandedQ)) ||
          (tokens.length > 1 && tokens.every((t) => searchableBlob.contains(t)));

      return matchesCategory && matchesSearch;
    }).toList();

    final catalogPane = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopHeader(isMobile, screenWidth),
        _buildPatientBanner(isWide),
        _buildSearchAndCategories(),

        // Catalog Grid or List
        Expanded(
          child: PharmacyCatalogView(
            isLoading: _isLoadingCatalog,
            isSearchingRemote: _isSearchingRemote,
            searchQuery: _searchQuery,
            items: filteredItems,
            isGridView: _isGridView,
            isMobile: isMobile,
            getCartQuantity: _getCartQuantityForDrug,
            onAddToCart: _addToCart,
            onRemoveFromCart: _removeFromCart,
            onSelectUnit: (id, unit) => _addToCart(id, unit),
            onSyncCatalog: _fetchCatalog,
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: isWide
            ? Row(
                children: [
                  Expanded(
                    flex: 65,
                    child: catalogPane,
                  ),
                  Container(
                    width: 1,
                    color: const Color(0xFFE2E8F0),
                  ),
                  Expanded(
                    flex: 35,
                    child: PharmacyCartPanel(
                      cart: _cart,
                      drugItems: _drugItems,
                      drugItemsById: _drugItemsById,
                      totalPrice: _totalPrice,
                      tuslahFee: _tuslahFee,
                      selectedPatient: _selectedPatient,
                      selectedDoctor: _selectedDoctor,
                      queueNumber: _queueNumber,
                      medicalRecordNumber: _medicalRecordNumber,
                      patientCategory: _patientCategory,
                      patientAllergies: _patientAllergies,
                      onChangePatient: _showChangePatientOptions,
                      onClearCart: _clearCart,
                      onAddToCart: _addToCart,
                      onRemoveFromCart: _removeFromCart,
                      onCheckout: _showCheckoutDialog,
                      onSettlementSuccess: _onSettlementCompleted,
                      onChangeCartItemUnit: _onChangeCartItemUnit,
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  catalogPane,
                  if (_cart.isNotEmpty)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _buildMobileFloatingCartDrawer(),
                    ),
                ],
              ),
      ),
    );
  }
}
