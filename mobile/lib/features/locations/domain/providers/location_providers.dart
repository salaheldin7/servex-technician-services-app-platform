import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/location_repository.dart';
import '../models/location_models.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository(ref.read(apiClientProvider));
});

final countriesProvider = FutureProvider<List<Country>>((ref) async {
  final repo = ref.read(locationRepositoryProvider);
  final result = await repo.getCountries();
  return result.isSuccess ? result.data! : [];
});

final governoratesProvider =
    FutureProvider.family<List<Governorate>, String>((ref, countryId) async {
  final repo = ref.read(locationRepositoryProvider);
  final result = await repo.getGovernorates(countryId);
  return result.isSuccess ? result.data! : [];
});

final citiesProvider =
    FutureProvider.family<List<City>, String>((ref, governorateId) async {
  final repo = ref.read(locationRepositoryProvider);
  final result = await repo.getCities(governorateId);
  return result.isSuccess ? result.data! : [];
});
