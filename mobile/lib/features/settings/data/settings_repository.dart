import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';

class SettingsRepository {
  final ApiClient _apiClient;

  SettingsRepository(this._apiClient);

  Future<ApiResult<void>> updateName(String name) async {
    try {
      await _apiClient.put(ApiConstants.settingsName, data: {'full_name': name});
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<void>> updatePhone(String phone) async {
    try {
      await _apiClient.put(ApiConstants.settingsPhone, data: {'phone': phone});
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<void>> updateEmail(String email) async {
    try {
      await _apiClient.put(ApiConstants.settingsEmail, data: {'email': email});
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<void>> updateLanguage(String lang) async {
    try {
      await _apiClient.put(
          ApiConstants.settingsLanguage, data: {'language': lang});
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<void>> deleteAccount() async {
    try {
      await _apiClient.delete(ApiConstants.settingsDeleteAccount);
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.read(apiClientProvider));
});
