import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/core/localization/app_localizations.dart';
import 'package:sakan_app/features/properties/data/repositories/property_repository.dart';
import 'package:sakan_app/features/properties/data/models/property_model.dart';
import 'package:sakan_app/features/properties/presentation/screens/create_listing_screen.dart';
import 'package:sakan_app/features/properties/presentation/screens/property_detail_screen.dart';
import 'package:sakan_app/features/payment/presentation/screens/payment_screen.dart';
import 'package:sakan_app/core/utils/formatters.dart';

import 'package:sakan_app/shared/widgets/mode_toggle_appbar.dart';

import 'package:sakan_app/shared/widgets/guest_prompt_card.dart';
import 'package:sakan_app/features/auth/presentation/providers/auth_provider.dart';

final myPropertiesFutureProvider = FutureProvider.autoDispose<List<Property>>((ref) async {
  return ref.read(propertyRepositoryProvider).getMyProperties();
});

final myPropertyStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(propertyRepositoryProvider).getMyPropertyStats();
});

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isGuest) {
      return Scaffold(
        appBar: ModeToggleAppBar(
          title: context.translate('my_listings'),
        ),
        body: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: GuestPromptCard(),
          ),
        ),
      );
    }

    final propertiesAsync = ref.watch(myPropertiesFutureProvider);
    final statsAsync = ref.watch(myPropertyStatsProvider);

    return Scaffold(
      appBar: ModeToggleAppBar(
        title: context.translate('my_listings'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myPropertiesFutureProvider);
          ref.invalidate(myPropertyStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              statsAsync.when(
                data: (stats) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(label: context.translate('total'), value: stats['total'] ?? 0),
                      _StatItem(label: context.translate('published'), value: stats['published'] ?? 0, color: Colors.green),
                      _StatItem(label: context.translate('pending'), value: stats['pending'] ?? 0, color: Colors.orange),
                      _StatItem(label: context.translate('rejected'), value: stats['rejected'] ?? 0, color: Colors.red),
                    ],
                  ),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => const SizedBox.shrink(),
              ),
              propertiesAsync.when(
                data: (properties) {
                  if (properties.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          children: [
                            const Icon(Icons.list_alt, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(context.translate('no_listings_yet')),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: properties.length,
                    itemBuilder: (context, index) {
                      final property = properties[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: property.images.isNotEmpty
                              ? Image.network(property.images[0], width: 60, height: 60, fit: BoxFit.cover)
                              : Container(width: 60, height: 60, color: Colors.grey[300]),
                          title: Text(property.title),
                          subtitle: Text(
                            '${AppFormatters.formatCurrency(property.price)} ${context.translate('egp')} • ${context.translate(property.status.toLowerCase()) ?? property.status}',
                            style: TextStyle(
                              color: property.status == 'PendingPayment' ? Colors.red : null,
                              fontWeight: property.status == 'PendingPayment' ? FontWeight.bold : null,
                            ),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PropertyDetailScreen(
                                propertyId: property.id!,
                                initialProperty: property,
                              ),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (property.status == 'PendingPayment')
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PaymentScreen(
                                          property: property,
                                          isFeatured: property.listingType == 'Featured',
                                        ),
                                      ),
                                    ).then((_) {
                                      ref.invalidate(myPropertiesFutureProvider);
                                      ref.invalidate(myPropertyStatsProvider);
                                    });
                                  },
                                  icon: const Icon(Icons.payment, size: 18, color: Colors.red),
                                  label: Text(
                                    context.translate('complete_payment') ?? 'Complete Payment',
                                    style: const TextStyle(color: Colors.red, fontSize: 12),
                                  ),
                                ),
                              PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(value: 'edit', child: Text(context.translate('edit'))),
                                  PopupMenuItem(value: 'delete', child: Text(context.translate('delete'))),
                                ],
                                onSelected: (val) async {
                                  if (val == 'edit') {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CreateListingScreen(existingProperty: property),
                                      ),
                                    );
                                    ref.invalidate(myPropertiesFutureProvider);
                                    ref.invalidate(myPropertyStatsProvider);
                                  } else if (val == 'delete') {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(context.translate('delete_listing')),
                                        content: Text(context.translate('delete_confirmation')),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.translate('cancel'))),
                                          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(context.translate('delete'), style: const TextStyle(color: Colors.red))),
                                        ],
                                      ),
                                    );

                                    if (confirmed == true) {
                                      try {
                                        await ref.read(propertyRepositoryProvider).deleteProperty(property.id!);
                                        ref.invalidate(myPropertiesFutureProvider);
                                        ref.invalidate(myPropertyStatsProvider);
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                        }
                                      }
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateListingScreen()),
          );
        },
        label: Text(context.translate('add_listing')),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int value;
  final Color? color;

  const _StatItem({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color ?? Theme.of(context).primaryColor,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
