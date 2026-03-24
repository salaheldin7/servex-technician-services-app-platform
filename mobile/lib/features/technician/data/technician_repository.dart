import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';

class TechnicianStats {
  final double rating;
  final int completedJobs;
  final double balance;
  final double debt;
  final int strikes;
  final bool isOnline;
  final bool isVerified;
  final double todayEarnings;
  final double weekEarnings;
  final double monthEarnings;

  TechnicianStats({
    this.rating = 0,
    this.completedJobs = 0,
    this.balance = 0,
    this.debt = 0,
    this.strikes = 0,
    this.isOnline = false,
    this.isVerified = false,
    this.todayEarnings = 0,
    this.weekEarnings = 0,
    this.monthEarnings = 0,
  });

  factory TechnicianStats.fromJson(Map<String, dynamic> json) {
    return TechnicianStats(
      rating: (json['rating'] ?? 0).toDouble(),
      completedJobs: json['completed_jobs'] ?? 0,
      balance: (json['balance'] ?? 0).toDouble(),
      debt: (json['debt'] ?? 0).toDouble(),
      strikes: json['strikes'] ?? 0,
      isOnline: json['is_online'] ?? false,
      isVerified: json['is_verified'] ?? false,
      todayEarnings: (json['today_earnings'] ?? 0).toDouble(),
      weekEarnings: (json['week_earnings'] ?? 0).toDouble(),
      monthEarnings: (json['month_earnings'] ?? 0).toDouble(),
    );
  }
}

class TechnicianRepository {
  final ApiClient _apiClient;

  TechnicianRepository(this._apiClient);

  Future<ApiResult<TechnicianStats>> getStats() async {
    try {
      final response = await _apiClient.get(ApiConstants.technicianStats);
      return ApiResult.success(TechnicianStats.fromJson(response.data));
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> getEarnings({
    String period = 'month',
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.technicianEarnings,
        queryParameters: {'period': period},
      );
      return ApiResult.success(response.data);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<void>> goOnline() async {
    try {
      await _apiClient.put(
        ApiConstants.technicianOnline,
        data: {'is_online': true},
      );
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<void>> goOffline() async {
    try {
      await _apiClient.put(
        ApiConstants.technicianOnline,
        data: {'is_online': false},
      );
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<void>> updateLocation(double lat, double lng) async {
    try {
      await _apiClient.put(
        ApiConstants.technicianLocation,
        data: {'lat': lat, 'lng': lng},
      );
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<void>> acceptBooking(String bookingId) async {
    try {
      await _apiClient.post(ApiConstants.bookingAccept(bookingId));
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<List<Map<String, dynamic>>>> getPendingRequests() async {
    try {
      final response = await _apiClient.get(ApiConstants.pendingRequests);
      final data = response.data;
      final requests = (data['requests'] as List?)
              ?.map((r) => Map<String, dynamic>.from(r))
              .toList() ??
          [];
      return ApiResult.success(requests);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<void>> registerProfile({
    required List<String> categoryIds,
    required String idCardPath,
    String? certificationPath,
  }) async {
    try {
      await _apiClient.post(
        ApiConstants.technicianRegister,
        data: {
          'category_ids': categoryIds,
        },
      );
      // Upload documents
      if (idCardPath.isNotEmpty) {
        await _apiClient.uploadFile(
          '${ApiConstants.technicianRegister}/documents',
          filePath: idCardPath,
          fieldName: 'id_card',
        );
      }
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }
}
