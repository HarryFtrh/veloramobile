import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/session_storage.dart';
import '../auth_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;

  AuthCubit({AuthService? authService})
      : _authService = authService ?? AuthService.instance,
        super(const AuthInitial()) {
    ApiClient.onSessionExpired = () {
      emit(const Unauthenticated());
    };
  }

  /// Checks stored credentials on startup with safe fallback
  Future<void> checkAuthStatus() async {
    emit(const AuthLoading(message: 'Memverifikasi sesi kasir...'));
    try {
      final token = await SessionStorage.instance.getAuthToken();
      if (token == null || token.isEmpty) {
        emit(const Unauthenticated());
        return;
      }

      // Live validation of session token against backend /me
      try {
        final liveUser = await _authService.getProfile();
        if (liveUser == null) {
          // Token revoked or expired on server
          await SessionStorage.instance.clearAll();
          emit(const Unauthenticated());
          return;
        }

        // Gerbang flavor: sesi pelanggan tidak boleh membuka app kasir/staf
        if (AppConfig.instance.flavor != AppFlavor.customer && liveUser.isCustomerAccount) {
          await SessionStorage.instance.clearAll();
          emit(const Unauthenticated());
          return;
        }

        // Token valid, refresh cache
        await SessionStorage.instance.saveTenantId(liveUser.tenantId);
        await SessionStorage.instance.saveUserProfile(
          id: liveUser.id,
          name: liveUser.name,
          email: liveUser.email,
          businessType: liveUser.businessType,
          role: liveUser.role,
        );
        await SessionStorage.instance.saveUserPermissions(liveUser.permissions);
        final locName = SessionStorage.instance.getLocationName() ??
            (liveUser.locations.isNotEmpty ? liveUser.locations.first.name : 'Cabang Utama');

        emit(Authenticated(user: liveUser, activeLocationName: locName));
        return;
      } catch (_) {
        // Offline POS fallback using real saved session details
        final userId = SessionStorage.instance.getUserId();
        final tenantId = SessionStorage.instance.getTenantId();
        final locationId = SessionStorage.instance.getLocationId();

        // Fail-closed security rule: tanpa tenant_id atau user_id tersimpan riil, jangan buka sesi palsu
        if (userId == null || tenantId == null || tenantId.isEmpty || locationId == null || locationId.isEmpty) {
          emit(const Unauthenticated());
          return;
        }

        final userName = SessionStorage.instance.getUserName() ?? 'Kasir';
        final userEmail = SessionStorage.instance.getUserEmail() ?? '';
        final tenantName = SessionStorage.instance.getTenantName() ?? 'Toko';
        final businessType = SessionStorage.instance.getBusinessType() ?? 'pos';
        final locationName = SessionStorage.instance.getLocationName() ?? 'Cabang Kasir';

        final userRole = SessionStorage.instance.getUserRole() ?? 'cashier';
        final userPermissions = SessionStorage.instance.getUserPermissions();
        final cachedUser = AuthUser(
          id: userId,
          name: userName,
          email: userEmail,
          role: userRole,
          permissions: userPermissions,
          tenantId: tenantId,
          tenantName: tenantName,
          businessType: businessType,
          locations: [
            BranchLocation(id: locationId, name: locationName, isMain: true),
          ],
        );

        emit(Authenticated(user: cachedUser, activeLocationName: locationName));
      }
    } catch (e) {
      // In case of storage corruption, safely reset to unauthenticated
      emit(const Unauthenticated());
    }
  }

  /// Handles login attempt with email and password
  Future<void> login({required String email, required String password}) async {
    emit(const AuthLoading(message: 'Mengotentikasi kasir...'));
    try {
      final user = await _authService.login(email: email, password: password);

      // Hanya akun berizin ganti cabang yang memiliki lebih dari 1 cabang yang memilih cabang.
      // Akun kasir langsung masuk ke cabang bertugasnya.
      if (user.can(AppPermission.changeBranch) && user.locations.length > 1) {
        emit(AuthBranchSelectionRequired(user: user));
      } else {
        final locName = user.locations.isNotEmpty
            ? user.locations.first.name
            : SessionStorage.instance.getLocationName();
        emit(Authenticated(user: user, activeLocationName: locName));
      }
    } on DioException catch (e) {
      final message = e.response?.data['message']?.toString() ??
          'Login gagal. Periksa koneksi internet atau kredensial Anda.';
      emit(AuthFailure(message));
      emit(const Unauthenticated());
    } catch (e) {
      emit(AuthFailure('Terjadi kesalahan: ${e.toString()}'));
      emit(const Unauthenticated());
    }
  }

  /// Branch selection if user operates multiple outlets
  Future<void> selectBranch({
    required AuthUser user,
    required BranchLocation location,
  }) async {
    await _authService.selectBranch(location);
    emit(Authenticated(user: user, activeLocationName: location.name));
  }

  /// Graceful logout
  Future<void> logout() async {
    emit(const AuthLoading(message: 'Menutup sesi kasir...'));
    await _authService.logout();
    await SessionStorage.instance.clearAll();
    emit(const Unauthenticated());
  }
}
