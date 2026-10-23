import 'package:flutter/material.dart';
import '../../core/network/api_exception.dart';
import '../kitchen/kitchen_service.dart';
import '../shared_pos/product_catalog_service.dart';
import '../shared_pos/shift_service.dart';
import '../tables/table_service.dart';
import 'billing.dart';
import 'fnb_register_service.dart';
import 'modifiers.dart';

export 'fnb_register_service.dart' show RegisterLine;

enum OrderType { dineIn, takeaway, online }

/// State kasir FnB: mengelola katalog produk, filter kategori & pencarian,
/// keranjang belanja (lines), meja tamu, sinkronisasi pesanan KDS dapur, dan kalkulasi tagihan.
class RegisterController extends ChangeNotifier {
  RegisterController({FnbRegisterService? service})
      : _service = service ?? FnbRegisterService.instance {
    ShiftService.instance.addListener(_onShiftChanged);
  }

  void _onShiftChanged() {
    final s = ShiftService.instance.currentStatus;
    final newShiftId = (s != null && s.isOpen) ? s.shiftId : null;
    if (shiftId != newShiftId) {
      shiftId = newShiftId;
      if (shiftId == null) {
        reset();
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    ShiftService.instance.removeListener(_onShiftChanged);
    super.dispose();
  }

  final FnbRegisterService _service;

  List<PosProduct> products = const [];
  List<String> categories = const ['Semua'];
  List<ModifierGroup> modifierGroups = const [];
  String category = 'Semua';
  String search = '';
  BillingSettings? billing;
  String? loadError;
  bool loading = true;
  bool busy = false;
  String? shiftId;

  final List<RegisterLine> lines = [];
  OrderType orderType = OrderType.takeaway;
  CafeTableInfo? table;
  String customerName = '';
  String? existingOrderId;

  // Diskon Member / Promosi Toko / Voucher banner
  StorePromotion? activePromotion;
  String? activeVoucherCode;
  double voucherDiscountAmount = 0;
  String? memberTier; // e.g. 'Gold Member'
  double memberDiscountPercent = 0; // e.g. 10.0 for 10%

  String? get activeOrderId => existingOrderId ?? table?.order?.id;

  Future<void> load() async {
    loading = true;
    loadError = null;
    notifyListeners();

    try {
      final catalog = await ProductCatalogService.instance.fetchCatalog();
      products = catalog.products;
      categories = catalog.categories;
      if (catalog.modifiers.isNotEmpty) {
        modifierGroups = catalog.modifiers;
      }
    } catch (e) {
      loadError = ApiException.from(e).message;
    }

    try {
      billing = await _service.billingSettings();
    } catch (_) {
      billing = const BillingSettings(
        serviceChargeEnabled: false,
        serviceChargeRate: 0,
        pb1Enabled: false,
        pb1Rate: 0,
        pb1Inclusive: false,
        roundingEnabled: true,
        roundingStep: 100,
        roundingScope: 'both',
        roundingDirection: 'floor',
      );
    }

    if (modifierGroups.isEmpty) {
      try {
        modifierGroups = await ModifierService.instance.groups();
      } catch (_) {}
    }

    try {
      await refreshShift();
    } catch (_) {}

    loading = false;
    notifyListeners();
  }

  Future<ShiftStatus?> refreshShift() async {
    try {
      final s = await ShiftService.instance.getShiftStatus();
      shiftId = s.isOpen ? s.shiftId : null;
      notifyListeners();
      return s;
    } catch (_) {
      return null;
    }
  }

  List<PosProduct> get visibleProducts {
    final q = search.trim().toLowerCase();
    return products.where((p) {
      final inCategory = category == 'Semua' || p.category == category;
      final matches = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q);
      return inCategory && matches;
    }).toList();
  }

  num get subtotal => lines.fold<num>(0, (sum, l) => sum + l.subtotal);
  int get itemCount => lines.fold<int>(0, (sum, l) => sum + l.quantity);

  num get memberDiscountAmount => memberDiscountPercent > 0 ? (subtotal * (memberDiscountPercent / 100)) : 0;
  
  num get promoDiscountAmount {
    if (activePromotion != null) {
      return activePromotion!.calculateDiscount(subtotal);
    }
    return voucherDiscountAmount;
  }

  num get totalDiscount => (memberDiscountAmount + promoDiscountAmount).clamp(0, subtotal);

  BillBreakdown? get bill => billing == null
      ? null
      : BillCalculator.calculate(billing!, subtotal: subtotal, discount: totalDiscount);

  void applyPromotion(StorePromotion promo) {
    activePromotion = promo;
    activeVoucherCode = promo.code ?? promo.name;
    voucherDiscountAmount = promo.calculateDiscount(subtotal);
    notifyListeners();
  }

  Future<bool> applyVoucherCode(String code) async {
    final clean = code.trim().toUpperCase();
    if (clean.isEmpty) return false;

    // 1. Cek di local billing settings
    final promo = billing?.findPromotionByCode(clean);
    if (promo != null) {
      if (promo.minOrderAmount > 0 && subtotal < promo.minOrderAmount) {
        throw ApiException.from(
          'Minimal transaksi untuk promo "${promo.name}" adalah Rp ${promo.minOrderAmount.toInt()}',
        );
      }
      applyPromotion(promo);
      return true;
    }

    // 2. Cek langsung via API backend
    final remote = await BillingSettings.verifyVoucherCodeApi(clean, subtotal);
    if (remote != null) {
      if (remote.minOrderAmount > 0 && subtotal < remote.minOrderAmount) {
        throw ApiException.from(
          'Minimal transaksi untuk promo "${remote.name}" adalah Rp ${remote.minOrderAmount.toInt()}',
        );
      }
      if (billing != null) {
        final merged = List<StorePromotion>.from(billing!.promotions)..add(remote);
        billing = billing!.copyWith(promotions: merged);
      }
      applyPromotion(remote);
      return true;
    }

    return false;
  }

  Future<void> refreshDiscounts() async {
    try {
      final extraPromos = await BillingSettings.fetchDiscountsFromApi();
      if (extraPromos.isNotEmpty && billing != null) {
        final merged = List<StorePromotion>.from(billing!.promotions);
        final existingIds = merged.map((p) => p.id).toSet();
        final existingCodes = merged.where((p) => p.code != null).map((p) => p.code!.toUpperCase()).toSet();
        for (final ep in extraPromos) {
          final codeUpper = ep.code?.toUpperCase();
          final isDup = existingIds.contains(ep.id) || (codeUpper != null && existingCodes.contains(codeUpper));
          if (!isDup) {
            merged.add(ep);
            existingIds.add(ep.id);
            if (codeUpper != null) existingCodes.add(codeUpper);
          }
        }
        billing = billing!.copyWith(promotions: merged);
        notifyListeners();
      }
    } catch (_) {}
  }

  void applyVoucher(String code, double amount, {StorePromotion? promo}) {
    activePromotion = promo;
    activeVoucherCode = code;
    voucherDiscountAmount = amount;
    notifyListeners();
  }

  void removeVoucher() {
    activePromotion = null;
    activeVoucherCode = null;
    voucherDiscountAmount = 0;
    notifyListeners();
  }

  void setMember(String name, {String? tier, double discountPercent = 0}) {
    customerName = name.trim();
    memberTier = tier;
    memberDiscountPercent = discountPercent;
    notifyListeners();
  }

  void setCategory(String c) {
    category = c;
    notifyListeners();
  }

  void setSearch(String q) {
    search = q;
    notifyListeners();
  }

  List<ModifierGroup> groupsFor(PosProduct p) {
    if (p.modifierGroups.isNotEmpty) {
      return p.modifierGroups;
    }
    final matched = modifierGroups
        .where((g) => g.appliesTo(p.category, p.categoryId))
        .toList();
    if (matched.isNotEmpty) return matched;

    // Fallback: Jika ada grup modifier yang berlaku secara global (tanpa batasan kategori)
    return modifierGroups.where((g) => g.categories.isEmpty && g.categoryIds.isEmpty).toList();
  }

  void add(
    PosProduct p, {
    List<ModifierOption> options = const [],
    int quantity = 1,
    String? note,
  }) {
    final candidate = RegisterLine(
      productId: p.id,
      name: p.name,
      price: p.price,
      quantity: quantity,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      options: options,
    );
    final existing = lines.where((l) => l.mergeKey == candidate.mergeKey);
    if (existing.isNotEmpty) {
      existing.first.quantity += quantity;
    } else {
      lines.add(candidate);
    }
    notifyListeners();
  }

  void increment(RegisterLine l) {
    l.quantity++;
    notifyListeners();
  }

  void decrement(RegisterLine l) {
    if (l.quantity <= 1) {
      lines.remove(l);
    } else {
      l.quantity--;
    }
    notifyListeners();
  }

  void remove(RegisterLine l) {
    lines.remove(l);
    notifyListeners();
  }

  void setNote(RegisterLine l, String note) {
    l.note = note.trim().isEmpty ? null : note.trim();
    notifyListeners();
  }

  void setOrderType(OrderType t) {
    orderType = t;
    if (t != OrderType.dineIn) table = null;
    notifyListeners();
  }

  void setTable(CafeTableInfo? t) {
    table = t;
    if (t != null) orderType = OrderType.dineIn;
    notifyListeners();
  }

  Future<void> loadTableActiveOrder(CafeTableInfo t) async {
    table = t;
    orderType = OrderType.dineIn;
    if (t.order != null) {
      busy = true;
      notifyListeners();
      try {
        final activeOrder = await TableService.instance.getActiveOrder(t.id);
        if (activeOrder != null && activeOrder.items.isNotEmpty) {
          existingOrderId = activeOrder.id;
          if (activeOrder.customerName.isNotEmpty) {
            customerName = activeOrder.customerName;
          }
          lines.clear();
          for (final item in activeOrder.items) {
            final allModSources = <String>{
              ...item.modifiers.map((e) => e.toString().trim()),
              ...item.modifierNames.map((e) => e.trim()),
            };

            final matchedOpts = <ModifierOption>[];
            for (final modStr in allModSources) {
              if (modStr.isEmpty) continue;
              final modLower = modStr.toLowerCase();

              ModifierOption? matched;
              for (final g in modifierGroups) {
                for (final opt in g.options) {
                  if (opt.id.toString() == modStr ||
                      opt.name.trim().toLowerCase() == modLower) {
                    matched = opt;
                    break;
                  }
                }
                if (matched != null) break;
              }

              matched ??= ModifierOption(
                id: modStr,
                name: modStr,
                price: 0,
              );

              if (!matchedOpts.any((existing) => existing.name.toLowerCase() == matched!.name.toLowerCase())) {
                matchedOpts.add(matched);
              }
            }

            lines.add(RegisterLine(
              productId: item.productId,
              name: item.name,
              price: item.price,
              quantity: item.quantity,
              note: item.notes,
              options: matchedOpts,
            ));
          }
        }
      } catch (_) {}
      busy = false;
      notifyListeners();
    }
  }

  Future<void> loadKitchenOrder(KitchenOrder order) async {
    busy = true;
    notifyListeners();
    try {
      existingOrderId = order.id;
      customerName = order.customerName ?? '';

      final label = order.tableLabel.toLowerCase();
      final isWalkIn = label.isEmpty ||
          label.contains('walk-in') ||
          label.contains('tamu') ||
          label.contains('takeaway');

      if (!isWalkIn) {
        orderType = OrderType.dineIn;
        try {
          final tables = await TableService.instance.tables();
          table = tables
              .where((t) =>
                  t.name.toLowerCase() == order.tableLabel.toLowerCase() ||
                  t.id == order.tableLabel ||
                  'meja ${t.name.toLowerCase()}' == label)
              .firstOrNull;
        } catch (_) {}
      } else {
        orderType = OrderType.takeaway;
        table = null;
      }

      lines.clear();
      for (final item in order.items) {
        final catalogProd = products
            .where((p) =>
                (item.productId != null && p.id == item.productId) ||
                p.name.toLowerCase() == item.name.toLowerCase())
            .firstOrNull;

        final prodId = (item.productId != null && item.productId!.isNotEmpty)
            ? item.productId!
            : (catalogProd?.id ?? item.id);

        final matchedOpts = <ModifierOption>[];
        for (final modStr in item.modifiers) {
          final modClean = modStr.trim();
          if (modClean.isEmpty) continue;
          final modLower = modClean.toLowerCase();

          ModifierOption? matched;
          for (final g in modifierGroups) {
            for (final opt in g.options) {
              if (opt.id.toString() == modClean ||
                  opt.name.trim().toLowerCase() == modLower) {
                matched = opt;
                break;
              }
            }
            if (matched != null) break;
          }

          matched ??= ModifierOption(
            id: modClean,
            name: modClean,
            price: 0,
          );

          if (!matchedOpts.any((existing) => existing.name.toLowerCase() == matched!.name.toLowerCase())) {
            matchedOpts.add(matched);
          }
        }

        final modTotal = matchedOpts.fold<num>(0, (s, o) => s + o.price);
        num basePrice = catalogProd?.price ?? ((item.price != null && item.price! > 0) ? item.price! : 0);
        if (catalogProd == null && basePrice > modTotal && modTotal > 0) {
          basePrice = basePrice - modTotal;
        }

        lines.add(RegisterLine(
          productId: prodId,
          name: item.name,
          price: basePrice,
          quantity: item.quantity,
          note: item.note,
          options: matchedOpts,
        ));
      }
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void setCustomer(String name) {
    customerName = name.trim();
    notifyListeners();
  }

  void reset() {
    lines.clear();
    table = null;
    existingOrderId = null;
    customerName = '';
    activePromotion = null;
    activeVoucherCode = null;
    voucherDiscountAmount = 0;
    memberTier = null;
    memberDiscountPercent = 0;
    orderType = OrderType.takeaway;
    notifyListeners();
  }

  Future<String> sendToKitchen() async {
    if (busy) throw ApiException.from('Sedang memproses, mohon tunggu...');
    if (lines.isEmpty) throw ApiException.from('Keranjang masih kosong');
    busy = true;
    notifyListeners();
    try {
      final id = await _service.sendToKitchen(
        lines: lines,
        tableId: table?.id,
        customerName: customerName,
        orderId: existingOrderId,
        isHold: false,
        orderType: orderType.name,
      );
      return id;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<String> holdOrder({String? name}) async {
    if (busy) throw ApiException.from('Sedang memproses, mohon tunggu...');
    if (lines.isEmpty) throw ApiException.from('Keranjang masih kosong');
    final effectiveCustomer = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : (customerName.trim().isNotEmpty
            ? customerName.trim()
            : (table != null
                ? 'Meja ${table!.name}'
                : 'Walk-In #${DateTime.now().minute}${DateTime.now().second.toString().padLeft(2, '0')}'));

    busy = true;
    notifyListeners();
    try {
      final id = await _service.sendToKitchen(
        lines: lines,
        tableId: table?.id,
        customerName: effectiveCustomer,
        orderId: existingOrderId,
        isHold: true,
        orderType: orderType.name,
      );

      final orderIdToRegister = id.isNotEmpty
          ? id
          : (existingOrderId ?? 'HOLD-${DateTime.now().millisecondsSinceEpoch}');

      KitchenService.instance.registerLocalHeldOrder(
        KitchenOrder(
          id: orderIdToRegister,
          number: '#$orderIdToRegister',
          tableLabel: table != null ? table!.name : effectiveCustomer,
          stage: KitchenStage.fresh,
          createdAt: DateTime.now(),
          status: 'held',
          customerName: effectiveCustomer,
          totalAmount: bill?.total ?? subtotal,
          items: lines
              .map((l) => KitchenItem(
                    id: l.productId,
                    name: l.name,
                    station: 'POS',
                    quantity: l.quantity,
                    done: false,
                    modifiers: l.options.map((o) => o.name).toList(),
                    note: l.note,
                    productId: l.productId,
                    price: l.unitPrice,
                  ))
              .toList(),
        ),
      );

      return id;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<CheckoutOutcome> pay(String method, num paid) async {
    if (busy) throw ApiException.from('Transaksi sedang diproses, mohon tunggu...');
    final b = bill;
    if (b == null) throw ApiException.from('Pengaturan pajak belum termuat');
    busy = true;
    notifyListeners();
    try {
      final res = await _service.checkout(
        lines: lines,
        bill: b,
        method: method,
        paid: paid,
        orderId: existingOrderId,
        tableId: table?.id,
        customerName: customerName,
        shiftId: shiftId,
        voucherCode: activeVoucherCode,
      );
      if (existingOrderId != null) {
        KitchenService.instance.removeHeldOrder(existingOrderId!);
      }
      existingOrderId = null;
      return res;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
