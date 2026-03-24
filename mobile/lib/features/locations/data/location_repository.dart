import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/models/location_models.dart';

class LocationRepository {
  final ApiClient _apiClient;

  LocationRepository(this._apiClient);

  Future<ApiResult<List<Country>>> getCountries() async {
    try {
      final response = await _apiClient.get(ApiConstants.countries);
      final data = response.data;
      final rawList = data is Map ? (data['countries'] as List?) : (data as List?);
      final list = rawList
              ?.map((e) => Country.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return ApiResult.success(list);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<List<Governorate>>> getGovernorates(String countryId) async {
    try {
      final response = await _apiClient.get(ApiConstants.governorates(countryId));
      final data = response.data;
      final rawList = data is Map ? (data['governorates'] as List?) : (data as List?);
      final list = rawList
              ?.map((e) => Governorate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return ApiResult.success(list);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<List<City>>> getCities(String governorateId) async {
    try {
      final response = await _apiClient.get(ApiConstants.cities(governorateId));
      final data = response.data;
      final rawList = data is Map ? (data['cities'] as List?) : (data as List?);
      final list = rawList
              ?.map((e) => City.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return ApiResult.success(list);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }
}
