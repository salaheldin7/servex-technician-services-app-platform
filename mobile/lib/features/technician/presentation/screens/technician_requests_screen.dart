import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/network/websocket_client.dart';
import '../../domain/providers/technician_providers.dart';

/// Pending booking requests page for technicians.
/// Shows all incoming requests with accept/decline actions.
class TechnicianRequestsScreen extends ConsumerStatefulWidget {
  const TechnicianRequestsScreen({super.key});

  @override
  ConsumerState<TechnicianRequestsScreen> createState() =>
      _TechnicianRequestsScreenState();
}

class _TechnicianRequestsScreenState
    extends ConsumerState<TechnicianRequestsScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  StreamSubscription? _wsSub;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _listenForNewRequests();
    // Periodically refresh to catch expired requests
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _loadRequests();
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    final repo = ref.read(technicianRepositoryProvider);
    final result = await repo.getPendingRequests();
    if (mounted) {
      setState(() {
        _loading = false;
        if (result.isSuccess) {
          _requests = result.data!;
        }
      });
    }
  }

  void _listenForNewRequests() {
    final ws = ref.read(wsClientProvider);
    _wsSub = ws.on('booking_request').listen((data) {
      final requestData = data['data'] ?? data;
      if (mounted) {
        setState(() {
          // Add to list if not already present
          final bookingId = requestData['booking_id']?.toString();
          final exists = _requests.any(
              (r) => r['booking_id']?.toString() == bookingId);
          if (!exists) {
            _requests.insert(0, Map<String, dynamic>.from(requestData));
          }
        });
      }
    });
  }

  Future<void> _acceptRequest(Map<String, dynamic> request) async {
    final bookingId = request['booking_id']?.toString();
    if (bookingId == null) return;

    final notifier = ref.read(technicianStateProvider.notifier);
    await notifier.acceptBooking(bookingId);

    if (mounted) {
      setState(() {
        _requests.removeWhere(
            (r) => r['booking_id']?.toString() == bookingId);
      });
      context.go('/booking/$bookingId');
    }
  }

  void _declineRequest(Map<String, dynamic> request) {
    final bookingId = request['booking_id']?.toString();
    if (bookingId == null) return;
    setState(() {
      _requests
          .removeWhere((r) => r['booking_id']?.toString() == bookingId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.isArabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'الطلبات الواردة' : 'Incoming Requests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/technician'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? _buildEmptyState(isArabic)
              : RefreshIndicator(
                  onRefresh: _loadRequests,
                  child: ListView.builder(
                    padding: Responsive.pagePadding(context),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      return _RequestCard(
                        request: _requests[index],
                        onAccept: () => _acceptRequest(_requests[index]),
                        onDecline: () => _declineRequest(_requests[index]),
                        isArabic: isArabic,
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(bool isArabic) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inbox_rounded,
                size: 48, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          Text(
            isArabic ? 'لا توجد طلبات حالياً' : 'No requests right now',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? 'ستظهر الطلبات الجديدة هنا عندما يطلب العملاء الخدمة'
                : 'New requests will appear here when customers book a service',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            isArabic
                ? 'يتم التحديث تلقائياً'
                : 'Auto-refreshing...',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final bool isArabic;

  const _RequestCard({
    required this.request,
    required this.onAccept,
    required this.onDecline,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final categoryName =
        request['category_name']?.toString() ?? (isArabic ? 'خدمة' : 'Service');
    final description =
        request['description']?.toString() ?? (isArabic ? 'بدون وصف' : 'No description');
    final address =
        request['address']?.toString() ?? (isArabic ? 'غير محدد' : 'Unknown');
    final customerName =
        request['customer_name']?.toString();
    final estimatedPrice = request['estimated_price'];
    final distance = request['distance'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with category
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.handyman_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    categoryName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (distance != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(distance as num).toStringAsFixed(1)} km',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.description_rounded,
                        size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        description,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textDirection: RegExp(r'[\u0600-\u06FF]').hasMatch(description)
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[700]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Customer name
                if (customerName != null && customerName.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.person_rounded,
                          size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          customerName,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // Estimated price
                if (estimatedPrice != null &&
                    (estimatedPrice is num) && estimatedPrice > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.attach_money_rounded,
                          size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        '${isArabic ? 'السعر المقدر' : 'Est. price'}: \$${(estimatedPrice as num).toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: onDecline,
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: Text(isArabic ? 'رفض' : 'Decline'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: onAccept,
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: Text(isArabic ? 'قبول' : 'Accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
