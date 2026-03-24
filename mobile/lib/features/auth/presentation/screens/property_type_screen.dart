import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/providers/auth_provider.dart';

class PropertyTypeScreen extends ConsumerStatefulWidget {
  const PropertyTypeScreen({super.key});

  @override
  ConsumerState<PropertyTypeScreen> createState() => _PropertyTypeScreenState();
}

class _PropertyTypeScreenState extends ConsumerState<PropertyTypeScreen> {
  String? _selectedType;

  static const List<_PropertyTypeItem> _propertyTypes = [
    _PropertyTypeItem('personal_residential', Icons.home_rounded, Color(0xFF2563EB)),
    _PropertyTypeItem('residential_compounds', Icons.apartment_rounded, Color(0xFF059669)),
    _PropertyTypeItem('offices', Icons.business_rounded, Color(0xFF7C3AED)),
    _PropertyTypeItem('banks', Icons.account_balance_rounded, Color(0xFFD97706)),
    _PropertyTypeItem('government_buildings', Icons.domain_rounded, Color(0xFF0891B2)),
    _PropertyTypeItem('schools_universities', Icons.school_rounded, Color(0xFFDB2777)),
    _PropertyTypeItem('hospitals_clinics', Icons.local_hospital_rounded, Color(0xFFDC2626)),
    _PropertyTypeItem('hotels', Icons.hotel_rounded, Color(0xFF9333EA)),
    _PropertyTypeItem('retail_shops', Icons.store_rounded, Color(0xFFEA580C)),
    _PropertyTypeItem('factories_warehouses', Icons.factory_rounded, Color(0xFF4B5563)),
    _PropertyTypeItem('restaurants_cafes', Icons.restaurant_rounded, Color(0xFFCA8A04)),
    _PropertyTypeItem('community_centers', Icons.groups_rounded, Color(0xFF0D9488)),
    _PropertyTypeItem('religious_buildings', Icons.mosque_rounded, Color(0xFF6D28D9)),
    _PropertyTypeItem('car_owners_garages', Icons.directions_car_rounded, Color(0xFF1D4ED8)),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('select_property_type')),
        actions: [
          TextButton(
            onPressed: () {
              final role = ref.read(authStateProvider).user?.role;
              context.go(role == 'technician' ? '/technician' : '/home');
            },
            child: Text(l10n.translate('skip')),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: Responsive.pagePadding(context),
        child: ResponsiveCenter(
          maxWidth: Responsive.maxContentWidth(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.translate('your_property_type'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.translate('select_property_type_desc'),
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: Responsive.gridColumns(context, mobile: 2, tablet: 3, desktop: 4),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                ),
                itemCount: _propertyTypes.length,
                itemBuilder: (context, index) {
                  final item = _propertyTypes[index];
                  final isSelected = _selectedType == item.key;
                  return InkWell(
                    onTap: () => setState(() => _selectedType = item.key),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected ? item.color : item.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? item.color : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: item.color.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.icon,
                            size: Responsive.iconSize(context, mobile: 32, tablet: 40),
                            color: isSelected ? Colors.white : item.color,
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              l10n.translate(item.key),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : item.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _selectedType != null
                    ? () {
                        // Save property type to user profile
                        final user = ref.read(authStateProvider).user;
                        if (user != null) {
                          ref.read(authStateProvider.notifier).updateUser(
                                user.copyWith(propertyType: _selectedType),
                              );
                        }
                        context.go(
                          ref.read(authStateProvider).user?.role == 'technician'
                              ? '/technician'
                              : '/home',
                        );
                      }
                    : null,
                child: Text(l10n.confirm),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertyTypeItem {
  final String key;
  final IconData icon;
  final Color color;
  const _PropertyTypeItem(this.key, this.icon, this.color);
}
