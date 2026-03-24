import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';

class UserAddress {
  final String id;
  final String userId;
  final String label;
  final String? countryId;
  final String? governorateId;
  final String? cityId;
  final String streetName;
  final String buildingName;
  final String buildingNumber;
  final String floor;
  final String apartment;
  final double? latitude;
  final double? longitude;
  final String fullAddress;
  final bool isDefault;
  final String countryName;
  final String governorateName;
  final String cityName;

  UserAddress({
    required this.id,
    required this.userId,
    this.label = 'Home',
    this.countryId,
    this.governorateId,
    this.cityId,
    this.streetName = '',
    this.buildingName = '',
    this.buildingNumber = '',
    this.floor = '',
    this.apartment = '',
    this.latitude,
    this.longitude,
    this.fullAddress = '',
    this.isDefault = false,
    this.countryName = '',
    this.governorateName = '',
    this.cityName = '',
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      label: json['label'] ?? 'Home',
      countryId: json['country_id'],
      governorateId: json['governorate_id'],
      cityId: json['city_id'],
      streetName: json['street_name'] ?? '',
      buildingName: json['building_name'] ?? '',
      buildingNumber: json['building_number'] ?? '',
      floor: json['floor'] ?? '',
      apartment: json['apartment'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      fullAddress: json['full_address'] ?? '',
      isDefault: json['is_default'] ?? false,
      countryName: json['country_name'] ?? '',
      governorateName: json['governorate_name'] ?? '',
      cityName: json['city_name'] ?? '',
    );
  }

  String get displayAddress {
    final parts = <String>[];
    if (buildingNumber.isNotEmpty) parts.add(buildingNumber);
    if (floor.isNotEmpty) parts.add('Floor $floor');
    if (apartment.isNotEmpty) parts.add('Apt $apartment');
    if (streetName.isNotEmpty) parts.add(streetName);
    if (cityName.isNotEmpty) parts.add(cityName);
    if (governorateName.isNotEmpty) parts.add(governorateName);
    if (countryName.isNotEmpty) parts.add(countryName);
    return parts.isNotEmpty ? parts.join(', ') : fullAddress;
  }
}

class AddressRepository {
  final ApiClient _apiClient;

  AddressRepository(this._apiClient);

  Future<ApiResult<List<UserAddress>>> getAddresses() async {
    try {
      final response = await _apiClient.get(ApiConstants.addresses);
      final list = response.data['addresses'] as List? ?? [];
      return ApiResult.success(list.map((e) => UserAddress.fromJson(e)).toList());
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<UserAddress>> getDefault() async {
    try {
      final response = await _apiClient.get(ApiConstants.defaultAddress);
      return ApiResult.success(UserAddress.fromJson(response.data));
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<UserAddress>> create(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(ApiConstants.addresses, data: data);
      return ApiResult.success(UserAddress.fromJson(response.data));
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<void>> setDefault(String id) async {
    try {
      await _apiClient.put(ApiConstants.addressSetDefault(id));
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<void>> delete(String id) async {
    try {
      await _apiClient.delete(ApiConstants.addressDelete(id));
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }
}
