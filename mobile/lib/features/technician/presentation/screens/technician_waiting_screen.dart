import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/domain/providers/auth_provider.dart';

class TechnicianWaitingScreen extends ConsumerWidget {
  const TechnicianWaitingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: Responsive.pagePadding(context),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.maxFormWidth(context)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.hourglass_empty_rounded,
                    size: Responsive.value<double>(context, mobile: 100, tablet: 130),
                    color: AppTheme.accentColor,
                  ),
              const SizedBox(height: 32),
              Text(
                l10n.waitingApproval,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.waitingApprovalDesc,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(authStateProvider.notifier).logout();
                },
                icon: const Icon(Icons.logout_rounded),
                label: Text(l10n.logout),
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

