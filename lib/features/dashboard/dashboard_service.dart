import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/safe_json.dart';
import '../shared_pos/sale_record.dart';

class BranchSales {
  const BranchSales({required this.name, required this.total});

  final String name;
  final double total;
}

/// Ringkasan angka utama untuk satu rentang tanggal.
/// Field yang tidak disediakan backend untuk flavor tertentu bernilai `null`
/// dan UI tidak boleh menampilkannya.
class DashboardSummary {
  const DashboardSummary({
    required this.revenue,
    required this.transactions,
    required this.rangeStart,
    this.rangeEnd,
    this.growthPercent,
    this.averageDaily,
    this.netProfit,
    this.expenses,
    this.dailyTrend = const [],
    this.branches = const [],
    this.statusBreakdown = const {},
    this.cashTotal = 0,
    this.qrisTotal = 0,
    this.debitTotal = 0,
    this.transferTotal = 0,
    this.otherTotal = 0,
  });

  final double revenue;
  final int transactions;
  final DateTime rangeStart;
  final DateTime? rangeEnd;
  final double? growthPercent;
  final double? averageDaily;
  final double? netProfit;
  final double? expenses;

  /// Total penjualan per hari, mulai dari [rangeStart].
  final List<double> dailyTrend;
  final List<BranchSales> branches;

  /// Jumlah pesanan per status (khusus F&B).
  final Map<String, int> statusBreakdown;

  /// Breakdown metode pembayaran
  final double cashTotal;
  final double qrisTotal;
  final double debitTotal;
  final double transferTotal;
  final double otherTotal;

  double get calculatedAov => transactions > 0 ? (revenue / transactions) : 0.0;
  double get paymentTotal => cashTotal + qrisTotal + debitTotal + transferTotal + otherTotal;
}

class DashboardService {
  static final DashboardService instance = DashboardService._();
  DashboardService._();

  static final _dateFmt = DateFormat('yyyy-MM-dd');

