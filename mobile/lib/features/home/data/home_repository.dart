import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/models/home_models.dart';

class HomeRepository {
  final ApiClient _apiClient;

  HomeRepository(this._apiClient);

  Future<ApiResult<List<Category>>> getCategories() async {
    try {
      final response = await _apiClient.get(ApiConstants.categories);
      final data = response.data;
      final List<dynamic> items;
      if (data is Map) {
        items = data['categories'] ?? [];
      } else if (data is List) {
        items = data;
      } else {
        items = [];
      }
      final list = items
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResult.success(list);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<List<NearbyTechnician>>> getNearbyTechnicians({
    required double lat,
    required double lng,
    double radius = 5000,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.nearbyTechnicians,
        queryParameters: {
          'latitude': lat,
          'longitude': lng,
          'radius': radius,
        },
      );
      final list = (response.data as List)
          .map((e) => NearbyTechnician.fromJson(e))
          .toList();
      return ApiResult.success(list);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<List<Booking>>> getActiveBookings() async {
    try {
      final response = await _apiClient.get(
        ApiConstants.bookings,
      );
      final data = response.data;
      final List<dynamic> items;
      if (data is Map) {
        items = data['bookings'] ?? [];
      } else if (data is List) {
        items = data;
      } else {
        items = [];
      }
      final list = items
          .map((e) => Booking.fromJson(e as Map<String, dynamic>))
          .where((b) => b.isActive)
          .toList();
      return ApiResult.success(list);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<List<Booking>>> getBookingHistory({int page = 1}) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.bookings,
        queryParameters: {'page': page, 'page_size': 20},
      );
      final data = response.data;
      final List<dynamic> items;
      if (data is Map) {
        items = data['bookings'] ?? [];
      } else if (data is List) {
        items = data;
      } else {
        items = [];
      }
      final list = items
          .map((e) => Booking.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResult.success(list);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }
}
