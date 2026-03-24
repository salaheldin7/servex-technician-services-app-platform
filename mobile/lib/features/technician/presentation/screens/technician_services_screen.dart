import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/verification_models.dart';
import '../../domain/providers/verification_providers.dart';

class TechnicianServicesScreen extends ConsumerWidget {
  const TechnicianServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.isArabic;
    final servicesAsync = ref.watch(techServicesProvider);
    final locationsAsync = ref.watch(techServiceLocationsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(isArabic ? 'خدماتي ومناطقي' : 'My Services & Areas'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Services Section ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic ? 'خدماتي' : 'My Services',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => context.push('/technician/add-services'),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(isArabic ? 'إضافة' : 'Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            servicesAsync.when(
              data: (services) {
                if (services.isEmpty) {
                  return _EmptyCard(
                    icon: Icons.handyman_rounded,
                    message:
                        isArabic ? 'لم تضف خدمات بعد' : 'No services added yet',
                  );
                }
                return Column(
                  children: services
                      .map((s) => _ServiceTile(service: s, isArabic: isArabic))
                      .toList(),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),

            const SizedBox(height: 24),

            // --- Locations Section ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic ? 'مناطق الخدمة' : 'Service Areas',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => context.push('/technician/add-locations'),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(isArabic ? 'إضافة' : 'Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            locationsAsync.when(
              data: (locations) {
                if (locations.isEmpty) {
                  return _EmptyCard(
                    icon: Icons.location_on_rounded,
                    message: isArabic
                        ? 'لم تحدد مناطق خدمة بعد'
                        : 'No service areas added yet',
                  );
                }
                return Column(
                  children: locations
                      .map(
                          (l) => _LocationTile(location: l, isArabic: isArabic))
                      .toList(),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceTile extends ConsumerWidget {
  final TechnicianService service;
  final bool isArabic;

  const _ServiceTile({required this.service, required this.isArabic});

  // Map backend icon name strings to Material Icons + colors
  static const Map<String, (IconData, Color)> _iconStyles = {
    'electrical_services': (Icons.electrical_services_rounded, Color(0xFFE8A317)),
    'plumbing': (Icons.plumbing_rounded, Color(0xFF2563EB)),
    'carpenter': (Icons.carpenter_rounded, Color(0xFF78350F)),
    'format_paint': (Icons.format_paint_rounded, Color(0xFF7C3AED)),
    'ac_unit': (Icons.ac_unit_rounded, Color(0xFF0891B2)),
    'cleaning_services': (Icons.cleaning_services_rounded, Color(0xFF059669)),
    'kitchen': (Icons.kitchen_rounded, Color(0xFFEA580C)),
    'security': (Icons.security_rounded, Color(0xFF1D4ED8)),
    'computer': (Icons.computer_rounded, Color(0xFF4F46E5)),
    'pest_control': (Icons.pest_control_rounded, Color(0xFFDC2626)),
    'yard': (Icons.yard_rounded, Color(0xFF65A30D)),
    'pool': (Icons.pool_rounded, Color(0xFF0D9488)),
    'lock': (Icons.lock_rounded, Color(0xFF475569)),
    'design_services': (Icons.design_services_rounded, Color(0xFFDB2777)),
    'handyman': (Icons.handyman_rounded, Color(0xFFC2410C)),
    'car_repair': (Icons.car_repair_rounded, Color(0xFF991B1B)),
    'build': (Icons.build_rounded, Color(0xFF6D28D9)),
    'roofing': (Icons.roofing_rounded, Color(0xFF92400E)),
    'water_damage': (Icons.water_damage_rounded, Color(0xFF1E40AF)),
    'local_shipping': (Icons.local_shipping_rounded, Color(0xFF065F46)),
    'iron': (Icons.iron_rounded, Color(0xFF6B21A8)),
    'microwave': (Icons.microwave_rounded, Color(0xFFBE185D)),
    'satellite': (Icons.satellite_alt_rounded, Color(0xFF1E3A5F)),
    'camera_outdoor': (Icons.camera_outdoor_rounded, Color(0xFF334155)),
    'solar_power': (Icons.solar_power_rounded, Color(0xFFD97706)),
    'shower': (Icons.shower_rounded, Color(0xFF2563EB)),
    'grass': (Icons.grass_rounded, Color(0xFF16A34A)),
    'window': (Icons.window_rounded, Color(0xFF0E7490)),
    'door_front': (Icons.door_front_door_rounded, Color(0xFF78350F)),
    'electric_car': (Icons.electric_car_rounded, Color(0xFF15803D)),
    'local_car_wash': (Icons.local_car_wash_rounded, Color(0xFF3B82F6)),
    'tire_repair': (Icons.tire_repair_rounded, Color(0xFF374151)),
    'elevator': (Icons.elevator_rounded, Color(0xFF3730A3)),
    'air': (Icons.air_rounded, Color(0xFF0284C7)),
  };

  (IconData, Color) _getIconStyle() {
    final style = _iconStyles[service.categoryIcon];
    return style ?? (Icons.handyman_rounded, const Color(0xFF6B7280));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (iconData, iconColor) = _getIconStyle();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(
              iconData,
              color: iconColor,
              size: 22,
            ),
          ),
        ),
        title: Text(
          service.categoryName(isArabic),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          isArabic
              ? '${service.hourlyRate.toStringAsFixed(0)} ج.م/ساعة'
              : '\$${service.hourlyRate.toStringAsFixed(0)}/hr',
          style: TextStyle(
              color: AppTheme.successColor,
              fontWeight: FontWeight.bold,
              fontSize: 13),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(isArabic ? 'حذف الخدمة' : 'Remove Service'),
                content: Text(isArabic
                    ? 'هل تريد حذف هذه الخدمة؟'
                    : 'Remove this service?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(isArabic ? 'حذف' : 'Remove',
                        style: const TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              ref
                  .read(verificationFlowProvider.notifier)
                  .removeService(service.id);
            }
          },
        ),
      ),
    );
  }
}

class _LocationTile extends ConsumerWidget {
  final ServiceLocation location;
  final bool isArabic;

  const _LocationTile({required this.location, required this.isArabic});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.location_on, color: AppTheme.primaryColor),
        title: Text(
          location.displayName(isArabic),
          style: const TextStyle(fontSize: 13),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(isArabic ? 'حذف المنطقة' : 'Remove Area'),
                content: Text(isArabic
                    ? 'هل تريد حذف هذه المنطقة؟'
                    : 'Remove this area?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(isArabic ? 'حذف' : 'Remove',
                        style: const TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              ref
                  .read(verificationFlowProvider.notifier)
                  .removeLocation(location.id);
            }
          },
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }
}
