import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/features/notifications/data/models/notification_model.dart';
import 'package:sakan_app/features/notifications/data/repositories/notification_repository.dart';

final myNotificationsProvider = FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  return ref.read(notificationRepositoryProvider).getMyNotifications();
});

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  return ref.read(notificationRepositoryProvider).getUnreadCount();
});

class NotificationActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final NotificationRepository _repository;
  final Ref _ref;

  NotificationActionsNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  void _refreshAll() {
    _ref.invalidate(myNotificationsProvider);
    _ref.invalidate(unreadCountProvider);
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      _refreshAll();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAllAsRead() async {
    state = const AsyncValue.loading();
    try {
      await _repository.markAllAsRead();
      _refreshAll();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _repository.deleteNotification(id);
      _refreshAll();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final notificationActionsProvider =
StateNotifierProvider.autoDispose<NotificationActionsNotifier, AsyncValue<void>>((ref) {
  return NotificationActionsNotifier(ref.read(notificationRepositoryProvider), ref);
});