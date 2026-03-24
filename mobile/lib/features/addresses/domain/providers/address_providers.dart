import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/address_repository.dart';

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return AddressRepository(ref.read(apiClientProvider));
});

final addressesProvider = FutureProvider.autoDispose<List<UserAddress>>((ref) async {
  final repo = ref.read(addressRepositoryProvider);
  final result = await repo.getAddresses();
  if (result.isSuccess) return result.data!;
  return [];
});

final defaultAddressProvider = FutureProvider.autoDispose<UserAddress?>((ref) async {
  final repo = ref.read(addressRepositoryProvider);
  final result = await repo.getDefault();
  if (result.isSuccess) return result.data;
  return null;
});
