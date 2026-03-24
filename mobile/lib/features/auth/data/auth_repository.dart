import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/models/auth_models.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<ApiResult<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      return ApiResult.success(response.data);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
    String? username,
  }) async {
    try {
      final data = {
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
      };
      if (username != null && username.isNotEmpty) {
        data['username'] = username;
      }
      final response = await _apiClient.post(
        ApiConstants.register,
        data: data,
      );
      return ApiResult.success(response.data);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> checkUsername(String username) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.checkUsername}?username=$username',
      );
      return ApiResult.success(response.data);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> generateUsername(String name) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.generateUsername}?name=$name',
      );
      return ApiResult.success(response.data);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<void>> sendOtp({required String phone}) async {
    try {
      await _apiClient.post(
        ApiConstants.sendOtp,
        data: {'phone': phone},
      );
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> verifyOtp({
    required String phone,
    required String code,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.verifyOtp,
        data: {'phone': phone, 'code': code},
      );
      return ApiResult.success(response.data);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> refreshToken(String refreshToken) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken},
      );
      return ApiResult.success(response.data);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<User>> getProfile() async {
    try {
      final response = await _apiClient.get(ApiConstants.userProfile);
      return ApiResult.success(User.fromJson(response.data));
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<void>> logout() async {
    try {
      await _apiClient.post(ApiConstants.logout);
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }
}
