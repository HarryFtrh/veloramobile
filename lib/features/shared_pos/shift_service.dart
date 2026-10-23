import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/safe_json.dart';
import 'sales_history_drawer.dart';

class ShiftStatus {
  final bool isOpen;
  final String? shiftId;
  final String? cashierName;
  final num? startingCash;
  final DateTime? openedAt;
  final double cashSales;
  final double qrisSales;
  final double transferSales;
  final double cardSales;
  final double otherSales;
  final double totalSales;
  final int totalTransactions;
  final double cashIn;
  final double cashOut;
  final double expectedCash;

  ShiftStatus({
    required this.isOpen,
    this.shiftId,
    this.cashierName,
    this.startingCash,
    this.openedAt,
    this.cashSales = 0,
    this.qrisSales = 0,
    this.transferSales = 0,
    this.cardSales = 0,
    this.otherSales = 0,
    this.totalSales = 0,
    this.totalTransactions = 0,
    this.cashIn = 0,
    this.cashOut = 0,
    this.expectedCash = 0,
  });

  factory ShiftStatus.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ShiftStatus(isOpen: false);

    Map<String, dynamic> active = json.getMap('shift');
    if (active.isEmpty) {
      active = json.getMap('active_shift');
    }

    // Determine if the shift is genuinely open
    final bool rawIsOpen = json.containsKey('is_open') ? json.getBool('is_open') : true;
    final String statusStr = active.getString('status').toLowerCase();
    final bool isClosedStatus = statusStr == 'closed' || statusStr == 'ended' || statusStr == 'completed';
    final bool hasClosedAt = active['closed_at'] != null &&
        active.getString('closed_at').isNotEmpty &&
        active.getString('closed_at') != 'null';

    final bool isOpen = rawIsOpen && active.isNotEmpty && !isClosedStatus && !hasClosedAt;

    if (!isOpen) {
      return ShiftStatus(
        isOpen: false,
        shiftId: null,
        cashierName: active.getString('cashier_name', fallback: 'Kasir'),
      );
    }

    final user = active.getMap('user');
    final cashierName = user.getString(
      'name',
      fallback: active.getString('cashier_name', fallback: 'Kasir'),
    );

    final startingCash = active.getDouble(
      'starting_cash',
      fallback: active.getDouble('opening_cash', fallback: 0),
    );

    final summaryMap = json.getMap('summary').isNotEmpty ? json.getMap('summary') : active;
    final paymentsMap = json.getMap('payments').isNotEmpty
        ? json.getMap('payments')
        : summaryMap.getMap('payment_methods');

    double cashS = paymentsMap.getDouble('cash',
        fallback: summaryMap.getDouble('cash_sales',
            fallback: summaryMap.getDouble('cash_total',
                fallback: active.getDouble('cash_sales'))));

    double qrisS = paymentsMap.getDouble('qris',
        fallback: summaryMap.getDouble('qris_sales',
            fallback: summaryMap.getDouble('qris_total',
                fallback: active.getDouble('qris_sales'))));

    double tfS = paymentsMap.getDouble('transfer',
        fallback: summaryMap.getDouble('transfer_sales',
            fallback: active.getDouble('transfer_sales')));

    double cardS = paymentsMap.getDouble('card',
        fallback: paymentsMap.getDouble('debit',
            fallback: summaryMap.getDouble('card_sales',
                fallback: summaryMap.getDouble('debit_sales',
                    fallback: active.getDouble('card_sales')))));

    double otherS = paymentsMap.getDouble('other',
        fallback: summaryMap.getDouble('other_sales', fallback: active.getDouble('other_sales')));

    final cIn = summaryMap.getDouble('cash_in',
        fallback: summaryMap.getDouble('petty_cash_in',
            fallback: active.getDouble('cash_in')));

    final cOut = summaryMap.getDouble('cash_out',
        fallback: summaryMap.getDouble('petty_cash_out',
            fallback: active.getDouble('cash_out')));

