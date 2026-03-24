import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/providers/booking_providers.dart';
import '../../../home/domain/models/home_models.dart';

class ReceiptScreen extends ConsumerWidget {
  final String bookingId;
  const ReceiptScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final bookingAsync = ref.watch(bookingDetailProvider(bookingId));
    final isTechnician =
        ref.watch(authStateProvider).user?.role == 'technician';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(l10n.translate('receipt')),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            context.go(isTechnician ? '/technician' : '/home');
          },
        ),
      ),
      body: bookingAsync.when(
        data: (booking) => SingleChildScrollView(
          padding: Responsive.pagePadding(context),
          child: ResponsiveCenter(
            maxWidth: Responsive.maxFormWidth(context),
            child: _ReceiptCard(
              booking: booking,
              isTechnician: isTechnician,
              l10n: l10n,
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final Booking booking;
  final bool isTechnician;
  final AppLocalizations l10n;

  const _ReceiptCard({
    required this.booking,
    required this.isTechnician,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),

        // Status icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: booking.status == 'cancelled'
                ? Colors.red.withValues(alpha: 0.1)
                : AppTheme.successColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            booking.status == 'cancelled'
                ? Icons.cancel_rounded
                : Icons.check_circle_rounded,
            color: booking.status == 'cancelled'
                ? Colors.red
                : AppTheme.successColor,
            size: 48,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          booking.status == 'completed'
              ? l10n.translate('task_completed')
              : l10n.translate('task_closed'),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Booking #${booking.arrivalCode ?? booking.id.substring(0, 8).toUpperCase()}',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        const SizedBox(height: 24),

        // Receipt card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: booking.status == 'cancelled'
                          ? [const Color(0xFFDC2626), const Color(0xFFEF4444)]
                          : [const Color(0xFF059669), const Color(0xFF10B981)]),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        color: Colors.white, size: 32),
                    const SizedBox(height: 8),
                    Text(l10n.translate('receipt'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Service
                    _ReceiptRow(
                      icon: Icons.handyman_rounded,
                      label: l10n.translate('service'),
                      value: booking.categoryName ?? 'N/A',
                    ),
                    const _ReceiptDivider(),

                    // Technician / Customer info
                    if (!isTechnician && booking.technicianName != null)
                      _ReceiptRow(
                        icon: Icons.person_rounded,
                        label: l10n.translate('technician'),
                        value: booking.technicianName!,
                      ),
                    if (isTechnician && booking.customerName != null)
                      _ReceiptRow(
                        icon: Icons.person_rounded,
                        label: l10n.translate('customer'),
                        value: booking.customerName!,
                      ),
                    if (booking.technicianName != null ||
                        booking.customerName != null)
                      const _ReceiptDivider(),

                    // Location
                    _ReceiptRow(
                      icon: Icons.location_on_rounded,
                      label: l10n.translate('location'),
                      value: booking.fullAddress ?? booking.address,
                    ),
                    const _ReceiptDivider(),

                    // Duration
                    if (booking.durationMinutes != null) ...[
                      _ReceiptRow(
                        icon: Icons.timer_rounded,
                        label: l10n.translate('duration'),
                        value: _formatDuration(booking.durationMinutes!),
                      ),
                      const _ReceiptDivider(),
                    ],

                    // Date
                    _ReceiptRow(
                      icon: Icons.calendar_today_rounded,
                      label: l10n.translate('date'),
                      value: _formatDate(
                          booking.completedAt ?? booking.createdAt),
                    ),
                    const _ReceiptDivider(),

                    // Payment method
                    _ReceiptRow(
                      icon: Icons.payment_rounded,
                      label: l10n.paymentMethod,
                      value: booking.paymentMethod == 'cash'
                          ? l10n.cash
                          : l10n.card,
                    ),

                    const SizedBox(height: 16),
                    const Divider(thickness: 2),
                    const SizedBox(height: 8),

                    // Estimated price
                    _PriceLine(
                      label: l10n.translate('estimated_price'),
                      amount: booking.estimatedPrice,
                      isBold: false,
                    ),

                    // Final price
                    if (booking.finalPrice != null) ...[
                      const SizedBox(height: 8),
                      _PriceLine(
                        label: l10n.total,
                        amount: booking.finalPrice!,
                        isBold: true,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ],
                ),
              ),

              // Dashed line
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: List.generate(
                    40,
                    (i) => Expanded(
                        child: Container(
                            height: 1,
                            color:
                                i.isEven ? Colors.grey[300] : Colors.transparent)),
                  ),
                ),
              ),

              // Thank you
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(l10n.translate('thank_you'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                        isTechnician
                            ? l10n.translate('job_completed_message')
                            : l10n.translate('service_completed_message'),
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 13),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Rate button (customer only)
        if (!isTechnician && booking.status == 'completed')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  context.go('/rating/${booking.id}'),
              icon: const Icon(Icons.star_rounded),
              label: Text(l10n.rateTechnician),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
          ),

        const SizedBox(height: 12),

        // Back to home
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () =>
                context.go(isTechnician ? '/technician' : '/home'),
            icon: const Icon(Icons.home_rounded),
            label: Text(l10n.translate('back_to_home')),
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _ReceiptRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ReceiptRow(
      {required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 14),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

class _ReceiptDivider extends StatelessWidget {
  const _ReceiptDivider();
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: Colors.grey[200]);
}

class _PriceLine extends StatelessWidget {
  final String label;
  final double amount;
  final bool isBold;
  final Color? color;
  const _PriceLine(
      {required this.label,
      required this.amount,
      this.isBold = false,
      this.color});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: isBold ? 16 : 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color)),
        Text('\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
                fontSize: isBold ? 20 : 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color)),
      ],
    );
  }
}
