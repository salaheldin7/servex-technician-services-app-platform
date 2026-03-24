import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/booking_repository.dart';
import '../../../home/domain/models/home_models.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(ref.read(apiClientProvider));
});

final bookingDetailProvider =
    FutureProvider.family<Booking, String>((ref, id) async {
  final repo = ref.read(bookingRepositoryProvider);
  final result = await repo.getBooking(id);
  if (result.isSuccess) return result.data!;
  throw Exception(result.error?.message ?? 'Failed to load booking');
});

final bookingsListProvider = FutureProvider<List<Booking>>((ref) async {
  final repo = ref.read(bookingRepositoryProvider);
  final result = await repo.listBookings();
  if (result.isSuccess) return result.data!;
  throw Exception(result.error?.message ?? 'Failed to load bookings');
});

final technicianSearchProvider = FutureProvider.family<List<Map<String, dynamic>>, Map<String, String>>((ref, params) async {
  final repo = ref.read(bookingRepositoryProvider);
  final result = await repo.searchTechnicians(
    categoryId: params['category_id']!,
    countryId: params['country_id']!,
    governorateId: params['governorate_id']!,
    cityId: params['city_id']!,
  );
  if (result.isSuccess) return result.data!;
  throw Exception(result.error?.message ?? 'No technicians found');
});

class BookingState {
  final bool isLoading;
  final String? error;
  final Booking? lastCreated;

  BookingState({this.isLoading = false, this.error, this.lastCreated});
}

final bookingActionProvider =
    NotifierProvider<BookingActionNotifier, BookingState>(BookingActionNotifier.new);

class BookingActionNotifier extends Notifier<BookingState> {
  @override
  BookingState build() => BookingState();

  BookingRepository get _repo => ref.read(bookingRepositoryProvider);

  Future<Booking?> createBooking({
    required String categoryId,
    required String description,
    required double latitude,
    required double longitude,
    required String address,
    String? scheduledAt,
    required double estimatedPrice,
    required String paymentMethod,
    String? countryId,
    String? governorateId,
    String? cityId,
    String? addressId,
    String? streetName,
    String? buildingName,
    String? buildingNumber,
    String? floor,
    String? apartment,
    String? fullAddress,
    String? technicianId,
    bool autoAssign = false,
  }) async {
    state = BookingState(isLoading: true);
    final result = await _repo.createBooking(
      categoryId: categoryId,
      description: description,
      latitude: latitude,
      longitude: longitude,
      address: address,
      scheduledAt: scheduledAt,
      estimatedPrice: estimatedPrice,
      paymentMethod: paymentMethod,
      countryId: countryId,
      governorateId: governorateId,
      cityId: cityId,
      addressId: addressId,
      streetName: streetName,
      buildingName: buildingName,
      buildingNumber: buildingNumber,
      floor: floor,
      apartment: apartment,
      fullAddress: fullAddress,
      technicianId: technicianId,
      autoAssign: autoAssign,
    );

    if (result.isSuccess) {
      state = BookingState(lastCreated: result.data);
      return result.data;
    } else {
      state = BookingState(error: result.error?.message);
      return null;
    }
  }

  Future<Map<String, dynamic>?> autoAssignTechnician({
    required String categoryId,
    required String countryId,
    required String governorateId,
    required String cityId,
  }) async {
    final result = await _repo.autoAssignTechnician(
      categoryId: categoryId,
      countryId: countryId,
      governorateId: governorateId,
      cityId: cityId,
    );
    if (result.isSuccess) return result.data;
    return null;
  }

  Future<bool> cancelBooking(String id, {String? reason}) async {
    state = BookingState(isLoading: true);
    final result = await _repo.cancelBooking(id, reason: reason);
    state = BookingState(error: result.isFailure ? result.error?.message : null);
    return result.isSuccess;
  }

  Future<bool> arriveAtBooking(String id) async {
    final result = await _repo.arriveAtBooking(id);
    return result.isSuccess;
  }

  Future<bool> verifyArrival(
    String id, {
    required String code,
    required double lat,
    required double lng,
  }) async {
    final result = await _repo.verifyArrival(id,
        code: code, latitude: lat, longitude: lng);
    return result.isSuccess;
  }

  Future<bool> startJob(String id) async {
    final result = await _repo.startJob(id);
    return result.isSuccess;
  }

  Future<bool> completeJob(String id, {double? finalPrice}) async {
    final result = await _repo.completeJob(id, finalPrice: finalPrice);
    return result.isSuccess;
  }
}
