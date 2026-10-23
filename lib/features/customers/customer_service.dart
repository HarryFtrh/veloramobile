import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/state/paged_result.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/safe_json.dart';

export '../../core/state/paged_result.dart';

class LoyaltyMember {
  const LoyaltyMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.points,
    required this.totalSpend,
  });

  final String id;
  final String name;
  final String phone;
  final int points;
  final double totalSpend;

  factory LoyaltyMember.fromJson(Map<String, dynamic> json) => LoyaltyMember(
        id: json.getString('id'),
        name: json.getString('name', fallback: '-'),
        phone: json.getString('phone'),
        points: json.getInt('total_points'),
        totalSpend: json.getDouble('total_spend'),
      );
}

class MemberStats {
  const MemberStats({
    required this.totalMembers,
    required this.newThisMonth,
    required this.avgSpend,
    required this.activeLoyalty,
  });

  final int totalMembers;
  final int newThisMonth;
  final double avgSpend;
  final int activeLoyalty;

  factory MemberStats.fromJson(Map<String, dynamic> json) => MemberStats(
        totalMembers: json.getInt('total_members'),
        newThisMonth: json.getInt('new_this_month'),
        avgSpend: json.getDouble('avg_spend'),
        activeLoyalty: json.getInt('active_loyalty'),
      );
}

enum DebtStatus { unpaid, paid }

class Debt {
  const Debt({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.amount,
    required this.balance,
    required this.status,
    this.dueDate,
    this.createdAt,
  });

  final String id;
  final String customerName;
  final String phone;
  final double amount;
  final double balance;
  final DebtStatus status;
  final DateTime? dueDate;
  final DateTime? createdAt;

  bool get isOverdue =>
      status == DebtStatus.unpaid &&
      dueDate != null &&
      dueDate!.isBefore(DateTime.now());

  factory Debt.fromJson(Map<String, dynamic> json) => Debt(
        id: json.getString('id'),
        customerName: json.getString('customer_name', fallback: '-'),
        phone: json.getString('customer_phone'),
        amount: json.getDouble('amount'),
        balance: json.getDouble('balance'),
        status: json.getString('status') == 'paid' ? DebtStatus.paid : DebtStatus.unpaid,
        dueDate: DateTime.tryParse(json.getString('due_date')),
        createdAt: DateTime.tryParse(json.getString('created_at')),
      );
}

/// Metode bayar yang diterima backend pada pelunasan hutang
/// (`SettleCafeDebtRequest`: in:cash,qris,transfer,debit,credit_card,edc,e_wallet).
enum SettleMethod {
  cash('cash', 'Tunai'),
  qris('qris', 'QRIS'),
  transfer('transfer', 'Transfer'),
  debit('debit', 'Kartu debit');

  const SettleMethod(this.value, this.label);

  final String value;
  final String label;
}

/// Data pelanggan (member loyalty) dan hutang pelanggan untuk F&B.
class CustomerService {
  static final CustomerService instance = CustomerService._();
  CustomerService._();

  Map<String, dynamic> _locationQuery() {
    final id = SessionStorage.instance.getLocationId();
    return {if (id != null && id.isNotEmpty) 'location_id': id};
  }

  Map<String, dynamic> _data(dynamic raw) {
    if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
      return raw['data'] as Map<String, dynamic>;
    }
    return raw is Map<String, dynamic> ? raw : <String, dynamic>{};
  }

  PagedResult<T> _paged<T>(Map<String, dynamic> paginator, T Function(Map<String, dynamic>) map) {
    final rows = paginator.getList<T>('data', (e) => map(e as Map<String, dynamic>));
    return PagedResult(
      items: rows,
      page: paginator.getInt('current_page', fallback: 1),
      lastPage: paginator.getInt('last_page', fallback: 1),
    );
  }

  Future<PagedResult<LoyaltyMember>> members({String? search, int page = 1}) async {
    try {
      final query = {
        ..._locationQuery(),
        'page': page,
        'per_page': 20,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      };

      dynamic resData;
      try {
        final res = await ApiClient.instance.dio.get('/v1/pos/customers', queryParameters: query);
        resData = res.data;
      } catch (_) {
        final res = await ApiClient.instance.dio.get('/cafe/dashboard/customers', queryParameters: query);
        resData = res.data;
      }

      final data = _data(resData);
      final paged = data['members'] is Map<String, dynamic>
          ? _paged(data.getMap('members'), LoyaltyMember.fromJson)
          : _paged(data, LoyaltyMember.fromJson);

      return PagedResult(
        items: paged.items,
        page: paged.page,
        lastPage: paged.lastPage,
        extra: data['stats'] is Map ? MemberStats.fromJson(data.getMap('stats')) : null,
      );
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> createCustomer({required String name, required String phone, String? email}) async {
    try {
      await ApiClient.instance.dio.post(
        '/v1/pos/customers',
        data: {
          'name': name,
          'phone': phone,
          if (email != null && email.isNotEmpty) 'email': email,
          ..._locationQuery(),
        },
      );
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<PagedResult<Debt>> debts({DebtStatus? status, String? search, int page = 1}) async {
    try {
      final query = {
        ..._locationQuery(),
        'page': page,
        'status': ?status?.name,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      };
      dynamic rawData;
      try {
        final res = await ApiClient.instance.dio.get('/v1/pos/debts', queryParameters: query);
        rawData = res.data;
      } catch (_) {
        final res = await ApiClient.instance.dio.get('/cafe/pos/debts', queryParameters: query);
        rawData = res.data;
      }
      return _paged(_data(rawData), Debt.fromJson);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> settle(String debtId, SettleMethod method, {String? notes}) async {
    try {
      final payload = {
        'payment_method': method.value,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      };
      try {
        await ApiClient.instance.dio.post('/v1/pos/debts/$debtId/settle', data: payload);
      } catch (_) {
        await ApiClient.instance.dio.post('/cafe/pos/debts/$debtId/settle', data: payload);
      }
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> writeOff(String debtId) async {
    try {
      try {
        await ApiClient.instance.dio.post('/v1/pos/debts/$debtId/write-off');
      } catch (_) {
        await ApiClient.instance.dio.post('/cafe/pos/debts/$debtId/write-off');
      }
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}
