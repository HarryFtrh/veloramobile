import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/safe_json.dart';

/// Satu sesi login (token Sanctum) milik pengguna di suatu perangkat.
class ActiveSession {
  const ActiveSession({
    required this.id,
    required this.deviceName,
    required this.isCurrent,
    this.lastUsedAt,
    this.createdAt,
  });

  final String id;
  final String deviceName;
  final bool isCurrent;
  final DateTime? lastUsedAt;
  final DateTime? createdAt;

  factory ActiveSession.fromJson(Map<String, dynamic> json) => ActiveSession(
        id: json.getString('id'),
        deviceName: json.getString('name', fallback: 'Perangkat tidak dikenal'),
        isCurrent: json.getBool('is_current'),
        lastUsedAt: DateTime.tryParse(json.getString('last_used_at'))?.toLocal(),
        createdAt: DateTime.tryParse(json.getString('created_at'))?.toLocal(),
      );
}

class SettingsService {
  static final SettingsService instance = SettingsService._();
  SettingsService._();

  /// `GET /v1/profile/tokens` (fallback `/profile/tokens`) mengembalikan daftar langsung di `data`.
  Future<List<ActiveSession>> sessions() async {
    try {
      dynamic res;
      try {
        res = await ApiClient.instance.dio.get('/v1/profile/tokens');
      } catch (_) {
        res = await ApiClient.instance.dio.get('/profile/tokens');
      }
      final body = res.data;
      final raw = body is Map<String, dynamic> ? body['data'] : body;
      if (raw is! List) return const [];
      return [
        for (final item in raw)
          if (item is Map<String, dynamic>) ActiveSession.fromJson(item),
      ];
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Cabut sesi lain. Perangkat tersebut otomatis keluar.
  Future<void> revoke(String sessionId) async {
    try {
      try {
        await ApiClient.instance.dio.delete('/v1/profile/tokens/$sessionId');
      } catch (_) {
        await ApiClient.instance.dio.delete('/profile/tokens/$sessionId');
      }
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}
