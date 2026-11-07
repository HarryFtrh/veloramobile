import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/safe_json.dart';

class SalesVisit {
  final String id;
  final String customerName;
  final String? customerAddress;
  final String? status;
  final DateTime? checkinAt;
  final String? notes;

  SalesVisit({
    required this.id,
    required this.customerName,
    this.customerAddress,
    this.status,
    this.checkinAt,
    this.notes,
  });

  factory SalesVisit.fromJson(Map<String, dynamic> json) {
    return SalesVisit(
      id: json.getString('id'),
      customerName: json.getString('customer_name', fallback: json.getString('name', fallback: 'Tanpa nama')),
      customerAddress: json.getString('customer_address', fallback: json.getString('address')),
      status: json.getString('status', fallback: 'scheduled'),
      checkinAt: json['checkin_at'] != null ? DateTime.tryParse(json.getString('checkin_at')) : null,
      notes: json.getString('notes'),
    );
  }
}

class SalesAttendanceStatus {
  final bool isClockedIn;
  final DateTime? clockInAt;
  final DateTime? clockOutAt;
  final double? latitude;
  final double? longitude;

  SalesAttendanceStatus({
    required this.isClockedIn,
    this.clockInAt,
    this.clockOutAt,
    this.latitude,
    this.longitude,
  });
}

class SalesService {
  static final SalesService instance = SalesService._();
  SalesService._();

  Future<Map<String, dynamic>> clockIn({
    required double latitude,
    required double longitude,
    String? selfiePhotoPath,
  }) async {
    final empId = SessionStorage.instance.getUserId()?.toString();
    final payload = <String, dynamic>{
      if (empId != null && empId.isNotEmpty) 'employee_id': empId,
      'gps_latitude': latitude.toString(),
      'gps_longitude': longitude.toString(),
      'latitude': latitude,
      'longitude': longitude,
    };
    if (selfiePhotoPath != null) {
      payload['selfie_photo_path'] = selfiePhotoPath;
    }

    final endpoints = [
      '/v1/mobile/salesman/clock-in',
      '/mobile/salesman/clock-in',
      '/v1/salesman/clock-in',
    ];

    for (final ep in endpoints) {
      try {
        final response = await ApiClient.instance.dio.post(
          ep,
          data: payload,
        );
        final rawData = response.data;
        if (rawData is Map) {
          final inner = rawData['data'];
          return inner is Map ? Map<String, dynamic>.from(inner) : Map<String, dynamic>.from(rawData);
        }
      } catch (_) {}
    }
    return {};
  }

  Future<Map<String, dynamic>> clockOut({
    required double latitude,
    required double longitude,
  }) async {
    final empId = SessionStorage.instance.getUserId()?.toString();
    final payload = {
      if (empId != null && empId.isNotEmpty) 'employee_id': empId,
      'gps_latitude': latitude.toString(),
      'gps_longitude': longitude.toString(),
      'latitude': latitude,
      'longitude': longitude,
    };

    final endpoints = [
      '/v1/mobile/salesman/clock-out',
      '/mobile/salesman/clock-out',
      '/v1/salesman/clock-out',
    ];

    for (final ep in endpoints) {
      try {
        final response = await ApiClient.instance.dio.post(
          ep,
          data: payload,
        );
        final rawData = response.data;
        if (rawData is Map) {
          final inner = rawData['data'];
          return inner is Map ? Map<String, dynamic>.from(inner) : Map<String, dynamic>.from(rawData);
        }
      } catch (_) {}
    }
    return {};
  }

  Future<List<SalesVisit>> getScheduledVisits() async {
    final endpoints = [
      '/v1/mobile/salesman/schedule-visits',
      '/mobile/salesman/schedule-visits',
      '/v1/salesman/visits',
    ];

    dynamic rawData;
    for (final ep in endpoints) {
      try {
        final response = await ApiClient.instance.dio.get(ep);
        if (response.statusCode == 200 && response.data != null) {
          rawData = response.data;
          break;
        }
      } catch (_) {}
    }

    List items = [];
    if (rawData is Map) {
      final inner = rawData['data'];
      final visits = rawData['visits'];
      items = inner is List ? inner : (visits is List ? visits : const []);
    } else if (rawData is List) {
      items = rawData;
    }

    return items
        .whereType<Map>()
        .map((e) => SalesVisit.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<String, dynamic>> recordVisitLog({
    required String customerName,
    required double latitude,
    required double longitude,
    String? customerAddress,
    String? visitType,
    String? notes,
  }) async {
    final payload = {
      'customer_name': customerName,
      'customer_address': customerAddress,
      'latitude': latitude,
      'longitude': longitude,
      'visit_type': visitType ?? 'routine_visit',
      'status': 'completed',
      'notes': notes,
    };

    final endpoints = [
      '/v1/mobile/salesman/visit-logs',
      '/mobile/salesman/visit-logs',
      '/v1/salesman/visit-logs',
    ];

    for (final ep in endpoints) {
      try {
        final response = await ApiClient.instance.dio.post(
          ep,
          data: payload,
        );
        final rawData = response.data;
        if (rawData is Map) {
          final inner = rawData['data'];
          return inner is Map ? Map<String, dynamic>.from(inner) : Map<String, dynamic>.from(rawData);
        }
      } catch (_) {}
    }
    return {};
  }

  Future<Map<String, dynamic>> createOrderTaking({
    required String customerName,
    required List<Map<String, dynamic>> items,
    String? notes,
    String? paymentTerms,
  }) async {
    final payload = {
      'customer_name': customerName,
      'customer_type': 'offline',
      'items': items,
      'payment_terms': paymentTerms ?? 'TOP_30',
      'notes': notes,
    };

    final endpoints = [
      '/v1/mobile/salesman/order-taking',
      '/mobile/salesman/order-taking',
      '/v1/salesman/orders',
    ];

    for (final ep in endpoints) {
      try {
        final response = await ApiClient.instance.dio.post(
          ep,
          data: payload,
        );
        final rawData = response.data;
        if (rawData is Map) {
          final inner = rawData['data'];
          return inner is Map ? Map<String, dynamic>.from(inner) : Map<String, dynamic>.from(rawData);
        }
      } catch (_) {}
    }
    return {};
  }
}
