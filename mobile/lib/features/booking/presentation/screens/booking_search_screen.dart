import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/websocket_client.dart';
import '../../domain/providers/booking_providers.dart';

/// Animated searching screen shown after booking creation.
/// Keeps polling / listening for technician assignment until:
///  • A technician accepts (WebSocket event)  → navigate to booking detail
///  • User presses "Stop Searching"           → cancel booking
class BookingSearchScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const BookingSearchScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingSearchScreen> createState() =>
      _BookingSearchScreenState();
}

class _BookingSearchScreenState extends ConsumerState<BookingSearchScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _dotController;
  late Animation<double> _pulseAnim;
  StreamSubscription? _wsSub;
  Timer? _tipTimer;
  int _tipIndex = 0;
  bool _cancelling = false;
  bool _accepted = false;

  static const _waitingTips = [
    {'icon': Icons.search_rounded, 'text': 'Looking for the best technician near you...'},
    {'icon': Icons.engineering_rounded, 'text': 'Matching your request with verified professionals...'},
    {'icon': Icons.verified_user_rounded, 'text': 'All our technicians are background-checked and certified.'},
    {'icon': Icons.star_rounded, 'text': 'We prioritize technicians with the highest ratings.'},
    {'icon': Icons.speed_rounded, 'text': 'Average response time is under 3 minutes!'},
    {'icon': Icons.shield_rounded, 'text': 'Your service is protected by our satisfaction guarantee.'},
    {'icon': Icons.support_agent_rounded, 'text': '24/7 support is available if you need help.'},
    {'icon': Icons.payments_rounded, 'text': 'Pay securely — no hidden fees, transparent pricing.'},
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Rotate tips every 4 seconds
    _tipTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() => _tipIndex = (_tipIndex + 1) % _waitingTips.length);
    });

    _listenForAssignment();
  }

  void _listenForAssignment() {
    final ws = ref.read(wsClientProvider);
    _wsSub = ws.messages.listen((msg) {
      final event = msg['event'] as String?;
      final data = msg['data'] ?? msg;
      final bookingId = data['booking_id']?.toString();
      if (bookingId != widget.bookingId) return;

      if (event == 'booking_accepted' ||
          event == 'booking_status_update' ||
          event == 'technician_assigned') {
        final newStatus = data['status']?.toString() ?? '';
        if (['assigned', 'driving', 'arrived', 'active'].contains(newStatus)) {
          // Technician found! Navigate to booking detail
          _accepted = true;
          if (mounted) {
            context.go('/booking/${widget.bookingId}');
          }
        }
      }
      if (event == 'booking_cancelled') {
        if (mounted) context.go('/home');
      }
      if (event == 'no_technician_found') {
        if (mounted) {
          _accepted = true; // Prevent auto-cancel on dispose
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No technicians available right now. Please try again later.'),
              duration: Duration(seconds: 4),
            ),
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) context.go('/home');
          });
        }
      }
    });
  }

  @override
  void dispose() {
    // Auto-cancel the searching booking if user leaves this screen
    // without explicitly pressing Stop (e.g. back button, navigation)
    if (!_cancelling && !_accepted) {
      final repo = ref.read(bookingRepositoryProvider);
      repo.cancelBooking(widget.bookingId, reason: 'User left search screen');
    }
    _pulseController.dispose();
    _dotController.dispose();
    _wsSub?.cancel();
    _tipTimer?.cancel();
    super.dispose();
  }

  Future<void> _cancelSearch() async {
    setState(() => _cancelling = true);
    final repo = ref.read(bookingRepositoryProvider);
    await repo.cancelBooking(widget.bookingId, reason: 'User stopped searching');
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tip = _waitingTips[_tipIndex];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A5F), Color(0xFF2563EB), Color(0xFF1E3A5F)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Spacer(),
                    Text(
                      AppLocalizations.of(context).translate('searching'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Animated search radar
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer pulse rings
                      for (int i = 0; i < 3; i++)
                        Transform.scale(
                          scale: _pulseAnim.value + (i * 0.25),
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(
                                    alpha: max(0.0, 0.3 - (i * 0.1))),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      // Center icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_search_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 40),

              // Animated "Searching..." text
              _AnimatedSearchText(controller: _dotController),

              const SizedBox(height: 12),

              Text(
                'Please wait while we find the perfect\ntechnician for your request',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const Spacer(flex: 1),

              // Tip card that rotates
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  key: ValueKey(_tipIndex),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          tip['icon'] as IconData,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          tip['text'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_waitingTips.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: i == _tipIndex ? 20 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == _tipIndex
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 32),

              // Stop searching button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _cancelling ? null : _cancelSearch,
                    icon: _cancelling
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white70,
                            ),
                          )
                        : const Icon(Icons.close_rounded, color: Colors.white70),
                    label: Text(
                      _cancelling ? 'Cancelling...' : 'Stop Searching',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated "Searching..." with bouncing dots
class _AnimatedSearchText extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedSearchText({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final progress = controller.value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Searching',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            for (int i = 0; i < 3; i++)
              Transform.translate(
                offset: Offset(0, -4 * sin(((progress + i * 0.33) % 1.0) * pi)),
                child: const Text(
                  '.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
