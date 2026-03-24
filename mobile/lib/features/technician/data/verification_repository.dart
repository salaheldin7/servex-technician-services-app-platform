import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/models/verification_models.dart';

class VerificationRepository {
  final ApiClient _apiClient;

  VerificationRepository(this._apiClient);

  // --- Verification Status ---

  Future<ApiResult<VerificationStatus>> getVerificationStatus() async {
    try {
      final response = await _apiClient.get(ApiConstants.verificationStatus);
      return ApiResult.success(VerificationStatus.fromJson(response.data));
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  // --- Face Verification ---

  Future<ApiResult<void>> uploadFace({
    required XFile frontImage,
    required XFile rightImage,
    required XFile leftImage,
  }) async {
    try {
      final Uint8List frontBytes = await frontImage.readAsBytes();
      final Uint8List rightBytes = await rightImage.readAsBytes();
      final Uint8List leftBytes = await leftImage.readAsBytes();

      final frontBase64 = base64Encode(frontBytes);
      final rightBase64 = base64Encode(rightBytes);
      final leftBase64 = base64Encode(leftBytes);

      await _apiClient.post(
        ApiConstants.verificationFace,
        data: {
          'face_front': frontBase64,
          'face_right': rightBase64,
          'face_left': leftBase64,
        },
      );
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    } catch (e) {
      return ApiResult.failure(ApiError(message: 'Upload failed: $e'));
    }
  }

  // --- ID Documents ---

  Future<ApiResult<void>> uploadDocuments(List<XFile> files) async {
    try {
      final docs = <Map<String, String>>[];
      for (int i = 0; i < files.length; i++) {
        final bytes = await files[i].readAsBytes();
        final b64 = base64Encode(bytes);
        String docType = i == 0 ? 'id_card_front' : 'id_card_back';
        docs.add({'data': b64, 'doc_type': docType});
      }

      await _apiClient.post(
        ApiConstants.verificationDocumentsBase64,
        data: {'documents': docs},
      );
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    } catch (e) {
      return ApiResult.failure(ApiError(message: 'Upload failed: $e'));
    }
  }

  // --- Technician Services ---

  Future<ApiResult<List<TechnicianService>>> getServices() async {
    try {
      final response = await _apiClient.get(ApiConstants.technicianServices);
      final list = (response.data['services'] as List?)
              ?.map((e) => TechnicianService.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return ApiResult.success(list);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<List<TechnicianService>>> addServices(
      List<Map<String, dynamic>> services) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.technicianServices,
        data: {'services': services},
      );
      final list = (response.data['services'] as List?)
              ?.map((e) => TechnicianService.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return ApiResult.success(list);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<void>> removeService(String serviceId) async {
    try {
      await _apiClient.delete(ApiConstants.technicianServiceById(serviceId));
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  // --- Service Locations ---

  Future<ApiResult<List<ServiceLocation>>> getLocations() async {
    try {
      final response =
          await _apiClient.get(ApiConstants.technicianServiceLocations);
      final list = (response.data['locations'] as List?)
              ?.map((e) => ServiceLocation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return ApiResult.success(list);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<List<ServiceLocation>>> addLocations(
      List<Map<String, dynamic>> locations) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.technicianServiceLocations,
        data: {'locations': locations},
      );
      final list = (response.data['locations'] as List?)
              ?.map((e) => ServiceLocation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return ApiResult.success(list);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<void>> removeLocation(String locationId) async {
    try {
      await _apiClient
          .delete(ApiConstants.technicianServiceLocationById(locationId));
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }
}
