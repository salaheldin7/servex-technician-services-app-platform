import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../home/domain/providers/home_providers.dart';

class TechnicianRegistrationScreen extends ConsumerStatefulWidget {
  const TechnicianRegistrationScreen({super.key});

  @override
  ConsumerState<TechnicianRegistrationScreen> createState() =>
      _TechnicianRegistrationScreenState();
}

class _TechnicianRegistrationScreenState
    extends ConsumerState<TechnicianRegistrationScreen> {
  final Set<String> _selectedCategories = {};
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.registerAsTechnician),
      ),
      body: SingleChildScrollView(
        padding: Responsive.pagePadding(context),
        child: ResponsiveCenter(
          maxWidth: Responsive.maxFormWidth(context),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.selectSpecialties,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            categoriesAsync.when(
              data: (categories) {
                final techRoles = categories
                    .where((c) => c.type == 'technician_role')
                    .toList();
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: techRoles.map((cat) {
                    final isSelected = _selectedCategories.contains(cat.id);
                    return FilterChip(
                      label: Text(
                        cat.name(l10n.isArabic ? 'ar' : 'en'),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategories.add(cat.id);
                          } else {
                            _selectedCategories.remove(cat.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text(e.toString()),
            ),
            const SizedBox(height: 24),

            // Document uploads
            Text(
              l10n.uploadDocuments,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            _DocumentUploadCard(
              label: l10n.idCard,
              icon: Icons.badge_outlined,
              onTap: () {
                // TODO: Pick ID card image
              },
            ),
            const SizedBox(height: 12),

            _DocumentUploadCard(
              label: l10n.certification,
              icon: Icons.card_membership_outlined,
              onTap: () {
                // TODO: Pick certification image
              },
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _selectedCategories.isNotEmpty && !_isSubmitting
                  ? () async {
                      setState(() => _isSubmitting = true);
                      // Submit registration
                      setState(() => _isSubmitting = false);
                      if (mounted) {
                        context.go('/technician-waiting');
                      }
                    }
                  : null,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l10n.registerAsTechnician),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _DocumentUploadCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DocumentUploadCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: AppTheme.primaryColor),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            const Icon(Icons.upload_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
