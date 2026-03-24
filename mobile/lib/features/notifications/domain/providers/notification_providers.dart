import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.read(apiClientProvider));
});

/// Auto-refreshes every 3 seconds via keepAlive + timer invalidation
final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.read(notificationRepositoryProvider);
  final result = await repo.getUnreadCount();
  if (result.isSuccess) {
    // Schedule next refresh in 3 seconds
    final timer = Timer(const Duration(seconds: 3), () {
      ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);
    return result.data!;
  }
  return 0;
});

final notificationsProvider = FutureProvider.autoDispose
    .family<List<NotificationItem>, int>((ref, page) async {
  final repo = ref.read(notificationRepositoryProvider);
  final result = await repo.getNotifications(page: page);
  if (result.isSuccess) {
    // Auto-refresh every 5 seconds
    final timer = Timer(const Duration(seconds: 5), () {
      ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);
    final list = result.data!['notifications'] as List? ?? [];
    return list.map((e) => NotificationItem.fromJson(e)).toList();
  }
  return [];
});
