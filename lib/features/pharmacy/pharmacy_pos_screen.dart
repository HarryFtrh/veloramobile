import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';
import '../../core/utils/audio_helper.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/storage/session_storage.dart';
import '../shared_pos/offline_sync_badge.dart';
import '../shared_pos/product_catalog_service.dart';
import '../shared_pos/pos_checkout_service.dart';
import '../shared_pos/shift_service.dart';
import '../shared_pos/shift_modal.dart';
import '../shared_pos/sales_history_drawer.dart';
import '../shared_pos/printer_settings_modal.dart';
import 'widgets/pharmacy_patient_dialog.dart';
import 'widgets/pharmacy_drug_card.dart';
import 'widgets/pharmacy_cart_panel.dart';
import 'widgets/pharmacy_queue_modal.dart';
import 'widgets/pharmacy_stock_alert_modal.dart';
import 'widgets/pharmacy_shift_report_modal.dart';
import 'widgets/pharmacy_prescription_review_modal.dart';
import 'widgets/pharmacy_medical_records_modal.dart';
import 'pharmacy_service.dart';
import 'pharmacy_checkout_screen.dart';

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

  bool get _isClinicPatientLoaded =>
      (_queueNumber != '-' && _queueNumber.isNotEmpty) ||
      (_medicalRecordNumber != '-' && _medicalRecordNumber.isNotEmpty) ||
      (_selectedPatient != 'Pelanggan Umum (Walk-in)' && _selectedPatient.isNotEmpty);

  bool get _hasRxInCart {
    for (final key in _cart.keys) {
      final baseId = key.contains(':') ? key.split(':').first : key;
      final item = _drugItems.firstWhere(
        (it) => it['id'].toString() == baseId,
        orElse: () => const {},
      );
      if (item.isNotEmpty && (item['isDotRed'] == true || item['isPrescriptionOnly'] == true)) {
        return true;
      }
    }
    return false;
  }

  bool _isLoadingCatalog = false;
  String? _syncError; // ignore: unused_field
  bool _isGridView = true;

  // Selected quick payment mode in mobile floating drawer
  int _mobilePaymentMode = 0; // 0: Tunai, 1: QRIS, 2: Debit, 3: Asuransi

  final List<String> _baseCategories = [
    'Semua',
    'Obat Bebas (OTC)',
    'Obat Keras (Rx)',
    'Alat Kesehatan',
    'Resep Dokter',
  ];
  final List<String> _dynamicCategories = [];
  final List<Map<String, dynamic>> _drugItems = [];

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
  void dispose() {
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

  Future<void> _fetchCatalog() async {
    setState(() => _isLoadingCatalog = true);
    try {
      final catalog = await ProductCatalogService.instance.fetchCatalog();
      if (mounted) {
        setState(() {
          _dynamicCategories.clear();
          for (final c in catalog.categories) {
            if (!_baseCategories.contains(c) && !_dynamicCategories.contains(c)) {
              _dynamicCategories.add(c);
            }
          }
          _drugItems.clear();
          _drugItems.addAll(catalog.products.map((p) => {
            'id': p.id,
            'name': p.name,
            'sku': p.sku.isNotEmpty ? p.sku : (p.barcode.isNotEmpty ? p.barcode : '-'),
            'category': p.category,
            'price': p.price,
            'isDotRed': p.isPrescriptionOnly,
            'isPrescriptionOnly': p.isPrescriptionOnly,
            'batch': p.batches.isNotEmpty ? p.batches.first.batchNumber : '-',
            'ed': p.batches.isNotEmpty ? p.batches.first.expiryDate : '-',
            'stock': p.stock.toInt(),
            'unit': p.unit ?? 'TAB',
            'selectedUnit': p.units.isNotEmpty ? p.units.first.name : (p.unit ?? 'TAB'),
            'units': p.units.map((u) => u.toJson()).toList(),
            'imageUrl': p.imageUrl,
            'image': p.imageUrl,
            'description': p.description,
            'batches': p.batches.map((b) => {
              'id': b.id,
              'batch': b.batchNumber,
              'batch_number': b.batchNumber,
              'ed': b.expiryDate,
              'expiry_date': b.expiryDate,
              'stock': b.stock,
            }).toList(),
          }));
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
          backgroundColor: res['remaining'] == 0 ? const Color(0xFF059669) : const Color(0xFFF59E0B),
        ),
      );
    }
  }

  void _showChangePatientOptions() {
    AudioHelper.tapFeedback();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Sumber Data Pasien',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Muat data dari antrean resep poli klinik atau input identitas langsung',
                style: TextStyle(color: Color(0xFF6D7A72), fontSize: 12),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.people_outline_rounded, color: Color(0xFF059669)),
                ),
                title: const Text(
                  'Antrean Klinik & Billing Pasien',
                  style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                subtitle: const Text(
                  'Pilih pasien dari loket poli rawat jalan / dokter klinik',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6D7A72)),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF6D7A72)),
                onTap: () {
                  Navigator.pop(ctx);
                  _openQueueModal();
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.badge_outlined, color: Color(0xFF0D9488)),
                ),
                title: const Text(
                  'Edit Identitas Pasien Manual',
                  style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                subtitle: const Text(
                  'Ketik manual nama pasien, No. RM, dokter perujuk, dan alergi',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6D7A72)),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF6D7A72)),
                onTap: () {
                  Navigator.pop(ctx);
                  _changePatientDialog();
                },
              ),
              if (_isClinicPatientLoaded) ...[
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBA1A1A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_off_outlined, color: Color(0xFFBA1A1A)),
                  ),
                  title: const Text(
                    'Reset ke Pelanggan Walk-in (Umum)',
                    style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  subtitle: const Text(
                    'Hapus data pasien klinik & kembali ke transaksi umum',
                    style: TextStyle(fontSize: 11, color: Color(0xFF6D7A72)),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF6D7A72)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _selectedPatient = 'Pelanggan Umum (Walk-in)';
                      _selectedDoctor = '-';
                      _queueNumber = '-';
                      _medicalRecordNumber = '-';
                      _patientCategory = 'Umum';
                      _patientAllergies = '';
                    });
                  },
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
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
        });
      },
    );
  }

  void _openBarcodeScanner() {
    AudioHelper.tapFeedback();
    final barcodeCtrl = TextEditingController();
    String? localError;

    showDialog<void>(
      context: context,
      builder: (dCtx) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF059669)),
              SizedBox(width: 10),
              Text(
                'Pindai Barcode / SKU Obat',
                style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Arahkan scanner barcode atau ketik kode barcode/SKU sediaan obat:',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6D7A72)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: barcodeCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Kode Barcode / SKU',
                    hintText: 'Contoh: 8991234567...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    errorText: localError,
                    prefixIcon: const Icon(Icons.qr_code_rounded, color: Color(0xFF059669)),
                  ),
                  onSubmitted: (val) {
                    final code = val.trim().toLowerCase();
                    if (code.isEmpty) return;
                    final match = _drugItems.firstWhere(
                      (it) => it['sku']?.toString().toLowerCase() == code || it['id']?.toString() == code,
                      orElse: () => <String, dynamic>{},
                    );
                    if (match.isNotEmpty) {
                      _addToCart(match['id'].toString());
                      AudioHelper.actionFeedback();
                      Navigator.pop(dCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ ${match['name']} ditambahkan ke keranjang resep.'),
                          backgroundColor: const Color(0xFF059669),
                        ),
                      );
                    } else {
                      setDState(() => localError = 'Obat dengan barcode "$val" tidak ditemukan.');
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Batal', style: TextStyle(color: Color(0xFF6D7A72))),
            ),
            ElevatedButton(
              onPressed: () {
                final code = barcodeCtrl.text.trim().toLowerCase();
                if (code.isEmpty) return;
                final match = _drugItems.firstWhere(
                  (it) => it['sku']?.toString().toLowerCase() == code || it['id']?.toString() == code,
                  orElse: () => <String, dynamic>{},
                );
                if (match.isNotEmpty) {
                  _addToCart(match['id'].toString());
                  AudioHelper.actionFeedback();
                  Navigator.pop(dCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✓ ${match['name']} ditambahkan ke keranjang resep.'),
                      backgroundColor: const Color(0xFF059669),
                    ),
                  );
                } else {
                  setDState(() => localError = 'Obat dengan barcode "${barcodeCtrl.text}" tidak ditemukan.');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cari & Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getItemFromCartKey(String key) {
    final id = key.contains(':') ? key.split(':').first : key;
    return _drugItems.firstWhere(
      (m) => m['id'] == id,
      orElse: () => <String, dynamic>{'id': id, 'name': 'Obat', 'price': 0},
    );
  }

  String _getUnitFromCartKey(String key, Map<String, dynamic> item) {
    if (key.contains(':')) {
      return key.split(':').last;
    }
    return item['selectedUnit']?.toString() ?? item['unit']?.toString() ?? 'TAB';
  }

  num _getPriceForCartKey(String key, Map<String, dynamic> item) {
    final unit = _getUnitFromCartKey(key, item);
    final rawUnits = item['units'];
    if (rawUnits is List) {
      for (final u in rawUnits) {
        if (u is Map && u['name']?.toString().toUpperCase() == unit.toUpperCase()) {
          return (u['price'] as num?) ?? (item['price'] as num? ?? 0);
        }
      }
    }
    return item['price'] as num? ?? 0;
  }

  int _getCartQuantityForDrug(String id) {
    int total = 0;
    _cart.forEach((k, q) {
      final baseId = k.contains(':') ? k.split(':').first : k;
      if (baseId == id) {
        total += q;
      }
    });
    return total;
  }

  List<PosCartItem> _buildPosCartItems() {
    return _cart.entries.map((e) {
      final item = _getItemFromCartKey(e.key);
      final unit = _getUnitFromCartKey(e.key, item);
      final price = _getPriceForCartKey(e.key, item);
      final baseId = e.key.contains(':') ? e.key.split(':').first : e.key;

      return PosCartItem(
        productId: baseId,
        name: '${item['name']?.toString() ?? 'Obat'} ($unit)',
        price: price,
        quantity: e.value,
        batchNumber: item['batch']?.toString(),
        expiryDate: (item['ed'] ?? item['exp'])?.toString(),
        modifiers: {'Satuan': unit},
      );
    }).toList();
  }

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
    AudioHelper.tapFeedback();
    setState(() {
      final baseId = id.contains(':') ? id.split(':').first : id;
      final item = _drugItems.firstWhere(
        (e) => e['id'] == baseId,
        orElse: () => <String, dynamic>{},
      );
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
      final current = _cart[key] ?? 0;
      if (current <= 1) {
        _cart.remove(key);
      } else {
        _cart[key] = current - 1;
      }
      _calculateTotal();
      _persistCart();
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      _totalPrice = 0;
      _persistCart();
    });
  }

  void _calculateTotal() {
    num total = 0;
    _cart.forEach((key, qty) {
      final item = _getItemFromCartKey(key);
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
    const primaryEmerald = Color(0xFF059669);
    const darkSurface = Color(0xFF283044);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6D7A72).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Items summary & details toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: primaryEmerald,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$totalItems',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalItems Item Terpilih (Keranjang)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                      Text(
                        'Total: ${CurrencyFormatter.format(grandTotal)}',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: _openMobileCartSheet,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rincian',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.keyboard_arrow_up_rounded, size: 18, color: Colors.white.withValues(alpha: 0.8)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Payment mode pills
          Row(
            children: [
              _buildPaymentPill(0, 'Tunai'),
              const SizedBox(width: 6),
              _buildPaymentPill(1, 'QRIS'),
              const SizedBox(width: 6),
              _buildPaymentPill(2, 'Debit'),
              const SizedBox(width: 6),
              _buildPaymentPill(3, 'Asuransi'),
            ],
          ),
          const SizedBox(height: 10),

          // Action CTA
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _showCheckoutDialog,
              icon: const Icon(Icons.payments_rounded, size: 18),
              label: const Text(
                'Proses Pembayaran / Bayar Cepat',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00855D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentPill(int index, String label) {
    final isSelected = _mobilePaymentMode == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _mobilePaymentMode = index),
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0D9488) : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Top App Bar Header
  Widget _buildTopHeader(bool isMobile, double screenWidth) {
    const emeraldPrimary = ClinicalPalette.primary;
    const borderColor = Color(0xFFE2E8F0);
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
    final shiftBadge = isShiftOpen
        ? (shift?.shiftId != null ? 'Shift #${shift!.shiftId}' : 'Shift Aktif')
        : 'Shift Tutup';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Clinic Icon & Name & Branch (Stitch Precision)
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: emeraldPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: emeraldPrimary.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.local_hospital_rounded, color: emeraldPrimary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              tenant,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: emeraldPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: emeraldPrimary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: emeraldPrimary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Online',
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: emeraldPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF6D7A72)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Actions Cluster & Cashier Shift
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMobile && screenWidth >= 1050) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      cashier,
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      shiftText,
                      style: const TextStyle(fontSize: 9.5, color: Color(0xFF6D7A72)),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
              if (!isMobile && screenWidth >= 950) ...[
                InkWell(
                  onTap: _openShiftReportModal,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isShiftOpen
                          ? const Color(0xFF0D9488).withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          shiftBadge,
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isShiftOpen ? const Color(0xFF0D9488) : Colors.deepOrange.shade800,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.expand_more_rounded,
                          size: 13,
                          color: isShiftOpen ? const Color(0xFF0D9488) : Colors.deepOrange.shade800,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              const OfflineSyncBadge(showClock: false),
              const SizedBox(width: 4),
              if (!isMobile) ...[
                IconButton(
                  icon: const Icon(Icons.people_outline_rounded, size: 20, color: Color(0xFF0D9488)),
                  tooltip: 'Antrean Pasien & Billing',
                  onPressed: _openQueueModal,
                ),
              ],
              IconButton(
                icon: const Icon(Icons.receipt_long_rounded, size: 20, color: Color(0xFF6D7A72)),
                tooltip: 'Riwayat Transaksi',
                onPressed: () {
                  AudioHelper.tapFeedback();
                  SalesHistoryDrawer.show(
                    context,
                    storeName: SessionStorage.instance.getTenantName() ?? 'Velora Pharmacy',
                    storeAddress: SessionStorage.instance.getStoreAddress() ?? '',
                    storePhone: SessionStorage.instance.getStorePhone() ?? '-',
                    cashierName: SessionStorage.instance.getUserName() ?? 'Apoteker',
                    accentColor: emeraldPrimary,
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  _isGridView ? Icons.grid_view_rounded : Icons.view_list_rounded,
                  size: 20,
                  color: const Color(0xFF0D9488),
                ),
                tooltip: _isGridView ? 'Beralih ke List' : 'Beralih ke Grid',
                onPressed: () {
                  AudioHelper.tapFeedback();
                  setState(() => _isGridView = !_isGridView);
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFF6D7A72)),
                tooltip: 'Menu Tambahan',
                onSelected: (val) {
                  AudioHelper.tapFeedback();
                  switch (val) {
                    case 'sync':
                      if (!_isLoadingCatalog) _fetchCatalog();
                      break;
                    case 'queue':
                      _openQueueModal();
                      break;
                    case 'review':
                      _openPrescriptionReviewModal();
                      break;
                    case 'stock_alert':
                      _openStockAlertModal();
                      break;
                    case 'printer':
                      PrinterSettingsModal.show(context);
                      break;
                    case 'offline':
                      _syncOfflineQueue();
                      break;
                    case 'logout':
                      widget.onLogout?.call();
                      break;
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'sync',
                    child: Row(
                      children: [
                        Icon(Icons.sync_rounded, size: 18, color: _isLoadingCatalog ? Colors.grey : emeraldPrimary),
                        const SizedBox(width: 10),
                        const Text('Sinkronkan Katalog'),
                      ],
                    ),
                  ),
                  if (isMobile)
                    const PopupMenuItem(
                      value: 'queue',
                      child: Row(
                        children: [
                          Icon(Icons.people_outline_rounded, size: 18, color: Color(0xFF0D9488)),
                          SizedBox(width: 10),
                          Text('Antrean Pasien & Billing'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'review',
                    child: Row(
                      children: [
                        Icon(Icons.assignment_outlined, size: 18, color: Color(0xFF0D9488)),
                        SizedBox(width: 10),
                        Text('Telaah Resep & Skrining'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'stock_alert',
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFB45309)),
                        SizedBox(width: 10),
                        Text('Alert Kedaluwarsa & Stok FEFO'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'printer',
                    child: Row(
                      children: [
                        Icon(Icons.print_outlined, size: 18, color: Color(0xFF6D7A72)),
                        SizedBox(width: 10),
                        Text('Pengaturan Printer'),
                      ],
                    ),
                  ),
                  if (PosCheckoutService.instance.pendingOfflineCount > 0)
                    PopupMenuItem(
                      value: 'offline',
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_upload_outlined, size: 18, color: emeraldPrimary),
                          const SizedBox(width: 10),
                          Text('Sync Offline (${PosCheckoutService.instance.pendingOfflineCount})'),
                        ],
                      ),
                    ),
                  if (widget.onLogout != null)
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded, size: 18, color: Color(0xFFBA1A1A)),
                          SizedBox(width: 10),
                          Text('Keluar Kasir', style: TextStyle(color: Color(0xFFBA1A1A))),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Clinical Context Patient Strip
  Widget _buildPatientContextStrip(bool isWide) {
    // If wide screen (desktop split view) and walk-in, the cart panel on the right
    // already has the patient selector. Do not duplicate it on the left to keep screen tidy!
    if (isWide && !_isClinicPatientLoaded) {
      return const SizedBox.shrink();
    }

    const emeraldPrimary = ClinicalPalette.primary;
    const secondaryTeal = ClinicalPalette.secondary;
    const borderColor = Color(0xFFE2E8F0);

    final isWalkIn = !_isClinicPatientLoaded;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isWalkIn
                  ? emeraldPrimary.withValues(alpha: 0.1)
                  : secondaryTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isWalkIn ? Icons.storefront_outlined : Icons.badge_outlined,
              size: 18,
              color: isWalkIn ? emeraldPrimary : secondaryTeal,
            ),
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
                        isWalkIn ? 'Pelanggan Walk-in (Umum)' : _selectedPatient,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isWalkIn
                            ? emeraldPrimary.withValues(alpha: 0.1)
                            : secondaryTeal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isWalkIn ? 'Penjualan Bebas' : 'Antrean $_queueNumber',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isWalkIn ? emeraldPrimary : secondaryTeal,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isWalkIn
                      ? 'Penjualan kasir langsung tanpa antrean klinik'
                      : 'No. RM: $_medicalRecordNumber • Dokter: ${_selectedDoctor != '-' && _selectedDoctor.isNotEmpty ? _selectedDoctor : 'Resep Luar'}'
                          '${_patientAllergies.isNotEmpty ? " • Alergi: $_patientAllergies" : ""}',
                  style: TextStyle(
                    fontSize: 11,
                    color: _patientAllergies.isNotEmpty ? const Color(0xFFBA1A1A) : const Color(0xFF6D7A72),
                    fontWeight: _patientAllergies.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!isWalkIn) ...[
            InkWell(
              onTap: _openMedicalRecordsModal,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF8FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderColor),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.assignment_outlined, size: 14, color: secondaryTeal),
                    SizedBox(width: 4),
                    Text(
                      'Rekam Medis',
                      style: TextStyle(
                        color: secondaryTeal,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          InkWell(
            onTap: isWalkIn ? _openQueueModal : _showChangePatientOptions,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF8FF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isWalkIn ? Icons.people_outline_rounded : Icons.sync_alt_rounded,
                    size: 14,
                    color: emeraldPrimary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isWalkIn ? 'Muat Antrean' : 'Ganti',
                    style: const TextStyle(
                      color: emeraldPrimary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Prescription Prompt Info Banner
  Widget _buildPrescriptionValidationBanner() {
    // Only display when a clinical prescription patient is loaded OR when cart has Rx drugs!
    if (!_isClinicPatientLoaded && !_hasRxInCart) {
      return const SizedBox.shrink();
    }

    const secondaryTeal = ClinicalPalette.secondary;

    return InkWell(
      onTap: _openPrescriptionReviewModal,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: secondaryTeal.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: secondaryTeal.withValues(alpha: 0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.health_and_safety_outlined, size: 18, color: secondaryTeal),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Penjualan Resep / Obat Keras Aktif (7 Benar)',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Sediaan bertanda Rx / resep terdeteksi. Buka telaah klinis & SIP dokter.',
                    style: TextStyle(fontSize: 10, color: Color(0xFF6D7A72)),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Telaah Klinis',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: secondaryTeal,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 16, color: secondaryTeal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Search & Barcode Input
  Widget _buildSearchField() {
    const emeraldPrimary = ClinicalPalette.primary;
    const borderColor = Color(0xFFE2E8F0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SizedBox(
        height: 42,
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          onSubmitted: (val) {
            final trimmed = val.trim();
            if (trimmed.isEmpty) return;
            for (final it in _drugItems) {
              if (it['sku']?.toString().toLowerCase() == trimmed.toLowerCase()) {
                _addToCart(it['id'].toString());
                AudioHelper.actionFeedback();
                _searchController.clear();
                setState(() => _searchQuery = '');
                break;
              }
            }
          },
          style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: 'Cari obat, SKU, kandungan zat aktif, atau scan barcode...',
            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF6D7A72)),
            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF6D7A72)),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF6D7A72)),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 18, color: emeraldPrimary),
                  tooltip: 'Scan Barcode',
                  onPressed: _openBarcodeScanner,
                ),
              ],
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: emeraldPrimary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          ),
        ),
      ),
    );
  }

  // Horizontal Category Tabs
  Widget _buildCategoryTabs() {
    final allCategories = [..._baseCategories, ..._dynamicCategories];
    const emeraldPrimary = ClinicalPalette.primary;
    const borderColor = Color(0xFFE2E8F0);

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: allCategories.length,
        itemBuilder: (context, idx) {
          final isSelected = idx == _selectedCategoryIndex;
          final catName = allCategories[idx];
          final isRx = catName.contains('Keras') || catName.contains('Rx');

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                AudioHelper.tapFeedback();
                setState(() => _selectedCategoryIndex = idx);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? emeraldPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? emeraldPrimary : borderColor,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: emeraldPrimary.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isRx && !isSelected) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFBA1A1A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      catName,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: isSelected ? Colors.white : const Color(0xFF3D4A42),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 768;
    final isMobile = screenWidth < 600;

    final allCategories = [..._baseCategories, ..._dynamicCategories];
    final selectedCategoryName = _selectedCategoryIndex < allCategories.length
        ? allCategories[_selectedCategoryIndex]
        : 'Semua';

    final filteredItems = _drugItems.where((item) {
      bool matchesCategory = true;
      if (_selectedCategoryIndex > 0) {
        if (selectedCategoryName == 'Obat Bebas (OTC)') {
          matchesCategory = item['isDotRed'] != true && item['isPrescriptionOnly'] != true;
        } else if (selectedCategoryName == 'Obat Keras (Rx)') {
          matchesCategory = item['isDotRed'] == true || item['isPrescriptionOnly'] == true;
        } else if (selectedCategoryName == 'Alat Kesehatan') {
          matchesCategory = (item['category']?.toString().toLowerCase().contains('alkes') ?? false) ||
              (item['category']?.toString().toLowerCase().contains('alat') ?? false);
        } else if (selectedCategoryName == 'Resep Dokter') {
          matchesCategory = item['isDotRed'] == true || item['isPrescriptionOnly'] == true;
        } else {
          matchesCategory = item['category'] == selectedCategoryName;
        }
      }

      final q = _searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          item['name'].toString().toLowerCase().contains(q) ||
          item['sku'].toString().toLowerCase().contains(q) ||
          (item['category'] != null && item['category'].toString().toLowerCase().contains(q));

      return matchesCategory && matchesSearch;
    }).toList();

    final catalogPane = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopHeader(isMobile, screenWidth),
        _buildPatientContextStrip(isWide),
        _buildPrescriptionValidationBanner(),
        _buildSearchField(),
        _buildCategoryTabs(),

        // Catalog Grid or List
        Expanded(
          child: _isLoadingCatalog
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF059669)),
                      SizedBox(height: 16),
                      Text(
                        'Menghubungkan ke Database Velora...',
                        style: TextStyle(color: Color(0xFF6D7A72), fontSize: 13),
                      ),
                    ],
                  ),
                )
              : filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medication_liquid_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Tidak ada obat yang cocok dengan "$_searchQuery"'
                                : 'Katalog Obat Belum Terisi',
                            style: const TextStyle(color: Color(0xFF6D7A72), fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _fetchCatalog,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Sinkronkan Katalog Obat'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF059669),
                              side: const BorderSide(color: Color(0xFF059669)),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _isGridView
                      ? GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: isMobile ? 220 : 250,
                            childAspectRatio: isMobile ? 0.82 : 0.86,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                          ),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final qty = _getCartQuantityForDrug(item['id']);
                            return PharmacyDrugCard(
                              item: item,
                              quantity: qty,
                              onAdd: () => _addToCart(item['id']),
                              onRemove: () => _removeFromCart(item['id']),
                              onSelectUnit: (unit) => _addToCart(item['id'], unit),
                            );
                          },
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: filteredItems.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final qty = _getCartQuantityForDrug(item['id']);
                            return PharmacyDrugRow(
                              item: item,
                              quantity: qty,
                              onAdd: () => _addToCart(item['id']),
                              onRemove: () => _removeFromCart(item['id']),
                              onSelectUnit: (unit) => _addToCart(item['id'], unit),
                            );
                          },
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
