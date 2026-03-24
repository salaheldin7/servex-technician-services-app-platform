import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../locations/domain/providers/location_providers.dart';
import '../../domain/providers/address_providers.dart';

class AddAddressScreen extends ConsumerStatefulWidget {
  const AddAddressScreen({super.key});

  @override
  ConsumerState<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends ConsumerState<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController(text: 'Home');
  final _streetController = TextEditingController();
  final _buildingNameController = TextEditingController();
  final _buildingNumberController = TextEditingController();
  final _floorController = TextEditingController();
  final _apartmentController = TextEditingController();
  final MapController _mapController = MapController();

  String? _selectedCountryId;
  String? _selectedGovernorateId;
  String? _selectedCityId;

  LatLng? _selectedLocation;
  bool _isDefault = false;
  bool _isLoading = false;
  bool _locating = false;

  @override
  void dispose() {
    _labelController.dispose();
    _streetController.dispose();
    _buildingNameController.dispose();
    _buildingNumberController.dispose();
    _floorController.dispose();
    _apartmentController.dispose();
    super.dispose();
  }

  Future<void> _autoLocate() async {
    setState(() => _locating = true);
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _selectedLocation = LatLng(pos.latitude, pos.longitude));
      _mapController.move(_selectedLocation!, 16);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = <String, dynamic>{
      'label': _labelController.text.trim(),
      'street_name': _streetController.text.trim(),
      'building_name': _buildingNameController.text.trim(),
      'building_number': _buildingNumberController.text.trim(),
      'floor': _floorController.text.trim(),
      'apartment': _apartmentController.text.trim(),
      'is_default': _isDefault,
    };

    if (_selectedCountryId != null) data['country_id'] = _selectedCountryId;
    if (_selectedGovernorateId != null) {
      data['governorate_id'] = _selectedGovernorateId;
    }
    if (_selectedCityId != null) data['city_id'] = _selectedCityId;
    if (_selectedLocation != null) {
      data['latitude'] = _selectedLocation!.latitude;
      data['longitude'] = _selectedLocation!.longitude;
    }

    final repo = ref.read(addressRepositoryProvider);
    final result = await repo.create(data);

    setState(() => _isLoading = false);

