import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/state/paged_result.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/safe_json.dart';

export '../../core/state/paged_result.dart';

/// Kategori yang diterima backend (`StoreExpenseRequest`:
/// in:gaji,utilitas,sewa,promosi,lainnya).
enum ExpenseCategory {
  gaji('gaji', 'Gaji'),
  utilitas('utilitas', 'Utilitas'),
  sewa('sewa', 'Sewa'),
  promosi('promosi', 'Promosi'),
  lainnya('lainnya', 'Lainnya');

  const ExpenseCategory(this.value, this.label);

  final String value;
  final String label;

  static ExpenseCategory parse(String raw) => ExpenseCategory.values.firstWhere(
        (c) => c.value == raw,
        orElse: () => ExpenseCategory.lainnya,
      );
}

class Expense {
  const Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.month,
    required this.year,
    this.description,
    this.createdBy,
  });

  final String id;
  final ExpenseCategory category;
  final double amount;
  final int month;
  final int year;
  final String? description;
  final String? createdBy;

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json.getString('id'),
        category: ExpenseCategory.parse(json.getString('category')),
        amount: json.getDouble('amount'),
        month: json.getInt('period_month'),
        year: json.getInt('period_year'),
        description: json.getString('description').isEmpty
            ? null
            : json.getString('description'),
        createdBy: json.getMap('created_by').getString('name').isEmpty
            ? null
            : json.getMap('created_by').getString('name'),
      );
}

class ReturnItem {
  const ReturnItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.unitName,
  });

  final int id;
  final String productName;
  final double quantity;
  final double unitPrice;
  final String unitName;

  factory ReturnItem.fromJson(Map<String, dynamic> json) {
    final product = json.getMap('product');
    final name = product.getString(
      'name',
      fallback: product.getMap('global_product').getString('name', fallback: '-'),
    );
    return ReturnItem(
      id: json.getInt('id'),
      productName: name,
      quantity: json.getDouble('quantity'),
      unitPrice: json.getDouble('unit_price'),
      unitName: json.getString('unit_name'),
    );
  }
}

class ReturnableOrder {
  const ReturnableOrder({
    required this.invoiceNo,
    required this.grandTotal,
    required this.items,
    required this.status,
  });

  final String invoiceNo;
  final double grandTotal;
  final List<ReturnItem> items;
  final String status;

  factory ReturnableOrder.fromJson(Map<String, dynamic> json) => ReturnableOrder(
        invoiceNo: json.getString('invoice_no'),
        grandTotal: json.getDouble('grand_total'),
        status: json.getString('status'),
        items: json.getList<ReturnItem>(
          'items',
          (e) => ReturnItem.fromJson(e as Map<String, dynamic>),
        ),
      );
}

/// Pengeluaran operasional dan retur penjualan (Apotek).
class FinanceService {
  static final FinanceService instance = FinanceService._();
  FinanceService._();

  Map<String, dynamic> _location() {
    final id = SessionStorage.instance.getLocationId();
    return {if (id != null && id.isNotEmpty) 'location_id': id};
  }

  Map<String, dynamic> _data(dynamic raw) {
    if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
      return raw['data'] as Map<String, dynamic>;
    }
    return raw is Map<String, dynamic> ? raw : <String, dynamic>{};
  }

  Future<PagedResult<Expense>> expenses({
    required int month,
    required int year,
    int page = 1,
  }) async {
    try {
      final q = {
        ..._location(),
        'month': month,
        'year': year,
        'page': page,
        'per_page': 20,
      };
      dynamic res;
      try {
        res = await ApiClient.instance.dio.get('/v1/pharmacy/finance/expenses', queryParameters: q);
      } catch (_) {
        res = await ApiClient.instance.dio.get('/pharmacy/finance/expenses', queryParameters: q);
      }
      final paginator = _data(res.data);
      return PagedResult(
        items: paginator.getList<Expense>(
          'data',
          (e) => Expense.fromJson(e as Map<String, dynamic>),
        ),
        page: paginator.getInt('current_page', fallback: 1),
        lastPage: paginator.getInt('last_page', fallback: 1),
      );
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Map<String, dynamic> _expensePayload({
    required ExpenseCategory category,
    required double amount,
    required int month,
    required int year,
    String? description,
  }) =>
      {
        ..._location(),
        'category': category.value,
        'amount': amount,
        'period_month': month,
        'period_year': year,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
      };

  Future<void> createExpense({
    required ExpenseCategory category,
    required double amount,
    required int month,
    required int year,
    String? description,
  }) async {
    try {
      final payload = _expensePayload(
        category: category,
        amount: amount,
        month: month,
        year: year,
        description: description,
      );
      try {
        await ApiClient.instance.dio.post('/v1/pharmacy/finance/expenses', data: payload);
      } catch (_) {
        await ApiClient.instance.dio.post('/pharmacy/finance/expenses', data: payload);
      }
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> updateExpense(
    String id, {
    required ExpenseCategory category,
    required double amount,
    required int month,
    required int year,
    String? description,
  }) async {
    try {
      final payload = _expensePayload(
        category: category,
        amount: amount,
        month: month,
        year: year,
        description: description,
      );
      try {
        await ApiClient.instance.dio.put('/v1/pharmacy/finance/expenses/$id', data: payload);
      } catch (_) {
        await ApiClient.instance.dio.put('/pharmacy/finance/expenses/$id', data: payload);
      }
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      try {
        await ApiClient.instance.dio.delete('/v1/pharmacy/finance/expenses/$id');
      } catch (_) {
        await ApiClient.instance.dio.delete('/pharmacy/finance/expenses/$id');
      }
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Cari transaksi untuk diretur. `null` bila nomor invoice tidak ditemukan.
  Future<ReturnableOrder?> findOrder(String invoiceNo) async {
    try {
      final q = {'invoice_no': invoiceNo.trim()};
      dynamic res;
      try {
        res = await ApiClient.instance.dio.get(
          '/v1/pharmacy/returns/pos/order',
          queryParameters: q,
        );
      } catch (_) {
        res = await ApiClient.instance.dio.get(
          '/pharmacy/returns/pos/order',
          queryParameters: q,
        );
      }
      return ReturnableOrder.fromJson(_data(res.data));
    } catch (e) {
      final error = ApiException.from(e);
      if (error.statusCode == 404) return null;
      throw error;
    }
  }

  /// Kirim retur. [quantities] berisi id item → jumlah yang diretur.
  Future<void> submitReturn({
    required String invoiceNo,
    required Map<int, double> quantities,
    String? notes,
  }) async {
    try {
      final payload = {
        'invoice_no': invoiceNo,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        'items': [
          for (final e in quantities.entries)
            if (e.value > 0) {'id': e.key, 'quantity': e.value},
        ],
      };
      try {
        await ApiClient.instance.dio.post('/v1/pharmacy/returns/pos', data: payload);
      } catch (_) {
        await ApiClient.instance.dio.post('/pharmacy/returns/pos', data: payload);
      }
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}
