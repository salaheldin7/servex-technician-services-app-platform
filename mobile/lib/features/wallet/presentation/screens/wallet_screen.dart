import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/main_scaffold.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/providers/wallet_providers.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final balanceAsync = ref.watch(walletBalanceProvider);
    final transactionsAsync = ref.watch(walletTransactionsProvider(1));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              final role = ref.read(authStateProvider).user?.role;
              context.go(role == 'technician' ? '/technician' : '/home');
            }
          },
        ),
        title: Text(l10n.wallet),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(walletBalanceProvider);
          ref.invalidate(walletTransactionsProvider(1));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: Responsive.pagePadding(context),
          child: ResponsiveCenter(
            maxWidth: Responsive.maxContentWidth(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Balance card with gradient
                balanceAsync.when(
                  data: (wallet) => Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB)
                              .withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                  Icons
                                      .account_balance_wallet_rounded,
                                  color: Colors.white
                                      .withValues(alpha: 0.8),
                                  size: 20),
                              const SizedBox(width: 8),
                              Text(
                                l10n.balance,
                                style: TextStyle(
                                    color: Colors.white
                                        .withValues(alpha: 0.8),
                                    fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '\$${wallet.balance.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Responsive.value<double>(
                                  context,
                                  mobile: 40,
                                  tablet: 48),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (wallet.debt > 0) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red
                                    .withValues(alpha: 0.2),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Debt: \$${wallet.debt.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: wallet.balance > 0
                                  ? () => _showWithdrawDialog(
                                      context,
                                      ref,
                                      wallet.balance)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor:
                                    AppTheme.primaryColor,
                              ),
                              child: Text(l10n.withdraw,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  loading: () => const SizedBox(
                      height: 200, child: LoadingWidget()),
                  error: (e, _) => ErrorDisplayWidget(
                    message: e.toString(),
                    onRetry: () =>
                        ref.invalidate(walletBalanceProvider),
                  ),
                ),
                const SizedBox(height: 24),

                // Transactions
                Text(
                  l10n.transactions,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                transactionsAsync.when(
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return const EmptyStateWidget(
                        icon: Icons.receipt_long_outlined,
                        title: 'No transactions',
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: tx.isCredit
                                ? AppTheme.successColor
                                    .withValues(alpha: 0.1)
                                : AppTheme.errorColor
                                    .withValues(alpha: 0.1),
                            child: Icon(
                              tx.isCredit
                                  ? Icons
                                      .arrow_downward_rounded
                                  : Icons
                                      .arrow_upward_rounded,
                              color: tx.isCredit
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor,
                            ),
                          ),
                          title: Text(
                              _transactionLabel(tx.type)),
                          subtitle: Text(
                            '${tx.createdAt.day}/${tx.createdAt.month}/${tx.createdAt.year}',
                            style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12),
                          ),
                          trailing: Text(
                            '${tx.isCredit ? '+' : '-'}\$${tx.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: tx.isCredit
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const LoadingWidget(),
                  error: (e, _) =>
                      ErrorDisplayWidget(message: e.toString()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _transactionLabel(String type) {
    switch (type) {
      case 'job_credit':
        return 'Job Payment';
      case 'commission':
        return 'Platform Commission';
      case 'withdrawal':
        return 'Withdrawal';
      case 'penalty':
        return 'Penalty';
      case 'debt':
        return 'Cash Collection Debt';
      case 'debt_payment':
        return 'Debt Payment';
      default:
        return type;
    }
  }

  void _showWithdrawDialog(
      BuildContext context, WidgetRef ref, double maxAmount) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).withdraw),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Available: \$${maxAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount =
                  double.tryParse(controller.text);
              if (amount != null &&
                  amount > 0 &&
                  amount <= maxAmount) {
                Navigator.of(ctx).pop();
                await ref
                    .read(walletRepositoryProvider)
                    .requestWithdrawal(amount);
                ref.invalidate(walletBalanceProvider);
                ref.invalidate(
                    walletTransactionsProvider(1));
              }
            },
            child:
                Text(AppLocalizations.of(context).confirm),
          ),
        ],
      ),
    );
  }
}
