import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/home_repository.dart';
import '../models/home_models.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(ref.read(apiClientProvider));
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.read(homeRepositoryProvider);
  final result = await repo.getCategories();
  if (result.isSuccess) return result.data!;
  throw Exception(result.error?.message ?? 'Failed to load categories');
});

final nearbyTechniciansProvider =
    FutureProvider.family<List<NearbyTechnician>, Map<String, double>>(
        (ref, coords) async {
  final repo = ref.read(homeRepositoryProvider);
  final result = await repo.getNearbyTechnicians(
    lat: coords['lat']!,
    lng: coords['lng']!,
  );
  if (result.isSuccess) return result.data!;
  // Return empty list on error instead of throwing (prevents infinite retry)
  return [];
});

final activeBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final repo = ref.read(homeRepositoryProvider);
  final result = await repo.getActiveBookings();
  if (result.isSuccess) return result.data!;
  throw Exception(result.error?.message ?? 'Failed to load bookings');
});

final bookingHistoryProvider =
    FutureProvider.family<List<Booking>, int>((ref, page) async {
  final repo = ref.read(homeRepositoryProvider);
  final result = await repo.getBookingHistory(page: page);
  if (result.isSuccess) return result.data!;
  throw Exception(result.error?.message ?? 'Failed to load bookings');
});
