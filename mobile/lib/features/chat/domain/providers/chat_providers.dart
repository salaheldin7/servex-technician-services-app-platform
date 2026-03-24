import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.read(apiClientProvider));
});

final chatMessagesProvider =
    FutureProvider.family<List<ChatMessage>, String>((ref, bookingId) async {
  final repo = ref.read(chatRepositoryProvider);
  final result = await repo.getMessages(bookingId);
  if (result.isSuccess) return result.data!;
  throw Exception(result.error?.message ?? 'Failed to load messages');
});
