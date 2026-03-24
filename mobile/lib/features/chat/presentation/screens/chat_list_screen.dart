import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/main_scaffold.dart';
import '../../../home/domain/providers/home_providers.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final bookingsAsync = ref.watch(activeBookingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookings)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(activeBookingsProvider),
        child: bookingsAsync.when(
          data: (bookings) {
            if (bookings.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  const EmptyStateWidget(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'No active bookings',
                    subtitle: 'Your booking conversations will appear here',
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.go('/booking/${booking.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Status indicator
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _statusColor(booking.status)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _statusIcon(booking.status),
                              color: _statusColor(booking.status),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.categoryName ?? 'Booking',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (booking.technicianName != null)
                                  Text(
                                    booking.technicianName!,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _statusColor(booking.status)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    booking.status.toUpperCase(),
                                    style: TextStyle(
                                      color: _statusColor(booking.status),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Chat button
                          if (booking.technicianId != null)
                            IconButton(
                              icon: const Icon(Icons.chat_rounded),
                              color: AppTheme.primaryColor,
                              onPressed: () =>
                                  context.go('/chat/${booking.id}'),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const LoadingWidget(),
          error: (e, _) => ListView(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.25),
              ErrorDisplayWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(activeBookingsProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'searching':
        return const Color(0xFFF59E0B);
      case 'assigned':
      case 'driving':
        return const Color(0xFF2563EB);
      case 'arrived':
        return const Color(0xFF7C3AED);
      case 'active':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF6B7280);
    }
  }

  static IconData _statusIcon(String status) {
    switch (status) {
      case 'searching':
        return Icons.search_rounded;
      case 'assigned':
      case 'driving':
        return Icons.directions_car_rounded;
      case 'arrived':
        return Icons.place_rounded;
      case 'active':
        return Icons.build_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }
}
