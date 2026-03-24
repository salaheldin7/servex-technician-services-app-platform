import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/main_scaffold.dart';
import '../../../../core/network/websocket_client.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/providers/booking_providers.dart';
import '../../../home/domain/models/home_models.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingDetailScreen> createState() =>
      _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  StreamSubscription? _statusSub;
  String? _liveStatus;
  String? _liveTaskStatus;
  Timer? _jobTimer;
  Duration _jobDuration = Duration.zero;
  DateTime? _jobStartedAt;

  @override
  void initState() {
    super.initState();
    _listenForStatusUpdates();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _jobTimer?.cancel();
    super.dispose();
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
          event == 'booking_cancelled' ||
          event == 'no_technician_found') {
        final newStatus = data['status']?.toString();
        final newTaskStatus = data['task_status']?.toString();
        if (newStatus != null) {
          setState(() {
            _liveStatus = newStatus;
            if (newTaskStatus != null) _liveTaskStatus = newTaskStatus;
          });
        }
        // Refresh booking from API for full data
        ref.invalidate(bookingDetailProvider(widget.bookingId));

        // Auto-start timer when job starts
        if (newStatus == 'active') {
          _startTimer();
        }
        if (newStatus == 'completed' || newStatus == 'cancelled') {
          _jobTimer?.cancel();
        }

        // Navigate to receipt on completion
        if (newStatus == 'completed' && mounted) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) context.go('/receipt/${widget.bookingId}');
          });
        }

        // Auto-navigate to chat when accepted
        if (event == 'booking_accepted' && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Booking accepted! Chat is now available.'),
              action: SnackBarAction(
                label: 'Open Chat',
                onPressed: () => context.go('/chat/${widget.bookingId}'),
              ),
            ),
          );
        }

        // No technician found notification
        if (event == 'no_technician_found' && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No technicians available right now. Please try again later.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    });
  }

  void _startTimer() {
    _jobTimer?.cancel();
    _jobStartedAt ??= DateTime.now();
    _jobTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _jobDuration = DateTime.now().difference(_jobStartedAt!);
        });
      }
    });
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _handleArrive() async {
    final success = await ref
        .read(bookingActionProvider.notifier)
        .arriveAtBooking(widget.bookingId);
    if (success && mounted) {
      ref.invalidate(bookingDetailProvider(widget.bookingId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marked as arrived!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to mark arrived')),
      );
    }
  }

  Future<void> _handleVerifyAndStart(Booking booking) async {
    final codeController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Arrival Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ask the customer for the 4-digit verification code.'),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: const InputDecoration(
                hintText: '0000',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verify & Start Job'),
          ),
        ],
      ),
    );

    if (confirmed != true || codeController.text.trim().length != 4) return;

    // Get current position for GPS verification
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition();
    } catch (_) {}

    final verified = await ref
        .read(bookingActionProvider.notifier)
        .verifyArrival(widget.bookingId,
            code: codeController.text.trim(),
            lat: pos?.latitude ?? booking.latitude,
            lng: pos?.longitude ?? booking.longitude);

    if (!verified) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification failed. Wrong code or too far from location.')),
        );
      }
      return;
    }

    // Now start the job
    final started = await ref
        .read(bookingActionProvider.notifier)
        .startJob(widget.bookingId);
    if (started && mounted) {
      _startTimer();
      ref.invalidate(bookingDetailProvider(widget.bookingId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job started! Timer is running.')),
      );
    }
  }

  Future<void> _handleCompleteJob() async {
    // Auto-calculate price based on duration
    final durationMinutes = _jobDuration.inMinutes;
    
    // Fetch booking to get estimated price (used as hourly rate)
    final booking = ref.read(bookingDetailProvider(widget.bookingId)).value;
    final hourlyRate = booking?.estimatedPrice ?? 0;
    
    double autoCalculatedPrice;
    if (durationMinutes <= 60) {
      autoCalculatedPrice = hourlyRate; // Minimum 1 hour
    } else {
      autoCalculatedPrice = hourlyRate * durationMinutes / 60.0;
    }
    // Round to 2 decimals
    autoCalculatedPrice = (autoCalculatedPrice * 100).roundToDouble() / 100;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Job'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.timer_rounded, color: Color(0xFF059669), size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Duration: ${_formatDuration(_jobDuration)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hourly Rate: \$${hourlyRate.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Price:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(
                    '\$${autoCalculatedPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Price is automatically calculated based on service duration.',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Send 0 to let backend auto-calculate (more accurate server-side timing)
    final success = await ref
        .read(bookingActionProvider.notifier)
        .completeJob(widget.bookingId, finalPrice: 0);

    if (success && mounted) {
      _jobTimer?.cancel();
      ref.invalidate(bookingDetailProvider(widget.bookingId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job completed!')),
      );
    }
  }

  void _openGoogleMapsNavigation(double lat, double lng) async {
    // Android: Google Maps navigation intent
    final androidUri = Uri.parse(
        'google.navigation:q=$lat,$lng&mode=d');
    // iOS: Google Maps app deep link
    final iosUri = Uri.parse(
        'comgooglemaps://?daddr=$lat,$lng&directionsmode=driving');
    // Fallback: open in-app browser view with Google Maps web
    final webUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');

    if (await canLaunchUrl(androidUri)) {
      await launchUrl(androidUri);
    } else if (await canLaunchUrl(iosUri)) {
      await launchUrl(iosUri);
    } else {
      // Open Google Maps web in-app
      await launchUrl(webUri, mode: LaunchMode.inAppBrowserView);
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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(isTechnician ? '/technician' : '/home');
            }
          },
        ),
        title: const Text('Booking Details'),
      ),
      body: bookingAsync.when(
        data: (booking) {
          final status = _liveStatus ?? booking.status;
          final taskStatus = _liveTaskStatus ?? booking.taskStatus;

          // Start timer if job is already active
          if (status == 'active' && _jobStartedAt == null) {
            if (booking.startedAt != null) {
              _jobStartedAt = booking.startedAt;
            } else {
              _jobStartedAt = DateTime.now();
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _startTimer();
            });
          }

          return SingleChildScrollView(
            padding: Responsive.pagePadding(context),
            child: ResponsiveCenter(
              maxWidth: Responsive.maxContentWidth(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status header with gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _statusGradient(status),
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _statusGradient(status)
                              .first
                              .withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          _statusDisplayIcon(status),
                          color: Colors.white,
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _statusDisplayText(status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Task status subtitle
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _taskStatusDisplay(taskStatus),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Code: ${booking.code}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // SEARCHING ANIMATION
                  if (status == 'searching') ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const SizedBox(
                              width: 48,
                              height: 48,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Looking for a technician nearby...',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please wait while we find the best available technician for your service.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // LIVE JOB TIMER (during active status)
                  if (status == 'active') ...[
                    Card(
                      color: const Color(0xFF059669),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Icon(Icons.timer_rounded,
                                color: Colors.white, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              _formatDuration(_jobDuration),
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Job in progress',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // RECEIPT (on completed)
                  if (status == 'completed') ...[
                    Card(
                      color: Colors.green[50],
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Icon(Icons.receipt_long_rounded,
                                color: Color(0xFF059669), size: 36),
                            const SizedBox(height: 8),
                            const Text(
                              'Receipt',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(height: 24),
                            _PriceRow(
                              label: 'Service',
                              value: booking.categoryName ?? 'N/A',
                            ),
                            if (booking.durationMinutes != null)
                              _PriceRow(
                                label: 'Duration',
                                value: '${booking.durationMinutes} min',
                              ),
                            _PriceRow(
                              label: 'Estimated',
                              value:
                                  '\$${booking.estimatedPrice.toStringAsFixed(2)}',
                            ),
                            if (booking.finalPrice != null) ...[
                              const Divider(),
                              _PriceRow(
                                label: l10n.total,
                                value:
                                    '\$${booking.finalPrice!.toStringAsFixed(2)}',
                                isBold: true,
                              ),
                            ],
                            _PriceRow(
                              label: l10n.paymentMethod,
                              value: booking.paymentMethod == 'cash'
                                  ? l10n.cash
                                  : l10n.card,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Category & Description
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Service',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(booking.categoryName ?? 'N/A'),
                          const SizedBox(height: 12),
                          Text(l10n.description,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            booking.description,
                            textDirection: RegExp(r'[\u0600-\u06FF]').hasMatch(booking.description)
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Address
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.location_on_outlined,
                          color: AppTheme.primaryColor),
                      title: const Text('Address'),
                      subtitle: Text(booking.address),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Technician/Customer info
                  if (!isTechnician && booking.technicianName != null) ...[
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(booking.technicianName![0]),
                        ),
                        title: Text(booking.technicianName!),
                        subtitle: booking.technicianRating != null
                            ? Row(
                                children: [
                                  const Icon(Icons.star,
                                      size: 16, color: Colors.amber),
                                  Text(
                                      ' ${booking.technicianRating!.toStringAsFixed(1)}'),
                                ],
                              )
                            : null,
                        trailing: booking.technicianPhone != null
                            ? IconButton(
                                icon: const Icon(Icons.phone_rounded,
                                    color: AppTheme.primaryColor),
                                onPressed: () => _callPhone(
                                    booking.technicianPhone!),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (isTechnician && booking.customerName != null) ...[
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(booking.customerName![0]),
                        ),
                        title: Text(booking.customerName!),
                        subtitle: const Text('Customer'),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Price info (not shown if receipt already visible)
                  if (status != 'completed')
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _PriceRow(
                              label: 'Estimated',
                              value:
                                  '\$${booking.estimatedPrice.toStringAsFixed(2)}',
                            ),
                            if (booking.finalPrice != null) ...[
                              const Divider(),
                              _PriceRow(
                                label: l10n.total,
                                value:
                                    '\$${booking.finalPrice!.toStringAsFixed(2)}',
                                isBold: true,
                              ),
                            ],
                            const Divider(),
                            _PriceRow(
                              label: l10n.paymentMethod,
                              value: booking.paymentMethod == 'cash'
                                  ? l10n.cash
                                  : l10n.card,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // ARRIVAL CODE (customer sees when assigned/driving/arrived)
                  if (!isTechnician &&
                      booking.arrivalCode != null &&
                      ['assigned', 'driving', 'arrived']
                          .contains(status)) ...[
                    Card(
                      color: AppTheme.accentColor.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Icon(Icons.lock_rounded,
                                size: 28, color: AppTheme.primaryColor),
                            const SizedBox(height: 8),
                            const Text(
                              'Arrival Verification Code',
                              style:
                                  TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              booking.arrivalCode!,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 10,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Share this code with your technician when they arrive',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ====== TECHNICIAN ACTIONS ======
                  if (isTechnician) ...[
                    // Navigate to customer via Google Maps
                    if (['assigned', 'driving'].contains(status))
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _openGoogleMapsNavigation(
                              booking.latitude, booking.longitude),
                          icon: const Icon(Icons.navigation_rounded),
                          label: const Text('Navigate to Customer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    if (['assigned', 'driving'].contains(status))
                      const SizedBox(height: 10),

                    // "I've Arrived" button
                    if (['assigned', 'driving'].contains(status))
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _handleArrive,
                          icon: const Icon(Icons.place_rounded),
                          label: const Text("I've Arrived"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                    // "Enter Code & Start Job" button
                    if (status == 'arrived')
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _handleVerifyAndStart(booking),
                          icon: const Icon(Icons.vpn_key_rounded),
                          label: const Text('Enter Code & Start Job'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                    // "Complete Job" button
                    if (status == 'active')
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _handleCompleteJob,
                          icon: const Icon(Icons.check_circle_rounded),
                          label: const Text('Complete Job'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],

                  // ====== CUSTOMER ACTIONS ======
                  if (!isTechnician && booking.isActive) ...[
                    if (['assigned', 'driving', 'arrived']
                        .contains(status))
                      ElevatedButton.icon(
                        onPressed: () =>
                            context.go('/tracking/${booking.id}'),
                        icon: const Icon(Icons.map_rounded),
                        label: Text(l10n.tracking),
                      ),
                    const SizedBox(height: 8),
                  ],

                  // ====== SHARED ACTIONS ======
                  if (booking.isActive && booking.technicianId != null) ...[
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.go('/chat/${booking.id}'),
                      icon: const Icon(Icons.chat_rounded),
                      label: Text(l10n.chat),
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (booking.isCancellable)
                    TextButton(
                      onPressed: () =>
                          _showCancelDialog(context, ref),
                      style: TextButton.styleFrom(
                          foregroundColor: AppTheme.errorColor),
                      child: Text(l10n.cancelBooking),
                    ),

                  if (status == 'completed' && !isTechnician)
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.go('/rating/${booking.id}'),
                      icon: const Icon(Icons.star_rounded),
                      label: Text(l10n.rateTechnician),
                    ),

                  // View Receipt button
                  if (status == 'completed') ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.go('/receipt/${booking.id}'),
                      icon: const Icon(Icons.receipt_long_rounded),
                      label: const Text('View Receipt'),
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorDisplayWidget(
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(bookingDetailProvider(widget.bookingId)),
        ),
      ),
    );
  }

  void _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).cancelBooking),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Reason for cancellation (optional)',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await ref
                  .read(bookingActionProvider.notifier)
                  .cancelBooking(widget.bookingId,
                      reason: reasonController.text.trim());
              if (success && context.mounted) {
                ref.invalidate(bookingDetailProvider(widget.bookingId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking cancelled')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor),
            child: Text(AppLocalizations.of(context).confirm),
          ),
        ],
      ),
    );
  }

  String _statusDisplayText(String status) {
    switch (status) {
      case 'searching':
        return 'SEARCHING';
      case 'assigned':
        return 'ASSIGNED';
      case 'driving':
        return 'ON THE WAY';
      case 'arrived':
        return 'ARRIVED';
      case 'active':
        return 'IN PROGRESS';
      case 'completed':
        return 'COMPLETED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return status.toUpperCase();
    }
  }

  String _taskStatusDisplay(String taskStatus) {
    switch (taskStatus) {
      case 'searching':
        return 'Searching for technician...';
      case 'technician_coming':
        return 'Technician is on the way';
      case 'technician_working':
        return 'Technician working on your task';
      case 'technician_finished':
        return 'Technician finished the task';
      case 'task_closed':
        return 'Task closed';
      default:
        return taskStatus;
    }
  }

  IconData _statusDisplayIcon(String status) {
    switch (status) {
      case 'searching':
        return Icons.search_rounded;
      case 'assigned':
        return Icons.person_pin_rounded;
      case 'driving':
        return Icons.directions_car_rounded;
      case 'arrived':
        return Icons.place_rounded;
      case 'active':
        return Icons.build_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: isBold
                  ? const TextStyle(fontWeight: FontWeight.bold)
                  : null),
          Text(value,
              style: isBold
                  ? const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)
                  : null),
        ],
      ),
    );
  }
}

List<Color> _statusGradient(String status) {
  switch (status) {
    case 'pending':
    case 'searching':
      return const [Color(0xFFF59E0B), Color(0xFFFBBF24)];
    case 'assigned':
    case 'driving':
      return const [Color(0xFF2563EB), Color(0xFF3B82F6)];
    case 'arrived':
    case 'in_progress':
    case 'active':
      return const [Color(0xFF7C3AED), Color(0xFF8B5CF6)];
    case 'completed':
      return const [Color(0xFF059669), Color(0xFF10B981)];
    case 'cancelled':
      return const [Color(0xFFDC2626), Color(0xFFEF4444)];
    default:
      return const [Color(0xFF2563EB), Color(0xFF3B82F6)];
  }
}
