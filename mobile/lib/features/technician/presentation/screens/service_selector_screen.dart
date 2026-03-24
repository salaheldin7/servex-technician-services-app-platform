import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/domain/providers/home_providers.dart';
import '../../domain/providers/verification_providers.dart';

class ServiceSelectorScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const ServiceSelectorScreen({super.key, required this.onComplete});

  @override
  ConsumerState<ServiceSelectorScreen> createState() =>
      _ServiceSelectorScreenState();
}

class _ServiceSelectorScreenState
    extends ConsumerState<ServiceSelectorScreen> {
  // Map of categoryId -> hourlyRate
  final Map<String, double> _selected = {};
  final Map<String, TextEditingController> _rateControllers = {};

  @override
  void dispose() {
    for (final c in _rateControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _toggleCategory(String id) {
    setState(() {
      if (_selected.containsKey(id)) {
        _selected.remove(id);
        _rateControllers[id]?.dispose();
        _rateControllers.remove(id);
      } else {
        _selected[id] = 0;
        _rateControllers[id] = TextEditingController(text: '0');
      }
    });
  }

  void _updateRate(String id, String value) {
    final rate = double.tryParse(value) ?? 0;
    _selected[id] = rate;
  }

  Future<void> _submit() async {
    if (_selected.isEmpty) return;

    final services = _selected.entries
        .map((e) => {
              'category_id': e.key,
              'hourly_rate': e.value,
            })
        .toList();

    final success = await ref
        .read(verificationFlowProvider.notifier)
        .addServices(services);

    if (success && mounted) {
      widget.onComplete();
    } else if (mounted) {
      final error = ref.read(verificationFlowProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to save services'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Icon + color mapping keyed by the category 'icon' field
  static const Map<String, _ServiceIconStyle> _iconStyles = {
    'electrical_services': _ServiceIconStyle(Icons.electrical_services_rounded, Color(0xFFE8A317)),
    'plumbing': _ServiceIconStyle(Icons.plumbing_rounded, Color(0xFF2563EB)),
    'carpenter': _ServiceIconStyle(Icons.carpenter_rounded, Color(0xFF78350F)),
    'format_paint': _ServiceIconStyle(Icons.format_paint_rounded, Color(0xFF7C3AED)),
    'ac_unit': _ServiceIconStyle(Icons.ac_unit_rounded, Color(0xFF0891B2)),
    'cleaning_services': _ServiceIconStyle(Icons.cleaning_services_rounded, Color(0xFF059669)),
    'kitchen': _ServiceIconStyle(Icons.kitchen_rounded, Color(0xFFEA580C)),
    'security': _ServiceIconStyle(Icons.security_rounded, Color(0xFF1D4ED8)),
    'computer': _ServiceIconStyle(Icons.computer_rounded, Color(0xFF4F46E5)),
    'pest_control': _ServiceIconStyle(Icons.pest_control_rounded, Color(0xFFDC2626)),
    'yard': _ServiceIconStyle(Icons.yard_rounded, Color(0xFF65A30D)),
    'pool': _ServiceIconStyle(Icons.pool_rounded, Color(0xFF0D9488)),
    'lock': _ServiceIconStyle(Icons.lock_rounded, Color(0xFF475569)),
    'design_services': _ServiceIconStyle(Icons.design_services_rounded, Color(0xFFDB2777)),
    'handyman': _ServiceIconStyle(Icons.handyman_rounded, Color(0xFFC2410C)),
    'car_repair': _ServiceIconStyle(Icons.car_repair_rounded, Color(0xFF991B1B)),
    'build': _ServiceIconStyle(Icons.build_rounded, Color(0xFF6D28D9)),
    'roofing': _ServiceIconStyle(Icons.roofing_rounded, Color(0xFF92400E)),
    'water_damage': _ServiceIconStyle(Icons.water_damage_rounded, Color(0xFF1E40AF)),
    'local_shipping': _ServiceIconStyle(Icons.local_shipping_rounded, Color(0xFF065F46)),
    'iron': _ServiceIconStyle(Icons.iron_rounded, Color(0xFF6B21A8)),
    'microwave': _ServiceIconStyle(Icons.microwave_rounded, Color(0xFFBE185D)),
    'satellite': _ServiceIconStyle(Icons.satellite_alt_rounded, Color(0xFF1E3A5F)),
    'camera_outdoor': _ServiceIconStyle(Icons.camera_outdoor_rounded, Color(0xFF334155)),
    'solar_power': _ServiceIconStyle(Icons.solar_power_rounded, Color(0xFFD97706)),
    'shower': _ServiceIconStyle(Icons.shower_rounded, Color(0xFF2563EB)),
    'grass': _ServiceIconStyle(Icons.grass_rounded, Color(0xFF16A34A)),
    'window': _ServiceIconStyle(Icons.window_rounded, Color(0xFF0E7490)),
    'door_front': _ServiceIconStyle(Icons.door_front_door_rounded, Color(0xFF78350F)),
    'electric_car': _ServiceIconStyle(Icons.electric_car_rounded, Color(0xFF15803D)),
    'local_car_wash': _ServiceIconStyle(Icons.local_car_wash_rounded, Color(0xFF3B82F6)),
    'tire_repair': _ServiceIconStyle(Icons.tire_repair_rounded, Color(0xFF374151)),
    'elevator': _ServiceIconStyle(Icons.elevator_rounded, Color(0xFF3730A3)),
    'air': _ServiceIconStyle(Icons.air_rounded, Color(0xFF0284C7)),
  };

  _ServiceIconStyle _getStyle(String? icon) {
    if (icon != null && _iconStyles.containsKey(icon)) {
      return _iconStyles[icon]!;
    }
    return const _ServiceIconStyle(Icons.handyman_rounded, Color(0xFF6B7280));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final flowState = ref.watch(verificationFlowProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final isArabic = l10n.isArabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'اختر خدماتك' : 'Select Your Services'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Info
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.handyman_rounded,
                    color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isArabic
                        ? 'اختر الخدمات التي تريد تقديمها وحدد أجرك بالساعة لكل خدمة'
                        : 'Select the services you want to offer and set your hourly rate for each',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Category list
          Expanded(
            child: categoriesAsync.when(
              data: (allCategories) {
                final categories = allCategories
                    .where((c) => c.type == 'technician_role')
                    .toList();
                if (categories.isEmpty) {
                  return Center(
                    child: Text(isArabic ? 'لا توجد خدمات' : 'No services available'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = _selected.containsKey(cat.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                          width: isSelected ? 2 : 0,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _toggleCategory(cat.id),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: _getStyle(cat.icon).color
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        _getStyle(cat.icon).icon,
                                        color: _getStyle(cat.icon).color,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      isArabic
                                          ? cat.nameAr
                                          : cat.nameEn,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (_) => _toggleCategory(cat.id),
                                    activeColor: AppTheme.primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                              // Hourly rate input
                              if (isSelected) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const SizedBox(width: 56),
                                    Expanded(
                                      child: TextField(
                                        controller: _rateControllers[cat.id],
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 10),
                                          labelText: isArabic
                                              ? 'الأجر بالساعة'
                                              : 'Hourly Rate',
                                          suffixText: isArabic ? 'ج.م/ساعة' : '/hr',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        onChanged: (v) =>
                                            _updateRate(cat.id, v),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
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
                  onPressed:
                      _selected.isEmpty || flowState.isLoading ? null : _submit,
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
                          isArabic
                              ? 'حفظ الخدمات (${_selected.length})'
                              : 'Save Services (${_selected.length})',
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
}

class _ServiceIconStyle {
  final IconData icon;
  final Color color;
  const _ServiceIconStyle(this.icon, this.color);
}
