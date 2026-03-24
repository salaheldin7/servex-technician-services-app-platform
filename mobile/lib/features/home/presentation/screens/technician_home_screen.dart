import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/network/websocket_client.dart';
import '../../../../core/widgets/main_scaffold.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../technician/domain/providers/technician_providers.dart';
import '../../../technician/domain/providers/verification_providers.dart';
import '../../../technician/presentation/screens/verification_flow_screen.dart';
import '../../../notifications/domain/providers/notification_providers.dart';

class TechnicianHomeScreen extends ConsumerStatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  ConsumerState<TechnicianHomeScreen> createState() =>
      _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends ConsumerState<TechnicianHomeScreen> {
  StreamSubscription? _locationSub;
  StreamSubscription? _bookingRequestSub;
  StreamSubscription? _statusSub;

  @override
  void initState() {
    super.initState();
    _listenForBookingRequests();
    _listenForStatusUpdates();
    // Resume location tracking if already online (e.g. returning from booking screen)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isOnline = ref.read(technicianStateProvider).isOnline;
      if (isOnline) {
        _startLocationTracking();
      }
    });
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _bookingRequestSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  void _listenForBookingRequests() {
    final ws = ref.read(wsClientProvider);
    _bookingRequestSub = ws.on('booking_request').listen((data) {
      _showBookingRequestDialog(data['data'] ?? data);
    });
  }

  void _listenForStatusUpdates() {
    final ws = ref.read(wsClientProvider);
    _statusSub = ws.messages.listen((msg) {
      final event = msg['event'] as String?;
      if (event == 'booking_accepted' ||
          event == 'booking_cancelled' ||
          event == 'job_completed' ||
          event == 'job_started') {
        // Refresh active bookings on status change
        ref.read(technicianStateProvider.notifier).loadStats();
      }
    });
  }

  void _toggleOnline() async {
    final notifier = ref.read(technicianStateProvider.notifier);
    final l10n = AppLocalizations.of(context);

    if (ref.read(technicianStateProvider).isOnline) {
      await notifier.goOffline();
      _locationSub?.cancel();
    } else {
      // Check verification status first
      final verifyResult = await ref
          .read(verificationRepositoryProvider)
          .getVerificationStatus();

      if (verifyResult.isSuccess) {
        final status = verifyResult.data!;

        // Application submitted but pending admin review
        if (status.status == 'pending' || status.status == 'docs_done' || status.status == 'face_done') {
          if (mounted) {
            _showPendingReviewDialog();
          }
          return;
        }

        // Rejected
        if (status.status == 'rejected') {
          if (mounted) {
            final reason = status.rejectionReason.isNotEmpty
                ? status.rejectionReason
                : (l10n.isArabic
                    ? 'تم رفض طلبك. يرجى إعادة التقديم.'
                    : 'Your application was rejected. Please re-submit.');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(reason),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
            final completed = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => const VerificationFlowScreen(),
              ),
            );
            if (completed != true) return;
          }
          return;
        }

        if (!status.isFullyVerified) {
          // Need to go through verification flow
          if (!mounted) return;
          final completed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const VerificationFlowScreen(),
            ),
          );
          if (completed != true) return;
          // Re-check after verification flow
          final recheck = await ref
              .read(verificationRepositoryProvider)
              .getVerificationStatus();
          if (!recheck.isSuccess || !recheck.data!.isFullyVerified) {
            if (mounted) {
              // Application just submitted → show pending
              if (recheck.isSuccess && (recheck.data!.status == 'pending' || recheck.data!.status == 'docs_done')) {
                _showPendingReviewDialog();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.isArabic
                        ? 'يجب إكمال التحقق والموافقة عليه من الإدارة أولاً'
                        : 'Verification must be completed and approved by admin first'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
            return;
          }
        }
      } else {
        // Verification status check failed — launch verification flow
        if (!mounted) return;
        final completed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => const VerificationFlowScreen(),
          ),
        );
        if (completed != true) return;
        // Re-check status after flow completes
        final recheck = await ref
            .read(verificationRepositoryProvider)
            .getVerificationStatus();
        if (!recheck.isSuccess || !recheck.data!.isFullyVerified) {
          if (mounted) {
            if (recheck.isSuccess && (recheck.data!.status == 'pending' || recheck.data!.status == 'docs_done')) {
              _showPendingReviewDialog();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.isArabic
                      ? 'يجب إكمال التحقق والموافقة عليه من الإدارة أولاً'
                      : 'Verification must be completed and approved by admin first'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
          return;
        }
      }

      // Try to go online — backend also enforces verification
      final onlineResult = await notifier.goOnline();
      if (!mounted) return;

      if (onlineResult.isFailure) {
        final errorMsg = onlineResult.error?.message ?? '';
        String displayMsg;
        if (errorMsg.contains('verification_required') || (onlineResult.error?.statusCode == 403)) {
          displayMsg = l10n.isArabic
              ? 'يجب إكمال التحقق والموافقة عليه من الإدارة قبل الاتصال'
              : 'Verification must be approved by admin before going online';
        } else {
          displayMsg = errorMsg.isNotEmpty ? errorMsg : (l10n.isArabic ? 'فشل الاتصال' : 'Failed to go online');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(displayMsg), backgroundColor: Colors.red),
        );
        return;
      }

      _startLocationTracking();

      // Send initial location immediately so PostGIS has data for matching
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        ref.read(technicianStateProvider.notifier).updateLocation(
              pos.latitude,
              pos.longitude,
            );
        final ws = ref.read(wsClientProvider);
        ws.sendLocation(pos.latitude, pos.longitude);
      } catch (_) {}

      // Navigate to requests page so technician can see incoming requests
      if (mounted) {
        context.push('/technician/requests');
      }
    }
  }

  void _startLocationTracking() {
    final ws = ref.read(wsClientProvider);

    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      ws.sendLocation(position.latitude, position.longitude);
      ref.read(technicianStateProvider.notifier).updateLocation(
            position.latitude,
            position.longitude,
          );
    });
  }

  void _showPendingReviewDialog() {
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.isArabic;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.hourglass_top_rounded,
                  color: Colors.orange[700], size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              isArabic ? 'بانتظار المراجعة' : 'Awaiting Review',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              isArabic
                  ? 'تم إرسال طلبك وهو قيد المراجعة. ستصلك إشعار عند الموافقة.'
                  : 'Your application is under review. You will be notified once approved.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(isArabic ? 'حسناً' : 'OK',
                  style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingRequestDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _BookingRequestPopup(
          booking: booking,
          onAccept: () {
            Navigator.of(context).pop();
            final bookingId = booking['id'] ?? booking['booking_id'];
            if (bookingId != null) {
              ref
                  .read(technicianStateProvider.notifier)
                  .acceptBooking(bookingId.toString());
              this.context.go('/booking/$bookingId');
            }
          },
          onDecline: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authStateProvider).user;
    final techState = ref.watch(technicianStateProvider);

    return Scaffold(
      body: CustomScrollView(
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
                  child: Row(
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
                              '${l10n.appName} - ${l10n.technician}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                            Text(
                              'Hello, ${user?.fullName.split(' ').first ?? ''}',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: InkWell(
                          onTap: () =>
                              ref.read(localeProvider.notifier).toggleLocale(),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.language,
                                    size: 16,
                                    color:
                                        Colors.white.withValues(alpha: 0.9)),
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
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: Responsive.pagePadding(context),
            sliver: SliverToBoxAdapter(
              child: ResponsiveCenter(
                maxWidth: Responsive.maxContentWidth(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Online/Offline toggle
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              'Hello, ${user?.fullName.split(' ').first ?? ''}',
                              style:
                                  Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: _toggleOnline,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: Responsive.value<double>(
                                        context, mobile: 100, tablet: 120),
                                    height: Responsive.value<double>(
                                        context, mobile: 100, tablet: 120),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: ref.watch(technicianStateProvider).isOnline
                                          ? AppTheme.successColor
                                          : Colors.grey,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (ref.watch(technicianStateProvider).isOnline
                                                  ? AppTheme.successColor
                                                  : Colors.grey)
                                              .withValues(alpha: 0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            ref.watch(technicianStateProvider).isOnline
                                                ? Icons.power_settings_new
                                                : Icons.power_off,
                                            size: Responsive.value<double>(
                                                context,
                                                mobile: 32,
                                                tablet: 40),
                                            color: Colors.white,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            ref.watch(technicianStateProvider).isOnline
                                                ? l10n.goOffline
                                                : l10n.goOnline,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (ref.watch(technicianStateProvider).isOnline) ...[
                                  const SizedBox(width: 20),
                                  GestureDetector(
                                    onTap: () => context.push('/technician/requests'),
                                    child: Container(
                                      width: Responsive.value<double>(
                                          context, mobile: 100, tablet: 120),
                                      height: Responsive.value<double>(
                                          context, mobile: 100, tablet: 120),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF059669),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF059669)
                                                .withValues(alpha: 0.4),
                                            blurRadius: 20,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.inbox_rounded,
                                              size: 32,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              l10n.isArabic ? 'الطلبات' : 'Requests',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats cards
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.star_rounded,
                            label: l10n.rating,
                            value: techState.rating?.toStringAsFixed(1) ??
                                '0.0',
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.check_circle_rounded,
                            label: l10n.completedJobs,
                            value: '${techState.completedJobs ?? 0}',
                            color: AppTheme.successColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.account_balance_wallet_rounded,
                            label: l10n.earnings,
                            value:
                                '\$${techState.balance?.toStringAsFixed(2) ?? '0.00'}',
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.warning_rounded,
                            label: l10n.strikes,
                            value: '${techState.strikes ?? 0}/3',
                            color: AppTheme.errorColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // My Services & Areas quick action
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: InkWell(
                        onTap: () => context.push('/technician/my-services'),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.handyman_rounded,
                                    color: AppTheme.primaryColor),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.isArabic ? 'خدماتي ومناطقي' : 'My Services & Areas',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.isArabic
                                          ? 'إدارة خدماتك ومناطق عملك'
                                          : 'Manage your services and work areas',
                                      style: TextStyle(
                                          color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: Colors.grey[400]),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // (Incoming Requests button moved up next to toggle)

                    const SizedBox(height: 12),

                    // Recent/Active bookings
                    Text(
                      l10n.bookings,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (techState.activeBookings.isEmpty)
                      EmptyStateWidget(
                        icon: Icons.calendar_today_rounded,
                        title: l10n.noBookings,
                      )
                    else
                      ...techState.activeBookings.map((booking) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor
                                  .withValues(alpha: 0.1),
                              child: const Icon(Icons.work_rounded,
                                  color: AppTheme.primaryColor),
                            ),
                            title:
                                Text(booking.categoryName ?? 'Booking'),
                            subtitle: Text(booking.address),
                            trailing:
                                StatusBadge(status: booking.status),
                            onTap: () =>
                                context.go('/booking/${booking.id}'),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon,
                color: color, size: Responsive.iconSize(context)),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// Booking Request Popup with 60s countdown
// ==========================================
class _BookingRequestPopup extends StatefulWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _BookingRequestPopup({
    required this.booking,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<_BookingRequestPopup> createState() => _BookingRequestPopupState();
}

class _BookingRequestPopupState extends State<_BookingRequestPopup>
    with SingleTickerProviderStateMixin {
  static const int _timeoutSeconds = 60;
  late int _remaining;
  Timer? _timer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _remaining = _timeoutSeconds;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 1) {
        _timer?.cancel();
        widget.onDecline(); // auto-decline on timeout
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final progress = _remaining / _timeoutSeconds;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, child) => Transform.scale(
                scale: 1.0 + _pulseController.value * 0.1,
                child: child,
              ),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.handyman_rounded,
                    color: AppTheme.primaryColor, size: 32),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'New Booking Request!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Timer ring
            SizedBox(
              width: 70,
              height: 70,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _remaining <= 10 ? Colors.red : AppTheme.primaryColor,
                    ),
                  ),
                  Center(
                    child: Text(
                      '${_remaining}s',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _remaining <= 10 ? Colors.red : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Booking details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(
                    icon: Icons.category_rounded,
                    label: b['category_name'] ?? 'Service',
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.description_rounded,
                    label: b['description'] ?? 'No description',
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.location_on_rounded,
                    label: b['address'] ?? 'Unknown address',
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.attach_money_rounded,
                    label: 'Est. \$${b['estimated_price'] ?? '0'}',
                  ),
                  if (b['customer_name'] != null) ...[
                    const SizedBox(height: 8),
                    _DetailRow(
                      icon: Icons.person_rounded,
                      label: b['customer_name'],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: widget.onDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Decline',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: widget.onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Accept',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
