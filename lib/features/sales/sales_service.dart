import '../../core/network/api_client.dart';
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
    final payload = <String, dynamic>{
      'gps_latitude': latitude,
      'gps_longitude': longitude,
    };
    if (selfiePhotoPath != null) {
      payload['selfie_photo_path'] = selfiePhotoPath;
    }

    final response = await ApiClient.instance.dio.post(
      '/v1/mobile/salesman/clock-in',
      data: payload,
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      return rawData['data'] is Map<String, dynamic> ? rawData['data'] : rawData;
    }
    return {};
  }

  Future<Map<String, dynamic>> clockOut({
    required double latitude,
    required double longitude,
  }) async {
    final response = await ApiClient.instance.dio.post(
      '/v1/mobile/salesman/clock-out',
      data: {
        'gps_latitude': latitude,
        'gps_longitude': longitude,
      },
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      return rawData['data'] is Map<String, dynamic> ? rawData['data'] : rawData;
    }
    return {};
  }

  Future<List<SalesVisit>> getScheduledVisits() async {
    final response = await ApiClient.instance.dio.get('/v1/mobile/salesman/schedule-visits');
    final rawData = response.data;
    List items = [];
    if (rawData is Map<String, dynamic>) {
      items = rawData['data'] is List ? rawData['data'] as List : [];
    } else if (rawData is List) {
      items = rawData;
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((e) => SalesVisit.fromJson(e))
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
    final response = await ApiClient.instance.dio.post(
      '/v1/mobile/salesman/visit-logs',
      data: {
        'customer_name': customerName,
        'customer_address': customerAddress,
        'latitude': latitude,
        'longitude': longitude,
        'visit_type': visitType ?? 'routine_visit',
        'status': 'completed',
        'notes': notes,
      },
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      return rawData['data'] is Map<String, dynamic> ? rawData['data'] : rawData;
    }
    return {};
  }

  Future<Map<String, dynamic>> createOrderTaking({
    required String customerName,
    required List<Map<String, dynamic>> items,
    String? notes,
    String? paymentTerms,
  }) async {
    final response = await ApiClient.instance.dio.post(
      '/v1/mobile/salesman/order-taking',
      data: {
        'customer_name': customerName,
        'customer_type': 'offline',
        'items': items,
        'payment_terms': paymentTerms ?? 'TOP_30',
        'notes': notes,
      },
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      return rawData['data'] is Map<String, dynamic> ? rawData['data'] : rawData;
    }
    return {};
  }
}
