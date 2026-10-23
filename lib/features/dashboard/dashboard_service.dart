import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/safe_json.dart';

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
    this.growthPercent,
    this.averageDaily,
    this.netProfit,
    this.expenses,
    this.dailyTrend = const [],
    this.branches = const [],
    this.statusBreakdown = const {},
  });

  final double revenue;
  final int transactions;
  final DateTime rangeStart;
  final double? growthPercent;
  final double? averageDaily;
  final double? netProfit;
  final double? expenses;

  /// Total penjualan per hari, mulai dari [rangeStart].
  final List<double> dailyTrend;
  final List<BranchSales> branches;

  /// Jumlah pesanan per status (khusus F&B).
  final Map<String, int> statusBreakdown;
}

class DashboardService {
  static final DashboardService instance = DashboardService._();
  DashboardService._();

  static final _dateFmt = DateFormat('yyyy-MM-dd');

  Future<DashboardSummary> load({required DateTime start, required DateTime end}) async {
    try {
      return switch (AppConfig.instance.flavor) {
        AppFlavor.pharmacy => await _pharmacy(start, end),
        AppFlavor.fnb => await _cafe(start, end),
        _ => throw const ApiException('Dashboard belum tersedia untuk aplikasi ini.'),
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
      if (locationId != null && locationId.isNotEmpty) 'location_id': locationId,
    };
  }

  Map<String, dynamic> _unwrap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) return data;
      return raw;
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

    final trend = daily['trend'] is List
        ? (daily['trend'] as List).map((e) => e is num ? e.toDouble() : 0.0).toList()
        : <double>[];

    final branches = data.getList<BranchSales>('sales_by_branches', (item) {
      final m = item as Map<String, dynamic>;
      return BranchSales(
        name: m.getString('branch_name', fallback: '-'),
        total: m.getDouble('total_sales'),
      );
    });

    return DashboardSummary(
      revenue: overview.getDouble('total_sales'),
      transactions: overview.getInt('total_orders'),
      rangeStart: start,
      growthPercent: overview.getDouble('growth_percentage'),
      averageDaily: daily.getDouble('average_value'),
      netProfit: earnings.getDouble('net_profit'),
      expenses: earnings.getDouble('operational_expenses'),
      dailyTrend: trend,
      branches: branches,
    );
  }

  Future<DashboardSummary> _cafe(DateTime start, DateTime end) async {
    final query = _query(end, end);
    dynamic raw;
    try {
      final res = await ApiClient.instance.dio.get('/v1/pos/dashboard/overview', queryParameters: query);
      raw = res.data;
    } catch (_) {
      final res = await ApiClient.instance.dio.get('/cafe/dashboard/overview', queryParameters: query);
      raw = res.data;
    }
    final data = _unwrap(raw);
    final status = data.getMap('status_breakdown');

    return DashboardSummary(
      revenue: data.getDouble('today_revenue'),
      transactions: data.getInt('today_transactions'),
      rangeStart: end,
      statusBreakdown: {
        for (final e in status.entries)
          e.key: e.value is num ? (e.value as num).toInt() : 0,
      },
    );
  }
}
