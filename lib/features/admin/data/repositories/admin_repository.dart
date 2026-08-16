import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/core/api/dio_client.dart';
import 'package:sakan_app/core/constants/api_constants.dart';
import 'package:sakan_app/features/admin/data/models/admin_stats_model.dart';
import 'package:sakan_app/features/properties/data/models/property_model.dart';
import 'package:sakan_app/features/payment/data/models/payment_model.dart';
import 'package:sakan_app/shared/models/user_model.dart';

final adminRepositoryProvider = Provider((ref) => AdminRepository(ref.read(dioProvider)));

class AdminRepository {
  final Dio _dio;

  AdminRepository(this._dio);

  Future<AdminStats> getDashboardStats({DateTime? startDate, DateTime? endDate}) async {
    final response = await _dio.get(
      ApiConstants.adminDashboard,
      queryParameters: {
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      },
    );
    return AdminStats.fromJson(response.data);
  }

  Future<List<User>> getAllUsers() async {
    final response = await _dio.get(ApiConstants.adminUsers);
    final data = response.data;
    if (data is Map && data.containsKey('results')) {
      return (data['results'] as List).map((json) => User.fromJson(json)).toList();
    }
    if (data is List) {
      return data.map((json) => User.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<Property>> getPendingProperties() async {
    final response = await _dio.get(ApiConstants.adminPendingProperties);
    final data = response.data;
    if (data is Map && data.containsKey('results')) {
      return (data['results'] as List).map((json) => Property.fromJson(json)).toList();
    }
    if (data is List) {
      return data.map((json) => Property.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> updatePropertyStatus(String id, String status, {String? reviewNote}) async {
    // بناء المسار /admin/properties/$id/status
    await _dio.patch('/admin/properties/$id/status', data: {
      'status': status,
      if (reviewNote != null) 'reviewNote': reviewNote,
    });
  }

  Future<List<Payment>> getAllPayments({String? status}) async {
    final response = await _dio.get(
      '${ApiConstants.payments}/admin',
      queryParameters: {if (status != null) 'status': status},
    );
    final data = response.data;
    if (data is Map && data.containsKey('results')) {
      return (data['results'] as List).map((json) => Payment.fromJson(json)).toList();
    }
    if (data is List) {
      return data.map((json) => Payment.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> approvePayment(String id, {String? reviewNote}) async {
    try {
      await _dio.patch('${ApiConstants.payments}/$id/approve', data: {
        if (reviewNote != null) 'reviewNote': reviewNote,
      });
    } on DioException catch (e) {
      debugPrint('=== approvePayment ERROR ===');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Data: ${e.response?.data}');
      debugPrint('============================');
      throw 'BACKEND_ERROR: ${e.response?.data}';
    }
  }

  Future<void> rejectPayment(String id, {String? reviewNote}) async {
    try {
      await _dio.patch('${ApiConstants.payments}/$id/reject', data: {
        if (reviewNote != null) 'reviewNote': reviewNote,
      });
    } on DioException catch (e) {
      debugPrint('=== rejectPayment ERROR ===');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Data: ${e.response?.data}');
      debugPrint('===========================');
      throw 'BACKEND_ERROR: ${e.response?.data}';
    }
  }

  Future<void> updateUserRole(String id, String role) async {
    await _dio.patch('/admin/users/$id/role', data: {'role': role});
  }

  Future<bool> toggleBanUser(String id) async {
    final response = await _dio.patch('/admin/users/$id/ban');
    return response.data['isBanned'] as bool;
  }

  Future<void> deleteUser(String id) async {
    await _dio.delete('/admin/users/$id');
  }

  Future<Map<String, dynamic>> sendPushNotification({
    required String title,
    required String body,
    required String category,
  }) async {
    final response = await _dio.post('/admin/notifications/push', data: {
      'title': title,
      'body': body,
      'category': category,
    });
    return response.data;
  }
}
