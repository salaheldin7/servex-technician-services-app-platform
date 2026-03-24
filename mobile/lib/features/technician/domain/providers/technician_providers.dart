import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/technician_repository.dart';
import '../../../home/domain/models/home_models.dart';
import '../../../home/data/home_repository.dart';
import '../../../home/domain/providers/home_providers.dart';

final technicianRepositoryProvider = Provider<TechnicianRepository>((ref) {
  return TechnicianRepository(ref.read(apiClientProvider));
});

class TechnicianState {
  final bool isLoading;
  final String? error;
  final double? rating;
  final int? completedJobs;
  final double? balance;
  final int? strikes;
  final bool isOnline;
  final List<Booking> activeBookings;

  TechnicianState({
    this.isLoading = false,
    this.error,
    this.rating,
    this.completedJobs,
    this.balance,
    this.strikes,
    this.isOnline = false,
    this.activeBookings = const [],
  });

  TechnicianState copyWith({
    bool? isLoading,
    String? error,
    double? rating,
    int? completedJobs,
    double? balance,
    int? strikes,
    bool? isOnline,
    List<Booking>? activeBookings,
  }) {
    return TechnicianState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      rating: rating ?? this.rating,
      completedJobs: completedJobs ?? this.completedJobs,
      balance: balance ?? this.balance,
      strikes: strikes ?? this.strikes,
      isOnline: isOnline ?? this.isOnline,
      activeBookings: activeBookings ?? this.activeBookings,
    );
  }
}

final technicianStateProvider =
    NotifierProvider<TechnicianNotifier, TechnicianState>(TechnicianNotifier.new);

class TechnicianNotifier extends Notifier<TechnicianState> {
  @override
  TechnicianState build() {
    loadStats();
    return TechnicianState();
  }

  TechnicianRepository get _repo => ref.read(technicianRepositoryProvider);

  Future<void> loadStats() async {
    try {
      state = state.copyWith(isLoading: true);
    } catch (_) {
      // First call from build() — state not yet initialized
    }
    final result = await _repo.getStats();
    if (result.isSuccess) {
      final stats = result.data!;
      state = state.copyWith(
        isLoading: false,
        rating: stats.rating,
        completedJobs: stats.completedJobs,
        balance: stats.balance,
        strikes: stats.strikes,
        isOnline: stats.isOnline,
      );
    } else {
      state = state.copyWith(isLoading: false, error: result.error?.message);
    }
    // Also load active bookings for the technician
    _loadActiveBookings();
  }

  Future<void> _loadActiveBookings() async {
    final homeRepo = ref.read(homeRepositoryProvider);
    final result = await homeRepo.getActiveBookings();
    if (result.isSuccess) {
      state = state.copyWith(activeBookings: result.data!);
    }
  }

  Future<ApiResult<void>> goOnline() async {
    final result = await _repo.goOnline();
    if (result.isSuccess) {
      state = state.copyWith(isOnline: true);
    } else {
      state = state.copyWith(error: result.error?.message);
    }
    return result;
  }

  Future<ApiResult<void>> goOffline() async {
    final result = await _repo.goOffline();
    if (result.isSuccess) {
      state = state.copyWith(isOnline: false);
    } else {
      state = state.copyWith(error: result.error?.message);
    }
    return result;
  }

  Future<void> updateLocation(double lat, double lng) async {
    await _repo.updateLocation(lat, lng);
  }

  Future<void> acceptBooking(String bookingId) async {
    await _repo.acceptBooking(bookingId);
    // Refresh active bookings after accepting
    _loadActiveBookings();
  }
}
