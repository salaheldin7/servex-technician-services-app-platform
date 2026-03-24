import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/providers/booking_providers.dart';
import '../../../home/domain/providers/home_providers.dart';
import '../../../addresses/data/address_repository.dart';
import '../../../addresses/domain/providers/address_providers.dart';
import '../../../auth/domain/providers/auth_provider.dart';

class CreateBookingScreen extends ConsumerStatefulWidget {
  final String categoryId;
  const CreateBookingScreen({super.key, required this.categoryId});
  @override
  ConsumerState<CreateBookingScreen> createState() =>
      _CreateBookingScreenState();
}

class _CreateBookingScreenState extends ConsumerState<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  double? _latitude;
  double? _longitude;
  String? _categoryName;
  String _addressText = '';
  UserAddress? _selectedAddress;
  bool _showAddressPicker = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryLoadDefaultAddress();
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  int _wordCount(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  void _tryLoadDefaultAddress() {
    final addrAsync = ref.read(defaultAddressProvider);
    addrAsync.whenData((addr) {
      if (addr != null && mounted && _selectedAddress == null) {
        _useSavedAddress(addr);
      }
    });
  }

  void _useSavedAddress(UserAddress addr) {
    setState(() {
      _selectedAddress = addr;
      _latitude = addr.latitude;
      _longitude = addr.longitude;
      _addressText = addr.displayAddress;
      _showAddressPicker = false;
    });
  }

  Widget _buildNoAddressCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
          child: const Icon(Icons.location_off_rounded, color: Colors.orange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text('No address set. Please add an address.',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[800])),
        ),
      ]),
    );
  }

  Widget _buildSelectedAddressCard(UserAddress addr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.successColor.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: AppTheme.successColor.withValues(alpha: 0.1),
          child: const Icon(Icons.location_on_rounded,
              color: AppTheme.successColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(addr.label,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                if (addr.isDefault) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Default',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ]),
              const SizedBox(height: 4),
              Text(addr.displayAddress,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const Icon(Icons.check_circle,
            color: AppTheme.successColor, size: 22),
      ]),
    );
  }

  Future<void> _findTechnician() async {
    if (_selectedAddress == null && (_latitude == null || _longitude == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)
                .translate('pick_location_on_map'))),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final countryId = _selectedAddress?.countryId;
    final govId = _selectedAddress?.governorateId;
    final cityId = _selectedAddress?.cityId;

    if (countryId == null || govId == null || cityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please select a saved address with country, governorate and city')),
      );
      return;
    }

    // Create booking with auto_assign — all online technicians in the city will receive the request
    await _submit(autoAssign: true);
  }

  Future<void> _submit({bool autoAssign = true}) async {
    if (_selectedAddress == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an address first')),
        );
      }
      return;
    }

    final booking =
        await ref.read(bookingActionProvider.notifier).createBooking(
              categoryId: widget.categoryId,
              description: _descController.text.trim(),
              latitude: _latitude!,
              longitude: _longitude!,
              address: _addressText.isNotEmpty ? _addressText : 'Manual',
              estimatedPrice: 0,
              paymentMethod: 'cash',
              countryId: _selectedAddress?.countryId,
              governorateId: _selectedAddress?.governorateId,
              cityId: _selectedAddress?.cityId,
              addressId: _selectedAddress?.id,
              streetName: _selectedAddress?.streetName,
              buildingName: _selectedAddress?.buildingName,
              buildingNumber: _selectedAddress?.buildingNumber,
              floor: _selectedAddress?.floor,
              apartment: _selectedAddress?.apartment,
              fullAddress: _selectedAddress?.displayAddress ?? _addressText,
              autoAssign: autoAssign,
            );
    if (booking != null && mounted) {
      ref.invalidate(bookingsListProvider);
      // Go to searching screen — user waits until a technician accepts
      context.go('/booking/search/${booking.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bookingState = ref.watch(bookingActionProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final lang = l10n.isArabic ? 'ar' : 'en';

    categoriesAsync.whenData((categories) {
      final cat =
          categories.where((c) => c.id == widget.categoryId).firstOrNull;
      if (cat != null && _categoryName == null) {
        _categoryName = cat.name(lang);
      }
    });

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    final role = ref.read(authStateProvider).user?.role;
                    context.go(role == 'technician' ? '/technician' : '/home');
                  }
                },
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                  _categoryName ?? l10n.bookNow,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)]),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: Responsive.pagePadding(context),
            sliver: SliverToBoxAdapter(
              child: ResponsiveCenter(
                maxWidth: Responsive.maxFormWidth(context),
                child: _buildLocationAndDescription(l10n, bookingState),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ LOCATION + DESCRIPTION STEP ============
  Widget _buildLocationAndDescription(
      AppLocalizations l10n, BookingState bookingState) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),

          // STEP 1: LOCATION
          Text('① ${l10n.translate('your_location')}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // Default address or "no address" prompt
          Consumer(builder: (context, ref, _) {
            final defaultAsync = ref.watch(defaultAddressProvider);
            return defaultAsync.when(
              loading: () => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => _buildNoAddressCard(l10n),
              data: (defaultAddr) {
                // Show the selected address or the default one
                final addr = _selectedAddress ?? defaultAddr;
                if (addr == null) return _buildNoAddressCard(l10n);
                // Auto-select default if nothing selected yet
                if (_selectedAddress == null && defaultAddr != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _useSavedAddress(defaultAddr);
                  });
                }
                return _buildSelectedAddressCard(addr);
              },
            );
          }),

          const SizedBox(height: 8),

          // Choose another / add new buttons
          Consumer(builder: (context, ref, _) {
            final addrAsync = ref.watch(addressesProvider);
            final addresses = addrAsync.value ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  if (addresses.length > 1 || _selectedAddress == null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            setState(() => _showAddressPicker = !_showAddressPicker),
                        icon: const Icon(Icons.swap_horiz, size: 16),
                        label: Text(l10n.translate('choose_another_address'),
                            style: const TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                      ),
                    ),
                  if (addresses.length > 1 || _selectedAddress == null)
                    const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await context.push('/addresses/add');
                        ref.invalidate(addressesProvider);
                        ref.invalidate(defaultAddressProvider);
                      },
                      icon: const Icon(Icons.add_location_alt, size: 16),
                      label: Text(l10n.translate('add_new_address'),
                          style: const TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                    ),
                  ),
                ]),

                // Address picker list
                if (_showAddressPicker && addresses.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.translate('select_address'),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ...addresses.map((addr) => _AddressSelectionTile(
                              address: addr,
                              isSelected: _selectedAddress?.id == addr.id,
                              onTap: () => _useSavedAddress(addr),
                            )),
                      ],
                    ),
                  ),
              ],
            );
          }),

          const SizedBox(height: 24),

          // STEP 2: DESCRIPTION
          Text('② ${l10n.translate('describe_your_problem')}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
              controller: _descController,
              maxLines: 5,
              textDirection: _descController.text.isNotEmpty &&
                      RegExp(r'[\u0600-\u06FF]').hasMatch(_descController.text)
                  ? TextDirection.rtl
                  : null,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                  hintText: l10n.translate('describe_problem_hint'),
                  alignLabelWithHint: true,
                  counterText: '${_wordCount(_descController.text)}/60 ${l10n.isArabic ? 'كلمة' : 'words'}'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l10n.translate('description_required');
                }
                if (_wordCount(v) > 60) {
                  return l10n.isArabic
                      ? 'الوصف يجب ألا يتجاوز 60 كلمة'
                      : 'Description must not exceed 60 words';
                }
                return null;
              }),

          const SizedBox(height: 32),

          if (bookingState.error != null)
            Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(bookingState.error!,
                    style: const TextStyle(color: AppTheme.errorColor),
                    textAlign: TextAlign.center)),

          // FIND TECHNICIAN BUTTON
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF3B82F6)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: (bookingState.isLoading || _selectedAddress == null)
                  ? null
                  : _findTechnician,
              icon: bookingState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.search_rounded),
              label: Text(l10n.translate('find_technician'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),

          const SizedBox(height: 16),

          // Info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15))),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(l10n.translate('booking_info_note'),
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey[700]))),
            ]),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

}

// ============ ADDRESS SELECTION TILE ============
class _AddressSelectionTile extends StatelessWidget {
  final UserAddress address;
  final bool isSelected;
  final VoidCallback onTap;

  const _AddressSelectionTile({
    required this.address,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(children: [
          Icon(
            isSelected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: isSelected ? AppTheme.primaryColor : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(address.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  if (address.isDefault) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Default',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ]),
                Text(address.displayAddress,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
