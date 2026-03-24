import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/main_scaffold.dart';
import '../../domain/providers/booking_providers.dart';
import '../../../home/domain/models/home_models.dart';

class BookingsListScreen extends ConsumerWidget {
  const BookingsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final bookingsAsync = ref.watch(bookingsListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookings)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(bookingsListProvider),
        child: bookingsAsync.when(
          data: (bookings) {
            if (bookings.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.calendar_today_rounded,
                title: 'No bookings yet',
                subtitle: 'Your booking history will appear here',
              );
            }

            // Separate active and past bookings
            final active =
                bookings.where((b) => b.isActive).toList();
            final past =
                bookings.where((b) => !b.isActive).toList();

            return ListView(
              padding: Responsive.pagePadding(context),
              children: [
                if (active.isNotEmpty) ...[
                  _SectionHeader(
                    title: l10n.translate('active_bookings'),
                    count: active.length,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 8),
                  ...active.map((b) => _BookingCard(booking: b, isActive: true)),
                  const SizedBox(height: 24),
                ],
                if (past.isNotEmpty) ...[
                  _SectionHeader(
                    title: l10n.translate('past_bookings'),
                    count: past.length,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  ...past.map((b) => _BookingCard(booking: b, isActive: false)),
                ],
              ],
            );
          },
          loading: () => const LoadingWidget(),
          error: (e, _) => ErrorDisplayWidget(
            message: e.toString(),
            onRetry: () => ref.invalidate(bookingsListProvider),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  const _SectionHeader(
      {required this.title, required this.count, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count',
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isActive;
  const _BookingCard({required this.booking, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isActive
            ? Border.all(
                color: _taskStatusColor(booking.taskStatus)
                    .withValues(alpha: 0.3),
                width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: InkWell(
        onTap: () => context.go('/booking/${booking.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Service icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _taskStatusColor(booking.taskStatus)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _taskStatusIcon(booking.taskStatus),
                      color: _taskStatusColor(booking.taskStatus),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.categoryName ?? 'Service',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          booking.address,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '#${booking.code}',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      _StatusChip(
                        label: booking.taskStatusDisplay,
                        color: _taskStatusColor(booking.taskStatus),
                      ),
                    ],
                  ),
                ],
              ),

              // Extra info for active bookings
              if (isActive) ...[
                const Divider(height: 20),
                Row(
                  children: [
                    if (booking.technicianName != null) ...[
                      const Icon(Icons.person, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(booking.technicianName!,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[700])),
                      const Spacer(),
                    ],
                    Icon(Icons.access_time,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      _timeAgo(booking.createdAt),
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],

              // Price for past bookings
              if (!isActive && booking.finalPrice != null) ...[
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Icon(Icons.access_time,
                          size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(_formatDate(booking.createdAt),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500])),
                    ]),
                    Text(
                      '\$${booking.finalPrice!.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _taskStatusColor(String taskStatus) {
    switch (taskStatus) {
      case 'searching':
        return Colors.orange;
      case 'technician_coming':
        return const Color(0xFF2563EB);
      case 'technician_working':
        return const Color(0xFF7C3AED);
      case 'technician_finished':
        return const Color(0xFF059669);
      case 'task_closed':
        return Colors.grey;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _taskStatusIcon(String taskStatus) {
    switch (taskStatus) {
      case 'searching':
        return Icons.search_rounded;
      case 'technician_coming':
        return Icons.directions_car_rounded;
      case 'technician_working':
        return Icons.build_rounded;
      case 'technician_finished':
        return Icons.check_circle_rounded;
      case 'task_closed':
        return Icons.done_all_rounded;
      default:
        return Icons.work_rounded;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
