import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';

class NotificationItem {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'general',
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : {},
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository(this._apiClient);

  Future<ApiResult<Map<String, dynamic>>> getNotifications({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.notifications}?page=$page&page_size=$pageSize',
      );
      return ApiResult.success(response.data);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<int>> getUnreadCount() async {
    try {
      final response = await _apiClient.get(ApiConstants.notificationsUnreadCount);
      return ApiResult.success(response.data['count'] ?? 0);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<void>> markRead(String notifId) async {
    try {
      await _apiClient.put(ApiConstants.notificationMarkRead(notifId));
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<void>> markAllRead() async {
    try {
      await _apiClient.put(ApiConstants.notificationsReadAll);
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }
}
