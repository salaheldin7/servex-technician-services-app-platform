import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/main_scaffold.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/support_repository.dart';

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ticketsAsync = ref.watch(supportTicketsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              final role = ref.read(authStateProvider).user?.role;
              context.go(role == 'technician' ? '/technician/settings' : '/settings');
            }
          },
        ),
        title: Text(l10n.support),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/support/create'),
        icon: const Icon(Icons.add),
        label: Text(l10n.createTicket),
      ),
      body: ticketsAsync.when(
        data: (tickets) {
          if (tickets.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.support_agent_outlined,
              title: 'No tickets yet',
              subtitle: 'Create a support ticket if you need help',
              action: ElevatedButton(
                onPressed: () => context.push('/support/create'),
                child: Text(l10n.createTicket),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(supportTicketsProvider),
            child: ListView.separated(
              padding: Responsive.pagePadding(context),
              itemCount: tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _statusColor(ticket.status).withValues(alpha: 0.1),
                      child: Icon(
                        _statusIcon(ticket.status),
                        color: _statusColor(ticket.status),
                      ),
                    ),
                    title: Text(
                      ticket.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${ticket.priority} • ${ticket.status}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    trailing: Text(
                      '${ticket.createdAt.day}/${ticket.createdAt.month}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    onTap: () => context.push('/support/${ticket.id}'),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorDisplayWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(supportTicketsProvider),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'closed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'open':
        return Icons.fiber_new_rounded;
      case 'in_progress':
        return Icons.pending_rounded;
      case 'closed':
        return Icons.check_circle_rounded;
      default:
        return Icons.help_outline;
    }
  }
}
