import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../home/domain/models/home_models.dart';

class BookingRepository {
  final ApiClient _apiClient;

  BookingRepository(this._apiClient);

  Future<ApiResult<Booking>> createBooking({
    required String categoryId,
    required String description,
    required double latitude,
    required double longitude,
    required String address,
    String? scheduledAt,
    required double estimatedPrice,
    required String paymentMethod,
    String? countryId,
    String? governorateId,
    String? cityId,
    String? addressId,
    String? streetName,
    String? buildingName,
    String? buildingNumber,
    String? floor,
    String? apartment,
    String? fullAddress,
    String? technicianId,
    bool autoAssign = false,
  }) async {
    try {
      final data = <String, dynamic>{
        'category_id': categoryId,
        'description': description,
        'lat': latitude,
        'lng': longitude,
        'address': address.isNotEmpty ? address : 'Auto-detected',
        'payment_method': paymentMethod,
        'auto_assign': autoAssign,
      };
      if (countryId != null && countryId.isNotEmpty) data['country_id'] = countryId;
      if (governorateId != null && governorateId.isNotEmpty) data['governorate_id'] = governorateId;
      if (cityId != null && cityId.isNotEmpty) data['city_id'] = cityId;
      if (scheduledAt != null && scheduledAt.isNotEmpty) data['scheduled_at'] = scheduledAt;
      if (estimatedPrice > 0) data['estimated_cost'] = estimatedPrice;
      if (addressId != null && addressId.isNotEmpty) data['address_id'] = addressId;
      if (streetName != null && streetName.isNotEmpty) data['street_name'] = streetName;
      if (buildingName != null && buildingName.isNotEmpty) data['building_name'] = buildingName;
      if (buildingNumber != null && buildingNumber.isNotEmpty) data['building_number'] = buildingNumber;
      if (floor != null && floor.isNotEmpty) data['floor'] = floor;
      if (apartment != null && apartment.isNotEmpty) data['apartment'] = apartment;
      if (fullAddress != null && fullAddress.isNotEmpty) data['full_address'] = fullAddress;
      if (technicianId != null && technicianId.isNotEmpty) data['technician_id'] = technicianId;

      final response = await _apiClient.post(
        ApiConstants.bookings,
        data: data,
      );
      return ApiResult.success(Booking.fromJson(response.data));
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<List<Booking>>> listBookings({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.bookings,
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      final data = response.data;
      final bookings = (data['bookings'] as List?)
              ?.map((b) => Booking.fromJson(b))
              .toList() ??
          [];
      return ApiResult.success(bookings);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<List<Map<String, dynamic>>>> searchTechnicians({
    required String categoryId,
    required String countryId,
    required String governorateId,
    required String cityId,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.technicianSearch,
        queryParameters: {
          'category_id': categoryId,
          'country_id': countryId,
          'governorate_id': governorateId,
          'city_id': cityId,
        },
      );
      final techs = (response.data['technicians'] as List?)
              ?.map((t) => t as Map<String, dynamic>)
              .toList() ??
          [];
      return ApiResult.success(techs);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> autoAssignTechnician({
    required String categoryId,
    required String countryId,
    required String governorateId,
    required String cityId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.technicianAutoAssign,
        data: {
          'category_id': categoryId,
          'country_id': countryId,
          'governorate_id': governorateId,
          'city_id': cityId,
        },
      );
      return ApiResult.success(response.data['technician'] as Map<String, dynamic>);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<Booking>> getBooking(String id) async {
    try {
      final response = await _apiClient.get(ApiConstants.bookingById(id));
      return ApiResult.success(Booking.fromJson(response.data));
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<void>> acceptBooking(String id) async {
    try {
      await _apiClient.post(ApiConstants.bookingAccept(id));
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<void>> cancelBooking(String id, {String? reason}) async {
    try {
      await _apiClient.post(
        ApiConstants.bookingCancel(id),
        data: {'reason': (reason != null && reason.isNotEmpty) ? reason : 'User cancelled'},
      );
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<void>> arriveAtBooking(String id) async {
    try {
      await _apiClient.post(ApiConstants.bookingArrive(id));
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<void>> verifyArrival(
    String id, {
    required String code,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _apiClient.post(
        ApiConstants.bookingVerifyArrival(id),
        data: {
          'code': code,
          'lat': latitude,
          'lng': longitude,
        },
      );
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<void>> startJob(String id) async {
    try {
      await _apiClient.post(ApiConstants.bookingStart(id));
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<void>> completeJob(String id, {double? finalPrice}) async {
    try {
      await _apiClient.post(
        ApiConstants.bookingComplete(id),
        data: {'final_cost': finalPrice ?? 0},
      );
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }
}
