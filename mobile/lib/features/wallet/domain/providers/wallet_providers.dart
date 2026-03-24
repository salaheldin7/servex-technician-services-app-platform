import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.read(apiClientProvider));
});

final walletBalanceProvider = FutureProvider<WalletBalance>((ref) async {
  final repo = ref.read(walletRepositoryProvider);
  final result = await repo.getBalance();
  if (result.isSuccess) return result.data!;
  throw Exception(result.error?.message ?? 'Failed to load balance');
});

final walletTransactionsProvider =
    FutureProvider.family<List<WalletTransaction>, int>((ref, page) async {
  final repo = ref.read(walletRepositoryProvider);
  final result = await repo.getTransactions(page: page);
  if (result.isSuccess) return result.data!;
  throw Exception(result.error?.message ?? 'Failed to load transactions');
});
