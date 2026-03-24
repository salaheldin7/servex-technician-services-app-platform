import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';

class SupportTicket {
  final String id;
  final String userId;
  final String subject;
  final String description;
  final String priority;
  final String status;
  final String? assignedTo;
  final String? userName;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.subject,
    required this.description,
    required this.priority,
    required this.status,
    this.assignedTo,
    this.userName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      subject: json['subject'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'open',
      assignedTo: json['assigned_to'],
      userName: json['user_name'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class TicketMessage {
  final String id;
  final String ticketId;
  final String senderId;
  final bool isAdmin;
  final String content;
  final DateTime createdAt;

  TicketMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.isAdmin,
    required this.content,
    required this.createdAt,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] ?? '',
      ticketId: json['ticket_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      isAdmin: json['is_admin'] ?? false,
      content: json['content'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class SupportRepository {
  final ApiClient _apiClient;

  SupportRepository(this._apiClient);

  Future<ApiResult<List<SupportTicket>>> getTickets() async {
    try {
      final response = await _apiClient.get(ApiConstants.supportTickets);
      final data = response.data;
      final List items = data is Map ? (data['tickets'] ?? []) : (data is List ? data : []);
      final list = items
          .map((e) => SupportTicket.fromJson(e))
          .toList();
      return ApiResult.success(list);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<SupportTicket>> createTicket({
    required String subject,
    required String category,
    required String message,
  }) async {
    try {
      final description = '[$category] $message';
      final response = await _apiClient.post(
        ApiConstants.supportTickets,
        data: {
          'subject': subject,
          'description': description,
          'priority': 'medium',
        },
      );
      final ticket = SupportTicket.fromJson(response.data);
      // Add the initial message to the ticket thread
      try {
        await _apiClient.post(
          ApiConstants.supportTicketMessages(ticket.id),
          data: {'content': message},
        );
      } catch (_) {
        // Non-critical: ticket was created, message add failed
      }
      return ApiResult.success(ticket);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<SupportTicket>> getTicket(String id) async {
    try {
      final response =
          await _apiClient.get(ApiConstants.supportTicketById(id));
      return ApiResult.success(SupportTicket.fromJson(response.data));
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<List<TicketMessage>>> getMessages(String ticketId) async {
    try {
      final response =
          await _apiClient.get(ApiConstants.supportTicketMessages(ticketId));
      final data = response.data;
      final List items = data is Map ? (data['messages'] ?? []) : (data is List ? data : []);
      final list = items
          .map((e) => TicketMessage.fromJson(e))
          .toList();
      return ApiResult.success(list);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }

  Future<ApiResult<void>> addMessage(String ticketId, String message) async {
    try {
      await _apiClient.post(
        ApiConstants.supportTicketMessages(ticketId),
        data: {'content': message},
      );
      return ApiResult.success(null);
    } on DioException catch (e) {
      return ApiResult.failure(ApiError.fromDioException(e));
    }
  }
}

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(ref.read(apiClientProvider));
});

final supportTicketsProvider =
    FutureProvider<List<SupportTicket>>((ref) async {
  final repo = ref.read(supportRepositoryProvider);
  final result = await repo.getTickets();
  if (result.isSuccess) return result.data!;
  throw Exception(result.error?.message ?? 'Failed to load tickets');
});

final ticketDetailProvider =
    FutureProvider.family<SupportTicket, String>((ref, id) async {
  final repo = ref.read(supportRepositoryProvider);
  final result = await repo.getTicket(id);
  if (result.isSuccess) return result.data!;
  throw Exception(result.error?.message ?? 'Failed to load ticket');
});

final ticketMessagesProvider =
    FutureProvider.family<List<TicketMessage>, String>((ref, ticketId) async {
  final repo = ref.read(supportRepositoryProvider);
  final result = await repo.getMessages(ticketId);
  if (result.isSuccess) return result.data!;
  throw Exception(result.error?.message ?? 'Failed to load messages');
});
