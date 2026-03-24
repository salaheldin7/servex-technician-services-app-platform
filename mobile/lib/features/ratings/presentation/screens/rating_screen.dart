import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../data/rating_repository.dart';
import '../../../booking/domain/providers/booking_providers.dart';

class RatingScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const RatingScreen({super.key, required this.bookingId});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  int _score = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_score == 0) return;

    setState(() => _isSubmitting = true);

    final booking =
        await ref.read(bookingDetailProvider(widget.bookingId).future);

    if (booking.technicianId == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    final result = await ref.read(ratingRepositoryProvider).submitRating(
          bookingId: widget.bookingId,
          technicianId: booking.technicianId!,
          score: _score,
          comment: _commentController.text.trim().isNotEmpty
              ? _commentController.text.trim()
              : null,
        );

    setState(() => _isSubmitting = false);

    if (result.isSuccess && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your rating!')),
      );
      context.pop();
    } else if (result.isFailure && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error?.message ?? 'Failed to submit rating'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.rateTechnician),
      ),
      body: SingleChildScrollView(
        padding: Responsive.pagePadding(context),
        child: ResponsiveCenter(
          maxWidth: Responsive.maxFormWidth(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Icon(Icons.star_border_rounded,
                  size: Responsive.value<double>(context, mobile: 80, tablet: 100),
                  color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              l10n.rateTechnician,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 32),

            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  iconSize: Responsive.value<double>(context, mobile: 48, tablet: 56),
                  icon: Icon(
                    index < _score
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Colors.amber,
                  ),
                  onPressed: () => setState(() => _score = index + 1),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _score > 0 ? _ratingLabel(_score) : 'Tap to rate',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),

            // Comment
            TextFormField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: l10n.writeReview,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _score > 0 && !_isSubmitting ? _submit : null,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l10n.submitRating),
            ),
            ],
          ),
        ),
      ),
    );
  }

  String _ratingLabel(int score) {
    switch (score) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}
