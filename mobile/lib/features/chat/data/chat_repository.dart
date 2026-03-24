import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';

class ChatMessage {
  final String id;
  final String bookingId;
  final String senderId;
  final String senderRole;
  final String message;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.senderRole,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      bookingId: json['booking_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      senderRole: json['sender_role'] ?? '',
      message: json['message'] ?? json['content'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class ChatRepository {
  final ApiClient _apiClient;

  ChatRepository(this._apiClient);

  Future<ApiResult<List<ChatMessage>>> getMessages(String bookingId) async {
    try {
      final response =
          await _apiClient.get(ApiConstants.chatMessages(bookingId));
      final data = response.data;
      final List<dynamic> items;
      if (data is Map) {
        items = data['messages'] ?? [];
      } else if (data is List) {
        items = data;
      } else {
        items = [];
      }
      final list = items
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResult.success(list);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<ChatMessage>> sendMessage(
      String bookingId, String message) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.chatSend(bookingId),
        data: {'content': message, 'message': message},
      );
      return ApiResult.success(ChatMessage.fromJson(response.data));
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }
}
