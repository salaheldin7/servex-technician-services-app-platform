import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/main_scaffold.dart';
import '../../../../core/network/websocket_client.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../notifications/domain/providers/notification_providers.dart';
import '../../domain/providers/home_providers.dart';
import '../../domain/models/home_models.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

bool _isCarService(String icon) {
  return const {'car_repair', 'electric_car', 'local_car_wash', 'tire_repair', 'air'}
      .contains(icon);
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  Position? _currentPosition;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  StreamSubscription? _wsSub;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _listenForBookingUpdates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _wsSub?.cancel();
    super.dispose();
  }

  void _listenForBookingUpdates() {
    final ws = ref.read(wsClientProvider);
    _wsSub = ws.messages.listen((msg) {
      final event = msg['event'] as String?;
      if (event == 'booking_accepted') {
        ref.invalidate(activeBookingsProvider);
        // Navigate customer to the accepted booking
        final data = msg['data'] as Map<String, dynamic>?;
        final bookingId = data?['booking_id']?.toString();
        if (bookingId != null && mounted) {
          context.go('/booking/$bookingId');
        }
      } else if (event == 'booking_created' ||
          event == 'booking_cancelled' ||
          event == 'job_completed' ||
          event == 'technician_arrived' ||
          event == 'job_started') {
        ref.invalidate(activeBookingsProvider);
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authStateProvider).user;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
          ref.invalidate(activeBookingsProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Gradient header
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.3),
                                    Colors.white.withValues(alpha: 0.1),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  user?.fullName.isNotEmpty == true
                                      ? user!.fullName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${l10n.translate('hello')}, ${user?.fullName.split(' ').first ?? ''}',
                                    style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.8),
                                        fontSize: 13),
                                  ),
                                  Text(
                                    l10n.appName,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20),
                                  ),
                                ],
                              ),
                            ),
                            // Language toggle
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: InkWell(
                                onTap: () => ref
                                    .read(localeProvider.notifier)
                                    .toggleLocale(),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.language,
                                          size: 16,
                                          color: Colors.white
                                              .withValues(alpha: 0.9)),
                                      const SizedBox(width: 4),
                                      Text(
                                        l10n.isArabic ? 'EN' : 'عربي',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Consumer(builder: (context, ref, _) {
                                final unreadAsync = ref.watch(unreadCountProvider);
                                final count = unreadAsync.value ?? 0;
                                return Stack(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.notifications_outlined,
                                          color: Colors.white, size: 20),
                                      onPressed: () => context.push('/notifications'),
                                      constraints: const BoxConstraints(
                                          minWidth: 40, minHeight: 40),
                                      padding: EdgeInsets.zero,
                                    ),
                                    if (count > 0)
                                      Positioned(
                                        right: 4,
                                        top: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          constraints: const BoxConstraints(minWidth: 16),
                                          child: Text(
                                            count > 9 ? '9+' : '$count',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Search bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: l10n.searchServices,
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: const Icon(Icons.search_rounded,
                                  color: AppTheme.primaryColor),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            onChanged: (value) {
                              setState(() => _searchQuery = value.trim().toLowerCase());
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Body content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _ActiveBookingsBanner(),
                  const SizedBox(height: 20),
                  categoriesAsync.when(
                    data: (categories) {
                      final allServices = categories
                          .where((c) => c.type == 'technician_role')
                          .toList();
                      
                      // Apply search filter
                      final filtered = _searchQuery.isEmpty
                          ? allServices
                          : allServices.where((c) {
                              final nameEn = c.name('en').toLowerCase();
                              final nameAr = c.name('ar').toLowerCase();
                              return nameEn.contains(_searchQuery) ||
                                  nameAr.contains(_searchQuery);
                            }).toList();

                      final homeServices = filtered
                          .where((c) => !_isCarService(c.icon ?? ''))
                          .toList();
                      final carServices = filtered
                          .where((c) => _isCarService(c.icon ?? ''))
                          .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (homeServices.isNotEmpty) ...[
                            Text(
                              l10n.homeServicesSection,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            _ServiceGrid(
                                categories: homeServices,
                                lang: l10n.isArabic ? 'ar' : 'en'),
                            const SizedBox(height: 24),
                          ],
                          if (carServices.isNotEmpty) ...[
                            Text(
                              l10n.carServices,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            _ServiceGrid(
                                categories: carServices,
                                lang: l10n.isArabic ? 'ar' : 'en'),
                          ],
                          if (homeServices.isEmpty && carServices.isEmpty && _searchQuery.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.search_off_rounded,
                                        size: 56, color: Colors.grey[400]),
                                    const SizedBox(height: 12),
                                    Text(
                                      l10n.translate('no_results_found'),
                                      style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                    loading: () => const LoadingWidget(),
                    error: (e, _) => ErrorDisplayWidget(
                      message: e.toString(),
                      onRetry: () => ref.invalidate(categoriesProvider),
                    ),
                  ),
                  // Nearby technicians section removed
                  if (false && _currentPosition != null) ...[
                    Text(
                      l10n.nearbyTechnicians,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _NearbyTechniciansSection(
                      lat: _currentPosition!.latitude,
                      lng: _currentPosition!.longitude,
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveBookingsBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(activeBookingsProvider);

    return bookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) return const SizedBox.shrink();

        return Column(
          children: bookings.map((booking) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _bannerGradient(booking.taskStatus),
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _bannerGradient(booking.taskStatus)
                        .first
                        .withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.go('/booking/${booking.id}'),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_bannerIcon(booking.taskStatus),
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.categoryName ?? 'Active Booking',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  booking.taskStatusDisplay,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  List<Color> _bannerGradient(String taskStatus) {
    switch (taskStatus) {
      case 'searching':
        return const [Color(0xFFF59E0B), Color(0xFFFBBF24)];
      case 'technician_coming':
        return const [Color(0xFF2563EB), Color(0xFF3B82F6)];
      case 'technician_working':
        return const [Color(0xFF7C3AED), Color(0xFF8B5CF6)];
      case 'technician_finished':
        return const [Color(0xFF059669), Color(0xFF10B981)];
      default:
        return const [Color(0xFF2563EB), Color(0xFF3B82F6)];
    }
  }

  IconData _bannerIcon(String taskStatus) {
    switch (taskStatus) {
      case 'searching':
        return Icons.search_rounded;
      case 'technician_coming':
        return Icons.directions_car_rounded;
      case 'technician_working':
        return Icons.build_rounded;
      case 'technician_finished':
        return Icons.check_circle_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }
}

class _ServiceGrid extends StatelessWidget {
  final List<Category> categories;
  final String lang;

  const _ServiceGrid({required this.categories, required this.lang});

  static const Map<String, _ServiceStyle> _styles = {
    'electrical_services':
        _ServiceStyle(Icons.electrical_services_rounded, Color(0xFFE8A317)),
    'plumbing': _ServiceStyle(Icons.plumbing_rounded, Color(0xFF2563EB)),
    'carpenter': _ServiceStyle(Icons.carpenter_rounded, Color(0xFF78350F)),
    'format_paint':
        _ServiceStyle(Icons.format_paint_rounded, Color(0xFF7C3AED)),
    'ac_unit': _ServiceStyle(Icons.ac_unit_rounded, Color(0xFF0891B2)),
    'cleaning_services':
        _ServiceStyle(Icons.cleaning_services_rounded, Color(0xFF059669)),
    'kitchen': _ServiceStyle(Icons.kitchen_rounded, Color(0xFFEA580C)),
    'security': _ServiceStyle(Icons.security_rounded, Color(0xFF1D4ED8)),
    'computer': _ServiceStyle(Icons.computer_rounded, Color(0xFF4F46E5)),
    'pest_control':
        _ServiceStyle(Icons.pest_control_rounded, Color(0xFFDC2626)),
    'yard': _ServiceStyle(Icons.yard_rounded, Color(0xFF65A30D)),
    'pool': _ServiceStyle(Icons.pool_rounded, Color(0xFF0D9488)),
    'lock': _ServiceStyle(Icons.lock_rounded, Color(0xFF475569)),
    'design_services':
        _ServiceStyle(Icons.design_services_rounded, Color(0xFFDB2777)),
    'handyman': _ServiceStyle(Icons.handyman_rounded, Color(0xFFC2410C)),
    'car_repair': _ServiceStyle(Icons.car_repair_rounded, Color(0xFF991B1B)),
    'electric_car':
        _ServiceStyle(Icons.electric_car_rounded, Color(0xFFB45309)),
    'local_car_wash':
        _ServiceStyle(Icons.local_car_wash_rounded, Color(0xFF0284C7)),
    'tire_repair': _ServiceStyle(Icons.tire_repair_rounded, Color(0xFF1F2937)),
    'air': _ServiceStyle(Icons.air_rounded, Color(0xFF0369A1)),
    'build': _ServiceStyle(Icons.build_rounded, Color(0xFF6D28D9)),
    'roofing': _ServiceStyle(Icons.roofing_rounded, Color(0xFF92400E)),
    'water_damage': _ServiceStyle(Icons.water_damage_rounded, Color(0xFF1E40AF)),
    'local_shipping': _ServiceStyle(Icons.local_shipping_rounded, Color(0xFF065F46)),
    'iron': _ServiceStyle(Icons.iron_rounded, Color(0xFF6B21A8)),
    'microwave': _ServiceStyle(Icons.microwave_rounded, Color(0xFFBE185D)),
    'satellite': _ServiceStyle(Icons.satellite_alt_rounded, Color(0xFF1E3A5F)),
    'camera_outdoor': _ServiceStyle(Icons.camera_outdoor_rounded, Color(0xFF334155)),
    'solar_power': _ServiceStyle(Icons.solar_power_rounded, Color(0xFFD97706)),
    'elevator': _ServiceStyle(Icons.elevator_rounded, Color(0xFF374151)),
    'grass': _ServiceStyle(Icons.grass_rounded, Color(0xFF16A34A)),
    'shower': _ServiceStyle(Icons.shower_rounded, Color(0xFF2563EB)),
    'window': _ServiceStyle(Icons.window_rounded, Color(0xFF0E7490)),
    'door_front': _ServiceStyle(Icons.door_front_door_rounded, Color(0xFF78350F)),
  };

  @override
  Widget build(BuildContext context) {
    final cols =
        Responsive.gridColumns(context, mobile: 3, tablet: 4, desktop: 5);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final style = _styles[cat.icon] ??
            const _ServiceStyle(
                Icons.miscellaneous_services_rounded, Color(0xFF6B7280));

        return InkWell(
          onTap: () => context.go('/booking/create/${cat.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: style.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: style.color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  style.icon,
                  color: Colors.white,
                  size: Responsive.iconSize(context, mobile: 32, tablet: 38),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    cat.name(lang),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ServiceStyle {
  final IconData icon;
  final Color color;
  const _ServiceStyle(this.icon, this.color);
}

class _NearbyTechniciansSection extends ConsumerWidget {
  final double lat;
  final double lng;

  const _NearbyTechniciansSection({required this.lat, required this.lng});

  void _showTechnicianDetail(BuildContext context, NearbyTechnician tech) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Text(
                tech.fullName.isNotEmpty ? tech.fullName[0] : '?',
                style: const TextStyle(
                    fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Text(tech.fullName,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, size: 18, color: Colors.amber),
                const SizedBox(width: 4),
                Text(tech.rating.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(width: 16),
                Icon(Icons.work_outline,
                    size: 18, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${tech.completedJobs} jobs',
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey[600])),
                const SizedBox(width: 16),
                Icon(Icons.location_on_outlined,
                    size: 18, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${(tech.distance / 1000).toStringAsFixed(1)} km',
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey[600])),
              ],
            ),
            if (tech.categories.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tech.categories
                    .map((c) => Chip(
                          label: Text(c,
                              style: const TextStyle(fontSize: 12)),
                          backgroundColor:
                              AppTheme.primaryColor.withValues(alpha: 0.08),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Navigate to booking with first category if available
                  if (tech.categories.isNotEmpty) {
                    context.push('/booking/create/all');
                  }
                },
                icon: const Icon(Icons.build_circle_outlined),
                label: const Text('Book a Service'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final techAsync =
        ref.watch(nearbyTechniciansProvider({'lat': lat, 'lng': lng}));

    return techAsync.when(
      data: (technicians) {
        if (technicians.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No nearby technicians found'),
          );
        }

        return SizedBox(
          height: Responsive.value<double>(context, mobile: 160, tablet: 180),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: technicians.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final tech = technicians[index];
              return GestureDetector(
                onTap: () => _showTechnicianDetail(context, tech),
                child: Card(
                child: Container(
                  width: Responsive.value<double>(
                      context, mobile: 140, tablet: 170),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor:
                            AppTheme.primaryColor.withValues(alpha: 0.1),
                        child: Text(
                          tech.fullName.isNotEmpty ? tech.fullName[0] : '?',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tech.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star,
                              size: 14, color: Colors.amber),
                          Text(' ${tech.rating.toStringAsFixed(1)}',
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      Text(
                        '${(tech.distance / 1000).toStringAsFixed(1)} km',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              );
            },
          ),
        );
      },
      loading: () => const LoadingWidget(),
      error: (e, _) => Text(e.toString()),
    );
  }
}