    if (result.isSuccess && mounted) {
      ref.invalidate(addressesProvider);
      ref.invalidate(defaultAddressProvider);
      context.pop(result.data);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(result.error?.message ?? 'Failed to save address')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final countriesAsync = ref.watch(countriesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.translate('add_address')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- ADDRESS DETAILS CARD ---
              _SectionCard(
                title: 'Address Details',
                icon: Icons.location_on_rounded,
                children: [
                  // Label
                  TextFormField(
                    controller: _labelController,
                    decoration: const InputDecoration(
                      labelText: 'Label (e.g. Home, Work)',
                      prefixIcon: Icon(Icons.label_outlined),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Label is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Country
                  countriesAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error loading countries',
                        style: TextStyle(color: Colors.red[700])),
                    data: (countries) => DropdownButtonFormField<String>(
                      initialValue: _selectedCountryId,
                      decoration: InputDecoration(
                        labelText: l10n.translate('country'),
                        prefixIcon: const Icon(Icons.public),
                      ),
                      items: countries
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(l10n.isArabic ? c.nameAr : c.nameEn),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() {
                        _selectedCountryId = v;
                        _selectedGovernorateId = null;
                        _selectedCityId = null;
                      }),
                      validator: (v) => v == null ? 'Country is required' : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Governorate
                  if (_selectedCountryId != null)
                    Consumer(builder: (context, ref, _) {
                      final govsAsync =
                          ref.watch(governoratesProvider(_selectedCountryId!));
                      return govsAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => const SizedBox.shrink(),
                        data: (govs) => DropdownButtonFormField<String>(
                          initialValue: _selectedGovernorateId,
                          decoration: InputDecoration(
                            labelText: l10n.translate('governorate'),
                            prefixIcon: const Icon(Icons.location_city),
                          ),
                          items: govs
                              .map((g) => DropdownMenuItem(
                                    value: g.id,
                                    child: Text(
                                        l10n.isArabic ? g.nameAr : g.nameEn),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() {
                            _selectedGovernorateId = v;
                            _selectedCityId = null;
                          }),
                        ),
                      );
                    }),
                  if (_selectedCountryId != null) const SizedBox(height: 16),

                  // City
                  if (_selectedGovernorateId != null)
                    Consumer(builder: (context, ref, _) {
                      final citiesAsync =
                          ref.watch(citiesProvider(_selectedGovernorateId!));
                      return citiesAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => const SizedBox.shrink(),
                        data: (cities) => DropdownButtonFormField<String>(
                          initialValue: _selectedCityId,
                          decoration: InputDecoration(
                            labelText: l10n.translate('city'),
                            prefixIcon: const Icon(Icons.apartment),
                          ),
                          items: cities
                              .map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(
                                        l10n.isArabic ? c.nameAr : c.nameEn),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCityId = v),
                        ),
                      );
                    }),
                  if (_selectedGovernorateId != null) const SizedBox(height: 16),

                  // Street
                  TextFormField(
                    controller: _streetController,
                    decoration: InputDecoration(
                      labelText: l10n.translate('street_name'),
                      prefixIcon: const Icon(Icons.add_road),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Street is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Building name + number side by side
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _buildingNameController,
                          decoration: InputDecoration(
                            labelText: l10n.translate('building_name'),
                            hintText: 'Optional',
                            prefixIcon: const Icon(Icons.business),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _buildingNumberController,
                          decoration: InputDecoration(
                            labelText: l10n.translate('building_number'),
                            prefixIcon: const Icon(Icons.pin),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Required'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Floor + Apartment side by side
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _floorController,
                          decoration: const InputDecoration(
                            labelText: 'Floor',
                            hintText: 'e.g. 3',
                            prefixIcon: Icon(Icons.layers_outlined),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _apartmentController,
                          decoration: const InputDecoration(
                            labelText: 'Apartment',
                            hintText: 'e.g. 5A',
                            prefixIcon: Icon(Icons.door_front_door_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // --- MAP CARD ---
              _SectionCard(
                title: 'Pin Location on Map',
                icon: Icons.map_rounded,
                children: [
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _selectedLocation ??
                                const LatLng(30.0444, 31.2357),
                            initialZoom: 14,
                            onTap: (tapPos, latlng) {
                              setState(() => _selectedLocation = latlng);
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            ),
                            if (_selectedLocation != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _selectedLocation!,
                                    child: const Icon(Icons.location_pin,
                                        color: Colors.red, size: 40),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        // Coordinates overlay
                        if (_selectedLocation != null)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.location_on,
                                      color: Colors.green[600], size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _locating ? null : _autoLocate,
                          icon: _locating
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : const Icon(Icons.my_location, size: 18),
                          label: Text(l10n.translate('auto_locate'),
                              style: const TextStyle(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (_selectedLocation != null) {
                              _mapController.move(_selectedLocation!, 16);
                            }
                          },
                          icon: const Icon(Icons.center_focus_strong,
                              size: 18),
                          label: const Text('Center Map',
                              style: TextStyle(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap on the map to set your exact location',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // --- DEFAULT TOGGLE ---
              _SectionCard(
                title: 'Preferences',
                icon: Icons.settings_rounded,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isDefault
                          ? AppTheme.primaryColor.withValues(alpha: 0.06)
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isDefault
                            ? AppTheme.primaryColor.withValues(alpha: 0.2)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: SwitchListTile(
                      value: _isDefault,
                      onChanged: (v) => setState(() => _isDefault = v),
                      title: Text(l10n.translate('set_as_default'),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500)),
                      subtitle: Text(
                        _isDefault
                            ? 'This will be your default address'
                            : 'Toggle to make this your default',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      secondary: Icon(
                        _isDefault ? Icons.star : Icons.star_border,
                        color: _isDefault
                            ? AppTheme.accentColor
                            : Colors.grey[400],
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Save button
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF3B82F6)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveAddress,
                  icon: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    l10n.translate('save_address'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable section card with title and icon header
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppTheme.primaryColor, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