    // Augment with local sales from SalesHistoryDrawer if available
    final localSales = SalesHistoryDrawer.activeShiftSales.where((s) => !s.isVoided).toList();
    if (localSales.isNotEmpty) {
      final double localCash = localSales.where((s) => s.paymentMethod.toLowerCase() == 'cash').fold(0.0, (sum, s) => sum + s.total);
      final double localQris = localSales.where((s) => s.paymentMethod.toLowerCase() == 'qris').fold(0.0, (sum, s) => sum + s.total);
      final double localTf = localSales.where((s) => s.paymentMethod.toLowerCase().contains('transfer')).fold(0.0, (sum, s) => sum + s.total);
      final double localCard = localSales.where((s) => s.paymentMethod.toLowerCase().contains('card') || s.paymentMethod.toLowerCase().contains('edc') || s.paymentMethod.toLowerCase().contains('debit')).fold(0.0, (sum, s) => sum + s.total);
      final double localOther = localSales.where((s) => !['cash', 'qris'].contains(s.paymentMethod.toLowerCase()) && !s.paymentMethod.toLowerCase().contains('transfer') && !s.paymentMethod.toLowerCase().contains('card') && !s.paymentMethod.toLowerCase().contains('edc') && !s.paymentMethod.toLowerCase().contains('debit')).fold(0.0, (sum, s) => sum + s.total);

      if (cashS == 0 && localCash > 0) cashS = localCash;
      if (qrisS == 0 && localQris > 0) qrisS = localQris;
      if (tfS == 0 && localTf > 0) tfS = localTf;
      if (cardS == 0 && localCard > 0) cardS = localCard;
      if (otherS == 0 && localOther > 0) otherS = localOther;
    }

    final sumSales = cashS + qrisS + tfS + cardS + otherS;
    double totSales = summaryMap.getDouble('total_sales',
        fallback: summaryMap.getDouble('net_sales',
            fallback: active.getDouble('total_sales', fallback: sumSales)));
    if (totSales == 0 && sumSales > 0) totSales = sumSales;

    int txCount = summaryMap.getInt('total_transactions',
        fallback: summaryMap.getInt('transaction_count',
            fallback: active.getInt('total_transactions', fallback: localSales.length)));
    if (txCount == 0 && localSales.isNotEmpty) txCount = localSales.length;

    final calcExpected = startingCash + cashS + cIn - cOut;
    final expCash = summaryMap.getDouble('expected_cash',
        fallback: active.getDouble('expected_cash', fallback: calcExpected));

    return ShiftStatus(
      isOpen: true,
      shiftId: active.getString('id'),
      cashierName: cashierName,
      startingCash: startingCash,
      openedAt: active['opened_at'] != null ? DateTime.tryParse(active.getString('opened_at')) : null,
      cashSales: cashS,
      qrisSales: qrisS,
      transferSales: tfS,
      cardSales: cardS,
      otherSales: otherS,
      totalSales: totSales,
      totalTransactions: txCount,
      cashIn: cIn,
      cashOut: cOut,
      expectedCash: expCash,
    );
  }
}

class ShiftCloseSummary {
  final String shiftId;
  final String cashierName;
  final DateTime openedAt;
  final DateTime closedAt;
  final double startingCash;
  final double actualCash;
  final double expectedCash;
  final double difference;
  final double totalSales;
  final int totalTransactions;
  final double cashSales;
  final double qrisSales;
  final double transferSales;
  final double cardSales;
  final double otherSales;
  final double cashIn;
  final double cashOut;
  final String? notes;

  ShiftCloseSummary({
    required this.shiftId,
    required this.cashierName,
    required this.openedAt,
    required this.closedAt,
    required this.startingCash,
    required this.actualCash,
    required this.expectedCash,
    required this.difference,
    required this.totalSales,
    required this.totalTransactions,
    this.cashSales = 0,
    this.qrisSales = 0,
    this.transferSales = 0,
    this.cardSales = 0,
    this.otherSales = 0,
    this.cashIn = 0,
    this.cashOut = 0,
    this.notes,
  });

