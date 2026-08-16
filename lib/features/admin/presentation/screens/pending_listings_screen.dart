import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/core/localization/app_localizations.dart';
import 'package:sakan_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sakan_app/features/properties/presentation/screens/property_detail_screen.dart';
import 'package:sakan_app/core/utils/formatters.dart';

class PendingListingsScreen extends ConsumerWidget {
  const PendingListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingPropertiesProvider);
    final actionState = ref.watch(adminActionProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(pendingPropertiesProvider.future),
      child: pendingAsync.when(
          data: (properties) {
            if (properties.isEmpty) {
              return Center(child: Text(context.translate('no_pending_listings')));
            }
            return ListView.builder(
              itemCount: properties.length,
              itemBuilder: (context, index) {
                final property = properties[index];
                return ListTile(
                  leading: property.images.isNotEmpty
                      ? Image.network(property.images[0], width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.home),
                  title: Text(property.title),
                  subtitle: Text('${AppFormatters.formatCurrency(property.price)} ${context.translate('egp')} • ${property.owner?.name ?? 'Unknown'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: actionState.isLoading ? null : () => _handleAction(context, ref, property.id!, 'Published'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: actionState.isLoading ? null : () => _showRejectDialog(context, ref, property.id!),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PropertyDetailScreen(propertyId: property.id!, initialProperty: property),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String id, String status, {String? reviewNote}) async {
    await ref.read(adminActionProvider.notifier).updatePropertyStatus(id, status, reviewNote: reviewNote);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Listing $status')));
    }
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref, String id) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.translate('reject_listing')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: context.translate('rejection_reason')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.translate('cancel'))),
          TextButton(
            onPressed: () {
              _handleAction(context, ref, id, 'Rejected', reviewNote: controller.text.trim().isEmpty ? null : controller.text.trim());
              Navigator.pop(context);
            },
            child: Text(context.translate('reject'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
