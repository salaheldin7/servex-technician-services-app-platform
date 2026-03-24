import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/notification_repository.dart';
import '../../domain/providers/notification_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notificationsAsync = ref.watch(notificationsProvider(1));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.translate('notifications')),
        actions: [
          TextButton(
            onPressed: () async {
              final repo = ref.read(notificationRepositoryProvider);
              await repo.markAllRead();
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadCountProvider);
            },
            child: Text(l10n.translate('mark_all_read')),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    l10n.translate('no_notifications'),
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _NotificationTile(
                notification: notif,
                onTap: () async {
                  if (!notif.isRead) {
                    final repo = ref.read(notificationRepositoryProvider);
                    await repo.markRead(notif.id);
                    ref.invalidate(notificationsProvider);
                    ref.invalidate(unreadCountProvider);
                  }
                  // Navigate based on notification type
                  if (mounted) _handleNotificationTap(notif);
                },
              );
            },
          );
        },
      ),
    );
  }

  void _handleNotificationTap(NotificationItem notif) {
    switch (notif.type) {
      case 'support_reply':
        final ticketId = notif.data['ticket_id'];
        if (ticketId != null) {
          context.push('/support/$ticketId');
        }
        break;
      case 'verification_approved':
        // Show approval message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your account has been verified! You can now go online.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        break;
      case 'verification_rejected':
        // Show rejection reason and navigate to re-apply
        if (mounted) {
          final reason = notif.data['reason'] ?? 'Your verification was rejected. Please re-submit your documents.';
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.cancel, color: Colors.red, size: 28),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Verification Rejected')),
                ],
              ),
              content: Text(reason),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/technician/verification');
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('Re-Apply', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
        break;
      case 'booking_request':
      case 'booking_accepted':
      case 'booking_completed':
        final bookingId = notif.data['booking_id'];
        if (bookingId != null) {
          context.push('/booking/$bookingId');
        }
        break;
      case 'verification_submitted':
        // Just acknowledge
        break;
      default:
        break;
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  IconData _getIcon() {
    switch (notification.type) {
      case 'verification_approved':
        return Icons.verified;
      case 'verification_rejected':
        return Icons.cancel;
      case 'verification_submitted':
        return Icons.send;
      case 'booking_request':
        return Icons.work;
      case 'booking_accepted':
        return Icons.check_circle;
      case 'booking_completed':
        return Icons.task_alt;
      case 'support_reply':
        return Icons.support_agent;
      case 'payment':
        return Icons.payment;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case 'verification_approved':
        return Colors.green;
      case 'verification_rejected':
        return Colors.red;
      case 'verification_submitted':
        return Colors.blue;
      case 'booking_request':
        return AppTheme.primaryColor;
      case 'booking_accepted':
        return Colors.green;
      case 'booking_completed':
        return Colors.blue;
      case 'support_reply':
        return Colors.orange;
      case 'payment':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeAgo = _formatTimeAgo(notification.createdAt);

    return Card(
      elevation: notification.isRead ? 0 : 1,
      color: notification.isRead ? null : AppTheme.primaryColor.withValues(alpha: 0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getIconColor().withValues(alpha: 0.15),
          child: Icon(_getIcon(), color: _getIconColor(), size: 22),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notification.body.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(notification.body, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 4),
            Text(timeAgo, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
