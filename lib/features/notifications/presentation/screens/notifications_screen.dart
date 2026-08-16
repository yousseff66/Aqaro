import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:sakan_app/core/localization/app_localizations.dart';
import 'package:sakan_app/features/notifications/data/models/notification_model.dart';
import 'package:sakan_app/features/notifications/presentation/providers/notification_provider.dart';
import 'package:sakan_app/features/properties/presentation/screens/property_detail_screen.dart';

import 'package:sakan_app/shared/widgets/mode_toggle_appbar.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _iconForType(String type) {
    switch (type) {
      case 'PropertyPublished':
        return Icons.check_circle;
      case 'PropertyRejected':
        return Icons.cancel;
      case 'PaymentApproved':
        return Icons.payment;
      case 'PaymentRejected':
        return Icons.money_off;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(BuildContext context, String type) {
    switch (type) {
      case 'PropertyPublished':
      case 'PaymentApproved':
        return Colors.green;
      case 'PropertyRejected':
      case 'PaymentRejected':
        return Colors.red;
      case 'PropertyExpiring':
        return Colors.orange;
      case 'FeaturedExpired':
      case 'PropertyExpired':
        return Colors.blueGrey;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _getTranslatedTitle(BuildContext context, AppNotification notif) {
    // Try to translate the type, if not found use original title
    final typeTranslation = context.translate(notif.type);
    if (typeTranslation != notif.type) {
      return typeTranslation;
    }
    return notif.title;
  }

  String _getTranslatedMessage(BuildContext context, AppNotification notif) {
    switch (notif.type) {
      case 'PropertyPublished':
        return context.translate('notification_property_published_msg');
      case 'PropertyRejected':
        return notif.message.isNotEmpty && notif.message != 'Your property has been rejected by the admin.'
            ? notif.message
            : context.translate('notification_property_rejected_msg');
      case 'PaymentApproved':
        final isRenewal = notif.metadata['isRenewal'] == true;
        return isRenewal
            ? context.translate('notification_payment_approved')
            : context.translate('notification_payment_approved_new');
      case 'PaymentRejected':
        return notif.message.isNotEmpty && notif.message != 'Your payment has been rejected.'
            ? notif.message
            : context.translate('notification_payment_rejected');
      case 'PropertyExpiring':
        return context.translate('notification_property_expiring_msg');
      case 'FeaturedExpired':
        return context.translate('notification_featured_expired_msg');
      case 'PropertyExpired':
        return context.translate('notification_property_expired_msg');
      default:
        return notif.message;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(myNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.translate('notifications'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(notificationActionsProvider.notifier).markAllAsRead();
            },
            child: Text(
              context.translate('mark_all_as_read'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myNotificationsProvider);
          ref.invalidate(unreadCountProvider);
        },
        child: notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.notifications_none, size: 80, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(context.translate('no_notifications')),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return Dismissible(
                  key: ValueKey(notif.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: AlignmentDirectional.centerEnd,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    ref.read(notificationActionsProvider.notifier).deleteNotification(notif.id);
                  },
                  child: ListTile(
                    tileColor: notif.isRead ? null : Theme.of(context).colorScheme.primary.withOpacity(0.08),
                    leading: CircleAvatar(
                      backgroundColor: _colorForType(context, notif.type).withOpacity(0.15),
                      child: Icon(_iconForType(notif.type), color: _colorForType(context, notif.type)),
                    ),
                    title: Text(
                      _getTranslatedTitle(context, notif),
                      style: TextStyle(fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold),
                    ),
                    subtitle: Text(_getTranslatedMessage(context, notif)),
                    trailing: notif.createdAt != null
                        ? Text(
                      intl.DateFormat('dd/MM').format(notif.createdAt!),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    )
                        : null,
                    onTap: () {
                      if (!notif.isRead) {
                        ref.read(notificationActionsProvider.notifier).markAsRead(notif.id);
                      }
                      if (notif.propertyId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PropertyDetailScreen(propertyId: notif.propertyId!),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}