  factory ShiftCloseSummary.fromResponse({
    required Map<String, dynamic> data,
    required ShiftStatus currentShift,
    required num actualCash,
    String? notes,
  }) {
    final shiftMap = data.getMap('shift').isNotEmpty ? data.getMap('shift') : data;
    final summaryMap = data.getMap('summary').isNotEmpty ? data.getMap('summary') : shiftMap;
    final paymentsMap = data.getMap('payments').isNotEmpty
        ? data.getMap('payments')
        : summaryMap.getMap('payment_methods');

    final start = (shiftMap.getDouble('starting_cash', fallback: shiftMap.getDouble('opening_cash')) > 0)
        ? shiftMap.getDouble('starting_cash', fallback: shiftMap.getDouble('opening_cash'))
        : (currentShift.startingCash?.toDouble() ?? 0.0);

    final actual = actualCash.toDouble();

    double cashS = paymentsMap.getDouble('cash',
        fallback: summaryMap.getDouble('cash_sales',
            fallback: summaryMap.getDouble('cash_total',
                fallback: data.getDouble('cash_sales', fallback: currentShift.cashSales))));

    double qrisS = paymentsMap.getDouble('qris',
        fallback: summaryMap.getDouble('qris_sales',
            fallback: summaryMap.getDouble('qris_total',
                fallback: data.getDouble('qris_sales', fallback: currentShift.qrisSales))));

    double tfS = paymentsMap.getDouble('transfer',
        fallback: summaryMap.getDouble('transfer_sales',
            fallback: data.getDouble('transfer_sales', fallback: currentShift.transferSales)));

    double cardS = paymentsMap.getDouble('card',
        fallback: paymentsMap.getDouble('debit',
            fallback: summaryMap.getDouble('card_sales',
                fallback: summaryMap.getDouble('debit_sales',
                    fallback: data.getDouble('card_sales', fallback: currentShift.cardSales)))));

    double otherS = paymentsMap.getDouble('other',
        fallback: summaryMap.getDouble('other_sales', fallback: data.getDouble('other_sales', fallback: currentShift.otherSales)));

    final cIn = summaryMap.getDouble('cash_in',
        fallback: summaryMap.getDouble('petty_cash_in',
            fallback: data.getDouble('cash_in', fallback: currentShift.cashIn)));

    final cOut = summaryMap.getDouble('cash_out',
        fallback: summaryMap.getDouble('petty_cash_out',
            fallback: data.getDouble('cash_out', fallback: currentShift.cashOut)));

    // Fallback to local recorded transactions if backend returns 0
    final localSales = SalesHistoryDrawer.activeShiftSales.where((s) => !s.isVoided).toList();
    if (localSales.isNotEmpty) {
      final double localCash = localSales.where((s) => s.paymentMethod.toLowerCase() == 'cash').fold(0.0, (sum, s) => sum + s.total);
      final double localQris = localSales.where((s) => s.paymentMethod.toLowerCase() == 'qris').fold(0.0, (sum, s) => sum + s.total);
      final double localTf = localSales.where((s) => s.paymentMethod.toLowerCase().contains('transfer')).fold(0.0, (sum, s) => sum + s.total);
      final double localCard = localSales.where((s) => s.paymentMethod.toLowerCase().contains('card') || s.paymentMethod.toLowerCase().contains('edc') || s.paymentMethod.toLowerCase().contains('debit')).fold(0.0, (sum, s) => sum + s.total);
      final double localOther = localSales.where((s) => !['cash', 'qris'].contains(s.paymentMethod.toLowerCase()) && !s.paymentMethod.toLowerCase().contains('transfer') && !s.paymentMethod.toLowerCase().contains('card') && !s.paymentMethod.toLowerCase().contains('edc') && !s.paymentMethod.toLowerCase().contains('debit')).fold(0.0, (sum, s) => sum + s.total);

      if (cashS == 0 && localCash > 0) cashS = localCash;
      if (qrisS == 0 && localQris > 0) qrisS = localQris;
      if (tfS == 0 && localTf > 0) tfS = localTf;
      if (cardS == 0 && localCard > 0) cardS = localCard;
      if (otherS == 0 && localOther > 0) otherS = localOther;
    }

    final sumSales = cashS + qrisS + tfS + cardS + otherS;
    double totSales = summaryMap.getDouble('total_sales',
        fallback: summaryMap.getDouble('net_sales',
            fallback: data.getDouble('total_sales', fallback: sumSales)));
    if (totSales == 0 && sumSales > 0) totSales = sumSales;

    int txCount = summaryMap.getInt('total_transactions',
        fallback: summaryMap.getInt('transaction_count',
            fallback: data.getInt('total_transactions', fallback: localSales.length)));
    if (txCount == 0 && localSales.isNotEmpty) txCount = localSales.length;

    final calcExpected = start + cashS + cIn - cOut;
    final expCash = summaryMap.getDouble('expected_cash',
        fallback: data.getDouble('expected_cash', fallback: calcExpected));

    final diff = summaryMap.getDouble('difference',
        fallback: summaryMap.getDouble('discrepancy',
            fallback: data.getDouble('difference', fallback: (actual - expCash))));

    DateTime opened = currentShift.openedAt ?? DateTime.now();
    final openedStr = shiftMap.getString('opened_at', fallback: data.getString('opened_at'));
    if (openedStr.isNotEmpty) {
      opened = DateTime.tryParse(openedStr) ?? opened;
    }

    DateTime closed = DateTime.now();
    final closedStr = shiftMap.getString('closed_at', fallback: data.getString('closed_at'));
    if (closedStr.isNotEmpty) {
      closed = DateTime.tryParse(closedStr) ?? closed;
    }

    final cashier = currentShift.cashierName?.isNotEmpty == true
        ? currentShift.cashierName!
        : (shiftMap.getString('cashier_name',
            fallback: SessionStorage.instance.getUserName() ?? 'Kasir'));

    return ShiftCloseSummary(
      shiftId: currentShift.shiftId ?? shiftMap.getString('id', fallback: '1'),
      cashierName: cashier,
      openedAt: opened,
      closedAt: closed,
      startingCash: start,
      actualCash: actual,
      expectedCash: expCash,
      difference: diff,
      totalSales: totSales,
      totalTransactions: txCount,
      cashSales: cashS,
      qrisSales: qrisS,
      transferSales: tfS,
      cardSales: cardS,
      otherSales: otherS,
      cashIn: cIn,
      cashOut: cOut,
      notes: notes ?? shiftMap.getString('notes'),
    );
  }
}

