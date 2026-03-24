import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/address_repository.dart';
import '../../domain/providers/address_providers.dart';

class AddressesListScreen extends ConsumerWidget {
  const AddressesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.translate('my_addresses')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_rounded),
            tooltip: l10n.translate('add_new_address'),
            onPressed: () async {
              await context.push('/addresses/add');
              ref.invalidate(addressesProvider);
            },
          ),
        ],
      ),
      body: addressesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (addresses) {
          if (addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off_rounded,
                      size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No addresses yet',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Add your first address to get started',
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey[400])),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await context.push('/addresses/add');
                      ref.invalidate(addressesProvider);
                    },
                    icon: const Icon(Icons.add),
                    label: Text(l10n.translate('add_new_address')),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final addr = addresses[index];
              return _AddressCard(
                address: addr,
                onSetDefault: () async {
                  final repo = ref.read(addressRepositoryProvider);
                  await repo.setDefault(addr.id);
                  ref.invalidate(addressesProvider);
                  ref.invalidate(defaultAddressProvider);
                },
                onDelete: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Address'),
                      content: Text(
                          'Delete "${addr.label}"? This cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(l10n.translate('cancel')),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.errorColor),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final repo = ref.read(addressRepositoryProvider);
                    await repo.delete(addr.id);
                    ref.invalidate(addressesProvider);
                    ref.invalidate(defaultAddressProvider);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final UserAddress address;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.address,
    required this.onSetDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: address.isDefault
            ? Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: address.isDefault
                        ? AppTheme.primaryColor.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    address.isDefault
                        ? Icons.star_rounded
                        : Icons.location_on_outlined,
                    color: address.isDefault
                        ? AppTheme.primaryColor
                        : Colors.grey[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            address.label,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          if (address.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Default',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryColor)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address.displayAddress,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'default') onSetDefault();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (ctx) => [
                    if (!address.isDefault)
                      const PopupMenuItem(
                        value: 'default',
                        child: Row(
                          children: [
                            Icon(Icons.star_outline, size: 18),
                            SizedBox(width: 8),
                            Text('Set as Default'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (address.floor.isNotEmpty || address.apartment.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 44),
                child: Row(
                  children: [
                    if (address.floor.isNotEmpty) ...[
                      Icon(Icons.layers_outlined,
                          size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text('Floor ${address.floor}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500])),
                      const SizedBox(width: 12),
                    ],
                    if (address.apartment.isNotEmpty) ...[
                      Icon(Icons.door_front_door_outlined,
                          size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text('Apt ${address.apartment}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500])),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
