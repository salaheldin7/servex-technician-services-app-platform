import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/websocket_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/auth_models.dart';
import '../../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return AuthRepository(apiClient);
});

final authStateProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  AuthState build() {
    _initAuth();
    return AuthState(isLoading: true);
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);
  WebSocketClient get _ws => ref.read(wsClientProvider);

  Future<void> _initAuth() async {
    // Note: build() already returns AuthState(isLoading: true)
    // so we don't read state here (would crash in Riverpod 3.x)
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    if (token != null) {
      final result = await _repo.getProfile();
      if (result.isSuccess) {
        state = AuthState(
          user: result.data,
          isAuthenticated: true,
          isLoading: false,
        );
        _ws.connect();
      } else {
        await _clearTokens();
        state = AuthState(isLoading: false);
      }
    } else {
      state = AuthState(isLoading: false);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repo.login(email: email, password: password);
    if (result.isSuccess) {
      final data = result.data!;
      await _saveTokens(
        data['access_token'],
        data['refresh_token'],
      );

      // Fetch full user profile from /users/me
      final profileResult = await _repo.getProfile();
      if (profileResult.isSuccess) {
        final user = profileResult.data!;
        await _storage.write(key: AppConstants.userRoleKey, value: user.role);
        await _storage.write(key: AppConstants.userIdKey, value: user.id);

        state = AuthState(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
        _ws.connect();
      } else {
        // Tokens saved but profile fetch failed — use role from token response
        await _storage.write(key: AppConstants.userRoleKey, value: data['role'] ?? 'customer');
        state = AuthState(
          isAuthenticated: true,
          isLoading: false,
        );
        _ws.connect();
      }
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error?.message,
      );
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
    String? username,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repo.register(
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
      role: role,
      username: username,
    );

    if (result.isSuccess) {
      final data = result.data!;
      await _saveTokens(
        data['access_token'],
        data['refresh_token'],
      );

      // Fetch full user profile from /users/me
      final profileResult = await _repo.getProfile();
      if (profileResult.isSuccess) {
        final user = profileResult.data!;
        await _storage.write(key: AppConstants.userRoleKey, value: user.role);
        await _storage.write(key: AppConstants.userIdKey, value: user.id);

        state = AuthState(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
        _ws.connect();
      } else {
        await _storage.write(key: AppConstants.userRoleKey, value: data['role'] ?? 'customer');
        state = AuthState(
          isAuthenticated: true,
          isLoading: false,
        );
        _ws.connect();
      }
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error?.message,
      );
    }
  }

  Future<void> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repo.sendOtp(phone: phone);
    state = state.copyWith(
      isLoading: false,
      error: result.isFailure ? result.error?.message : null,
    );
  }

  Future<bool> verifyOtp({required String phone, required String code}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repo.verifyOtp(phone: phone, code: code);

    if (result.isSuccess) {
      state = state.copyWith(isLoading: false);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error?.message,
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    await _clearTokens();
    _ws.disconnect();
    state = AuthState();
  }

  Future<void> updateUser(User user) async {
    state = state.copyWith(user: user);
  }

  Future<void> _saveTokens(String access, String refresh) async {
    await _storage.write(key: AppConstants.accessTokenKey, value: access);
    await _storage.write(key: AppConstants.refreshTokenKey, value: refresh);
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.userRoleKey);
    await _storage.delete(key: AppConstants.userIdKey);
  }
}
