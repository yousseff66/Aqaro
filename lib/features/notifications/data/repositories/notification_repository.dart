import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/core/api/dio_client.dart';
import 'package:sakan_app/core/constants/api_constants.dart';
import 'package:sakan_app/features/notifications/data/models/notification_model.dart';

final notificationRepositoryProvider = Provider((ref) => NotificationRepository(ref.read(dioProvider)));

class NotificationRepository {
  final Dio _dio;

  NotificationRepository(this._dio);

  Future<List<AppNotification>> getMyNotifications() async {
    final response = await _dio.get(ApiConstants.notifications);
    final data = response.data;
    List results = [];
    if (data is Map && data.containsKey('results')) {
      results = data['results'] as List;
    } else if (data is List) {
      results = data;
    }
    return results.map((json) => AppNotification.fromJson(json)).toList();
  }

  Future<int> getUnreadCount() async {
    final response = await _dio.get(ApiConstants.unreadNotificationsCount);
    return response.data['count'] as int? ?? 0;
  }

  Future<void> markAsRead(String id) async {
    await _dio.patch('${ApiConstants.notifications}/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _dio.patch('${ApiConstants.notifications}/read-all');
  }

  Future<void> deleteNotification(String id) async {
    await _dio.delete('${ApiConstants.notifications}/$id');
  }
}