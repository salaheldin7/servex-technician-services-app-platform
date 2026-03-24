import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/settings_repository.dart';

String _roleHome(WidgetRef ref) {
  final role = ref.read(authStateProvider).user?.role;
  return role == 'technician' ? '/technician' : '/home';
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authStateProvider).user;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(_roleHome(ref));
                  }
                },
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 2),
                        ),
                        child: CircleAvatar(
                          radius: Responsive.value<double>(
                              context, mobile: 38, tablet: 50),
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.2),
                          child: Text(
                            user?.fullName.isNotEmpty == true
                                ? user!.fullName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: Responsive.value<double>(
                                  context, mobile: 30, tablet: 38),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.fullName ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.horizontalPadding(context),
              vertical: 16,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: Responsive.maxContentWidth(context)),
                  child: Column(
                    children: [
                      // Account section
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _SettingsTile(
                              icon: Icons.person_outlined,
                              iconColor: const Color(0xFF2563EB),
                              title: l10n.profile,
                              onTap: () => context.push('/edit-profile'),
                              isFirst: true,
                            ),
                            const Divider(height: 1, indent: 56),
                            _SettingsTile(
                              icon: Icons.language_outlined,
                              iconColor: const Color(0xFF059669),
                              title: l10n.language,
                              subtitle: l10n.isArabic
                                  ? 'العربية'
                                  : 'English',
                              onTap: () => _showLanguageDialog(
                                  context, ref),
                            ),
                            const Divider(height: 1, indent: 56),
                            _SettingsTile(
                              icon: Icons.location_on_outlined,
                              iconColor: const Color(0xFFEA580C),
                              title: l10n.translate('my_addresses'),
                              subtitle: l10n.translate('manage_addresses'),
                              onTap: () => context.push('/addresses'),
                            ),
                            const Divider(height: 1, indent: 56),
                            _SettingsTile(
                              icon: Icons.support_agent_outlined,
                              iconColor: const Color(0xFF8B5CF6),
                              title: l10n.support,
                              onTap: () => context.push('/support'),
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Danger zone
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _SettingsTile(
                              icon: Icons.delete_outline,
                              iconColor: AppTheme.errorColor,
                              title: l10n.deleteAccount,
                              titleColor: AppTheme.errorColor,
                              onTap: () => _showDeleteDialog(
                                  context, ref),
                              isFirst: true,
                            ),
                            const Divider(height: 1, indent: 56),
                            _SettingsTile(
                              icon: Icons.logout_rounded,
                              iconColor: Colors.grey,
                              title: l10n.logout,
                              onTap: () => ref
                                  .read(authStateProvider.notifier)
                                  .logout(),
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              onTap: () {
                Navigator.pop(ctx);
                ref
                    .read(settingsRepositoryProvider)
                    .updateLanguage('en');
              },
            ),
            ListTile(
              title: const Text('العربية'),
              onTap: () {
                Navigator.pop(ctx);
                ref
                    .read(settingsRepositoryProvider)
                    .updateLanguage('ar');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).deleteAccount),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(settingsRepositoryProvider)
                  .deleteAccount();
              ref.read(authStateProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor),
            child: Text(AppLocalizations.of(context).confirm),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.titleColor,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(16) : Radius.zero,
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: titleColor,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