class ShiftService extends ChangeNotifier {
  static final ShiftService instance = ShiftService._();
  ShiftService._();

  ShiftStatus? _currentStatus;
  ShiftStatus? get currentStatus => _currentStatus;

  ShiftCloseSummary? _lastCloseSummary;
  ShiftCloseSummary? get lastCloseSummary => _lastCloseSummary;

  Future<ShiftStatus> getShiftStatus() async {
    final locationId = SessionStorage.instance.getLocationId();
    final response = await ApiClient.instance.dio.get(
      '/v1/pos/shift-status',
      queryParameters: {
        if (locationId != null && locationId.isNotEmpty) 'location_id': locationId,
      },
    );
    final rawData = response.data;
    Map<String, dynamic> data = {};
    if (rawData is Map<String, dynamic>) {
      data = rawData['data'] is Map<String, dynamic> ? rawData['data'] : rawData;
    }
    _currentStatus = ShiftStatus.fromJson(data);
    notifyListeners();
    return _currentStatus!;
  }

  Future<void> openShift({required num startingCash, String? notes}) async {
    final locationId = SessionStorage.instance.getLocationId();
    await ApiClient.instance.dio.post(
      '/v1/pos/shift-open',
      data: {
        'opening_cash': startingCash,
        'starting_cash': startingCash,
        if (locationId != null && locationId.isNotEmpty) 'location_id': locationId,
        'notes': notes ?? 'Shift dibuka via Flutter POS',
      },
    );
    SalesHistoryDrawer.activeShiftSales.clear();
    await getShiftStatus();
  }

  Future<ShiftCloseSummary> closeShift({
    required ShiftStatus currentShift,
    required num actualCash,
    String? notes,
  }) async {
    final locationId = SessionStorage.instance.getLocationId();
    final response = await ApiClient.instance.dio.post(
      '/v1/pos/shift-close',
      data: {
        'shift_id': currentShift.shiftId,
        'closing_cash': actualCash,
        'actual_cash': actualCash,
        if (locationId != null && locationId.isNotEmpty) 'location_id': locationId,
        'notes': notes,
      },
    );
    final rawData = response.data;
    Map<String, dynamic> data = {};
    if (rawData is Map<String, dynamic>) {
      data = rawData['data'] is Map<String, dynamic> ? rawData['data'] as Map<String, dynamic> : rawData;
    }

    final summary = ShiftCloseSummary.fromResponse(
      data: data,
      currentShift: currentShift,
      actualCash: actualCash,
      notes: notes,
    );

    _lastCloseSummary = summary;
    _currentStatus = ShiftStatus(isOpen: false);
    SalesHistoryDrawer.activeShiftSales.clear();
    notifyListeners();

    return summary;
  }

  Future<void> recordPettyCash({
    required String type, // 'in' or 'out'
    required num amount,
    required String reason,
  }) async {
    final locationId = SessionStorage.instance.getLocationId();
    await ApiClient.instance.dio.post(
      '/v1/pos/petty-cash',
      data: {
        'type': type,
        'amount': amount,
        'reason': reason,
        if (locationId != null && locationId.isNotEmpty) 'location_id': locationId,
      },
    );
    await getShiftStatus();
  }
}
