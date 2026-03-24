import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../locations/domain/models/location_models.dart';
import '../../../locations/domain/providers/location_providers.dart';
import '../../domain/providers/verification_providers.dart';

class LocationSelectorScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const LocationSelectorScreen({super.key, required this.onComplete});

  @override
  ConsumerState<LocationSelectorScreen> createState() =>
      _LocationSelectorScreenState();
}

class _LocationSelectorScreenState
    extends ConsumerState<LocationSelectorScreen> {
  Country? _selectedCountry;
  Governorate? _selectedGovernorate; // null means "All Governorates"
  City? _selectedCity; // null means "All Cities"

  Future<void> _submit() async {
    if (_selectedCountry == null) return;

    final location = <String, dynamic>{
      'country_id': _selectedCountry!.id,
    };

    if (_selectedGovernorate != null) {
      location['governorate_id'] = _selectedGovernorate!.id;
    }
    if (_selectedCity != null) {
      location['city_id'] = _selectedCity!.id;
    }

    final success = await ref
        .read(verificationFlowProvider.notifier)
        .addLocations([location]);

    if (success && mounted) {
      widget.onComplete();
    } else if (mounted) {
      final error = ref.read(verificationFlowProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to save location'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final flowState = ref.watch(verificationFlowProvider);
    final countriesAsync = ref.watch(countriesProvider);
    final isArabic = l10n.isArabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'منطقة الخدمة' : 'Service Area'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: AppTheme.primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isArabic
                                ? 'اختر المنطقة التي تعمل فيها. المحافظة والمدينة اختياريان — إذا لم تخترهما يعني كل المنطقة.'
                                : 'Select your service area. Governorate and city are optional — leaving them means all areas.',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Country selector
                  Text(
                    isArabic ? 'الدولة *' : 'Country *',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  countriesAsync.when(
                    data: (countries) => _DropdownCard<Country>(
                      value: _selectedCountry,
                      items: countries,
                      hint: isArabic ? 'اختر الدولة' : 'Select Country',
                      itemLabel: (c) => c.name(isArabic),
                      onChanged: (c) {
                        setState(() {
                          _selectedCountry = c;
                          _selectedGovernorate = null;
                          _selectedCity = null;
                        });
                      },
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  ),
                  const SizedBox(height: 20),

                  // Governorate selector (optional)
                  if (_selectedCountry != null) ...[
                    Text(
                      isArabic ? 'المحافظة (اختياري)' : 'Governorate (optional)',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Consumer(builder: (context, ref, _) {
                      final govsAsync = ref.watch(
                          governoratesProvider(_selectedCountry!.id));
                      return govsAsync.when(
                        data: (govs) => _DropdownCard<Governorate>(
                          value: _selectedGovernorate,
                          items: govs,
                          hint: isArabic ? 'الكل' : 'All Governorates',
                          itemLabel: (g) => g.name(isArabic),
                          onChanged: (g) {
                            setState(() {
                              _selectedGovernorate = g;
                              _selectedCity = null;
                            });
                          },
                          allowClear: true,
                          clearLabel: isArabic ? 'الكل' : 'All Governorates',
                        ),
                        loading: () => const Center(
                            child: CircularProgressIndicator()),
                        error: (e, _) => Text('Error: $e'),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],

                  // City selector (optional, only when governorate is chosen)
                  if (_selectedGovernorate != null) ...[
                    Text(
                      isArabic ? 'المدينة (اختياري)' : 'City (optional)',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Consumer(builder: (context, ref, _) {
                      final citiesAsync = ref.watch(
                          citiesProvider(_selectedGovernorate!.id));
                      return citiesAsync.when(
                        data: (cities) {
                          if (cities.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  isArabic
                                      ? 'لا توجد مدن — سيتم تطبيق المحافظة كاملة'
                                      : 'No cities — entire governorate applies',
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 13),
                                ),
                              ),
                            );
                          }
                          return _DropdownCard<City>(
                            value: _selectedCity,
                            items: cities,
                            hint: isArabic ? 'الكل' : 'All Cities',
                            itemLabel: (c) => c.name(isArabic),
                            onChanged: (c) =>
                                setState(() => _selectedCity = c),
                            allowClear: true,
                            clearLabel: isArabic ? 'الكل' : 'All Cities',
                          );
                        },
                        loading: () => const Center(
                            child: CircularProgressIndicator()),
                        error: (e, _) => Text('Error: $e'),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],

                  // Summary
                  if (_selectedCountry != null) ...[
                    const Divider(),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.successColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: AppTheme.successColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _buildSummaryText(isArabic),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Submit button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _selectedCountry == null || flowState.isLoading
                      ? null
                      : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: flowState.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isArabic ? 'حفظ منطقة الخدمة' : 'Save Service Area',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),

          if (flowState.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                flowState.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  String _buildSummaryText(bool isArabic) {
    final country = _selectedCountry!.name(isArabic);
    if (_selectedGovernorate == null) {
      return isArabic
          ? 'ستخدم في: $country (كل المحافظات والمدن)'
          : 'You will serve: $country (all governorates & cities)';
    }
    final gov = _selectedGovernorate!.name(isArabic);
    if (_selectedCity == null) {
      return isArabic
          ? 'ستخدم في: $country > $gov (كل المدن)'
          : 'You will serve: $country > $gov (all cities)';
    }
    final city = _selectedCity!.name(isArabic);
    return isArabic
        ? 'ستخدم في: $country > $gov > $city'
        : 'You will serve: $country > $gov > $city';
  }
}

class _DropdownCard<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String hint;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final bool allowClear;
  final String? clearLabel;

  const _DropdownCard({
    required this.value,
    required this.items,
    required this.hint,
    required this.itemLabel,
    required this.onChanged,
    this.allowClear = false,
    this.clearLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint),
          isExpanded: true,
          items: [
            if (allowClear)
              DropdownMenuItem<T>(
                value: null,
                child: Text(
                  clearLabel ?? hint,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ...items.map((item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemLabel(item)),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
