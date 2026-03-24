import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/network/websocket_client.dart';
import '../../../../core/widgets/main_scaffold.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../booking/domain/providers/booking_providers.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const TrackingScreen({super.key, required this.bookingId});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  GoogleMapController? _mapController;
  LatLng _technicianLocation = const LatLng(0, 0);
  StreamSubscription? _locationSub;
  StreamSubscription? _statusSub;
  String _currentStatus = '';

  @override
  void initState() {
    super.initState();
    _listenForLocationUpdates();
    _listenForStatusUpdates();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _statusSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _listenForLocationUpdates() {
    final ws = ref.read(wsClientProvider);
    _locationSub = ws.on('technician_location_update').listen((data) {
      final eventData = data['data'] ?? data;
      if (eventData['booking_id'] == widget.bookingId) {
        final lat = (eventData['latitude'] as num?)?.toDouble() ?? 0;
        final lng = (eventData['longitude'] as num?)?.toDouble() ?? 0;
        setState(() {
          _technicianLocation = LatLng(lat, lng);
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_technicianLocation),
        );
      }
    });
  }

  void _listenForStatusUpdates() {
    final ws = ref.read(wsClientProvider);
    _statusSub = ws.messages.listen((msg) {
      final event = msg['event'] as String?;
      final data = msg['data'] ?? msg;
      final bookingId = data['booking_id']?.toString();
      if (bookingId != widget.bookingId) return;

      if (event == 'booking_status_update' ||
          event == 'booking_accepted' ||
          event == 'technician_arrived' ||
          event == 'job_started' ||
          event == 'job_completed' ||
          event == 'booking_cancelled') {
        final newStatus = data['status']?.toString();
        if (newStatus != null) {
          setState(() => _currentStatus = newStatus);
        }
        ref.invalidate(bookingDetailProvider(widget.bookingId));

        // Navigate away on terminal states
        if (mounted) {
          if (newStatus == 'completed') {
            context.go('/receipt/${widget.bookingId}');
          } else if (newStatus == 'cancelled') {
            context.go('/');
          }
        }
      }
    });
  }

  String _getStatusMessage(String status, AppLocalizations l10n) {
    switch (status) {
      case 'assigned':
      case 'driving':
        return l10n.technicianOnWay;
      case 'arrived':
        return l10n.technicianArrived;
      case 'active':
        return l10n.jobInProgress;
      case 'completed':
        return l10n.jobCompleted;
      default:
        return status;
    }
  }

  void _openGoogleMapsNavigation(double lat, double lng) async {
    final androidUri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final iosUri = Uri.parse(
        'comgooglemaps://?daddr=$lat,$lng&directionsmode=driving');
    final webUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    if (await canLaunchUrl(androidUri)) {
      await launchUrl(androidUri);
    } else if (await canLaunchUrl(iosUri)) {
      await launchUrl(iosUri);
    } else {
      await launchUrl(webUri, mode: LaunchMode.inAppBrowserView);
    }
  }

  void _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bookingAsync = ref.watch(bookingDetailProvider(widget.bookingId));
    final user = ref.watch(authStateProvider).user;
    final isTechnician = user?.role == 'technician';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.tracking),
      ),
      body: bookingAsync.when(
        data: (booking) {
          final status = _currentStatus.isNotEmpty ? _currentStatus : booking.status;
          final bookingLocation = LatLng(booking.latitude, booking.longitude);

          return Stack(
            children: [
              // Map
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: bookingLocation,
                  zoom: 15,
                ),
                onMapCreated: (controller) => _mapController = controller,
                markers: {
                  // Customer location
                  Marker(
                    markerId: const MarkerId('customer'),
                    position: bookingLocation,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueBlue),
                    infoWindow: const InfoWindow(title: 'Service Location'),
                  ),
                  // Technician location
                  if (_technicianLocation.latitude != 0)
                    Marker(
                      markerId: const MarkerId('technician'),
                      position: _technicianLocation,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueGreen),
                      infoWindow: InfoWindow(
                          title: booking.technicianName ?? 'Technician'),
                    ),
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),

              // Navigate button for technician (floating)
              if (isTechnician &&
                  ['assigned', 'driving'].contains(status))
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton.extended(
                    onPressed: () => _openGoogleMapsNavigation(
                        booking.latitude, booking.longitude),
                    icon: const Icon(Icons.navigation_rounded),
                    label: const Text('Navigate'),
                    backgroundColor: const Color(0xFF2563EB),
                  ),
                ),

              // Status bar at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: Responsive.pagePadding(context),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status progress
                      _StatusProgress(status: status),
                      const SizedBox(height: 16),

                      // Status message
                      Text(
                        _getStatusMessage(status, l10n),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      // Technician / Customer info
                      if (!isTechnician && booking.technicianName != null)
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              child: Text(booking.technicianName![0]),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(booking.technicianName!,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  if (booking.technicianRating != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.star,
                                            size: 14, color: Colors.amber),
                                        Text(
                                            ' ${booking.technicianRating!.toStringAsFixed(1)}'),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_outline),
                              onPressed: () =>
                                  context.go('/chat/${widget.bookingId}'),
                            ),
                            if (booking.technicianPhone != null)
                              IconButton(
                                icon: const Icon(Icons.phone_outlined),
                                onPressed: () =>
                                    _callPhone(booking.technicianPhone!),
                              ),
                          ],
                        ),

                      if (isTechnician && booking.customerName != null)
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              child: Text(booking.customerName![0]),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(booking.customerName!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_outline),
                              onPressed: () =>
                                  context.go('/chat/${widget.bookingId}'),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorDisplayWidget(message: e.toString()),
      ),
    );
  }
}

class _StatusProgress extends StatelessWidget {
  final String status;

  const _StatusProgress({required this.status});

  int get _stepIndex {
    switch (status) {
      case 'assigned':
      case 'driving':
        return 1;
      case 'arrived':
        return 2;
      case 'active':
        return 3;
      case 'completed':
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = ['Searching', 'On Way', 'Arrived', 'In Progress', 'Done'];

    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index <= _stepIndex;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: isActive ? AppTheme.primaryColor : Colors.grey[300],
                      ),
                    ),
                  Container(
                    width: Responsive.value<double>(context, mobile: 20, tablet: 24),
                    height: Responsive.value<double>(context, mobile: 20, tablet: 24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? AppTheme.primaryColor : Colors.grey[300],
                    ),
                    child: isActive
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: index < _stepIndex
                            ? AppTheme.primaryColor
                            : Colors.grey[300],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                steps[index],
                style: TextStyle(
                  fontSize: 9,
                  color: isActive ? AppTheme.primaryColor : Colors.grey,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