  Future<DashboardSummary> load({required DateTime start, required DateTime end}) async {
    try {
      return switch (AppConfig.instance.flavor) {
        AppFlavor.pharmacy => await _pharmacy(start, end),
        _ => await _cafe(start, end),
      };
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Map<String, dynamic> _query(DateTime start, DateTime end) {
    final locationId = SessionStorage.instance.getLocationId();
    return {
      'start_date': _dateFmt.format(start),
      'end_date': _dateFmt.format(end),
      if (locationId != null && locationId.isNotEmpty)
        'location_id': int.tryParse(locationId) ?? locationId,
    };
  }

  Map<String, dynamic> _unwrap(dynamic raw) {
    if (raw is Map) {
      final data = raw['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
      return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{};
  }

  Future<DashboardSummary> _pharmacy(DateTime start, DateTime end) async {
    Response res;
    final q = _query(start, end);
    try {
      res = await ApiClient.instance.dio.get(
        '/v1/pharmacy/dashboard/analytics',
        queryParameters: q,
      );
    } catch (_) {
      res = await ApiClient.instance.dio.get(
        '/pharmacy/dashboard/analytics',
        queryParameters: q,
      );
    }
    final data = _unwrap(res.data);

    final overview = data.getMap('sales_overview');
    final daily = data.getMap('average_daily_sales');
    final earnings = data.getMap('total_earnings');

    final rawTrend = daily['trend'];
    final trend = rawTrend is List
        ? rawTrend.map((e) => e is num ? e.toDouble() : 0.0).toList()
        : <double>[];

    final branches = data.getList<BranchSales>('sales_by_branches', (item) {
      final m = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
      return BranchSales(
        name: m.getString('branch_name', fallback: '-'),
        total: m.getDouble('total_sales'),
      );
    });

    final cash = data.getDouble('cash_total',
        fallback: overview.getDouble('cash_sales', fallback: 0.0));
    final qris = data.getDouble('qris_total',
        fallback: overview.getDouble('qris_sales', fallback: 0.0));
    final debit = data.getDouble('debit_total',
        fallback: overview.getDouble('debit_sales', fallback: 0.0));
    final transfer = data.getDouble('transfer_total',
        fallback: overview.getDouble('transfer_sales', fallback: 0.0));

    return DashboardSummary(
      revenue: overview.getDouble('total_sales'),
      transactions: overview.getInt('total_orders'),
      rangeStart: start,
      rangeEnd: end,
      growthPercent: overview.getDouble('growth_percentage'),
      averageDaily: daily.getDouble('average_value'),
      netProfit: earnings.getDouble('net_profit'),
      expenses: earnings.getDouble('operational_expenses'),
      dailyTrend: trend,
      branches: branches,
      cashTotal: cash,
      qrisTotal: qris,
      debitTotal: debit,
      transferTotal: transfer,
    );
  }

  Future<DashboardSummary> _cafe(DateTime start, DateTime end) async {
    final query = _query(start, end);
    dynamic raw;
    try {
      final res = await ApiClient.instance.dio.get('/v1/pos/dashboard/overview', queryParameters: query);
      raw = res.data;
    } catch (_) {
      try {
        final res = await ApiClient.instance.dio.get('/cafe/dashboard/overview', queryParameters: query);
        raw = res.data;
      } catch (_) {
        try {
          final res = await ApiClient.instance.dio.get('/pos/dashboard/overview', queryParameters: query);
          raw = res.data;
        } catch (_) {}
      }
    }
    final data = _unwrap(raw);
    final status = data.getMap('status_breakdown');

    double rev = data.getDouble('today_revenue',
        fallback: data.getDouble('total_sales',
            fallback: data.getDouble('revenue',
                fallback: data.getDouble('total_revenue', fallback: 0.0))));

    int tx = data.getInt('today_transactions',
        fallback: data.getInt('transaction_count',
            fallback: data.getInt('total_orders',
                fallback: data.getInt('total_transactions', fallback: 0))));

    double cash = data.getDouble('cash_total',
        fallback: data.getDouble('cash_sales',
            fallback: data.getDouble('total_cash', fallback: 0.0)));

    double qris = data.getDouble('qris_total',
        fallback: data.getDouble('qris_sales',
            fallback: data.getDouble('total_qris', fallback: 0.0)));

    double debit = data.getDouble('debit_total',
        fallback: data.getDouble('debit_sales',
            fallback: data.getDouble('total_debit', fallback: 0.0)));

    double transfer = data.getDouble('transfer_total',
        fallback: data.getDouble('transfer_sales',
            fallback: data.getDouble('total_transfer', fallback: 0.0)));

    double other = data.getDouble('other_total',
        fallback: data.getDouble('other_sales', fallback: 0.0));

    // Augment with local sales from ShiftSalesStorage if active
    final isToday = start.year == end.year && start.month == end.month && start.day == end.day;
    if (isToday) {
      final localSales = ShiftSalesStorage.activeShiftSales.where((s) => !s.isVoided).toList();
      if (localSales.isNotEmpty) {
        final double lCash = localSales.where((s) => s.paymentMethod.toLowerCase() == 'cash').fold(0.0, (sum, s) => sum + s.total);
        final double lQris = localSales.where((s) => s.paymentMethod.toLowerCase() == 'qris').fold(0.0, (sum, s) => sum + s.total);
        final double lTf = localSales.where((s) => s.paymentMethod.toLowerCase().contains('transfer')).fold(0.0, (sum, s) => sum + s.total);
        final double lDebit = localSales.where((s) => s.paymentMethod.toLowerCase().contains('card') || s.paymentMethod.toLowerCase().contains('edc') || s.paymentMethod.toLowerCase().contains('debit')).fold(0.0, (sum, s) => sum + s.total);
        final double lOther = localSales.where((s) => !['cash', 'qris'].contains(s.paymentMethod.toLowerCase()) && !s.paymentMethod.toLowerCase().contains('transfer') && !s.paymentMethod.toLowerCase().contains('card') && !s.paymentMethod.toLowerCase().contains('edc') && !s.paymentMethod.toLowerCase().contains('debit')).fold(0.0, (sum, s) => sum + s.total);

        if (cash == 0 && lCash > 0) cash = lCash;
        if (qris == 0 && lQris > 0) qris = lQris;
        if (transfer == 0 && lTf > 0) transfer = lTf;
        if (debit == 0 && lDebit > 0) debit = lDebit;
        if (other == 0 && lOther > 0) other = lOther;

        final double localTotal = localSales.fold(0.0, (sum, s) => sum + s.total);
        if (rev == 0 && localTotal > 0) rev = localTotal;
        if (tx == 0 && localSales.isNotEmpty) tx = localSales.length;
      }
    }

    final rawTrend = data['trend'] ?? data['daily_trend'] ?? data['sales_trend'];
    final trend = rawTrend is List
        ? rawTrend.map((e) => e is num ? e.toDouble() : 0.0).toList()
        : <double>[];

    final branches = data.getList<BranchSales>('sales_by_branches', (item) {
      final m = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
      return BranchSales(
        name: m.getString('branch_name', fallback: '-'),
        total: m.getDouble('total_sales'),
      );
    });

    final growth = data.getDouble('growth_percentage', fallback: data.getDouble('growth'));
    final avgDaily = data.getDouble('average_order_value', fallback: data.getDouble('average_daily'));
    final profit = data.getDouble('net_profit', fallback: data.getDouble('profit'));
    final exp = data.getDouble('operational_expenses', fallback: data.getDouble('expenses'));

    return DashboardSummary(
      revenue: rev,
      transactions: tx,
      rangeStart: start,
      rangeEnd: end,
      growthPercent: growth,
      averageDaily: avgDaily,
      netProfit: profit,
      expenses: exp,
      dailyTrend: trend,
      branches: branches,
      cashTotal: cash,
      qrisTotal: qris,
      debitTotal: debit,
      transferTotal: transfer,
      otherTotal: other,
      statusBreakdown: {
        for (final e in status.entries)
          e.key: e.value is num ? (e.value as num).toInt() : 0,
      },
    );
  }
}
