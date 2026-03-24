import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';

class Rating {
  final String id;
  final String bookingId;
  final String userId;
  final String technicianId;
  final int score;
  final String? comment;
  final DateTime createdAt;

  Rating({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.technicianId,
    required this.score,
    this.comment,
    required this.createdAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'] ?? '',
      bookingId: json['booking_id'] ?? '',
      userId: json['user_id'] ?? '',
      technicianId: json['technician_id'] ?? '',
      score: json['score'] ?? 0,
      comment: json['comment'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class RatingRepository {
  final ApiClient _apiClient;

  RatingRepository(this._apiClient);

  Future<ApiResult<void>> submitRating({
    required String bookingId,
    required String technicianId,
    required int score,
    String? comment,
  }) async {
    try {
      await _apiClient.post(
        ApiConstants.ratingCreate(bookingId),
        data: {
          'score': score,
          'comment': comment,
        },
      );
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<List<Rating>>> getTechnicianRatings(String techId) async {
    try {
      final response =
          await _apiClient.get(ApiConstants.technicianRatings(techId));
      final list =
          (response.data as List).map((e) => Rating.fromJson(e)).toList();
      return ApiResult.success(list);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }
}

final ratingRepositoryProvider = Provider<RatingRepository>((ref) {
  return RatingRepository(ref.read(apiClientProvider));
});
