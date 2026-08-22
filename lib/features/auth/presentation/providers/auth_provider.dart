import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/core/api/dio_client.dart';
import 'package:sakan_app/core/storage/storage_service.dart';
import 'package:sakan_app/shared/models/user_model.dart';
import 'package:dio/dio.dart';
import 'package:sakan_app/core/constants/api_constants.dart';
import 'package:sakan_app/core/services/push_notification_service.dart';
import 'dart:convert';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final bool isGuest;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.isGuest = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    bool? isGuest,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isGuest: isGuest ?? this.isGuest,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  AuthNotifier(this._ref) : super(AuthState()) {
    _checkAuth();
  }

  void skipLogin() {
    state = state.copyWith(isGuest: true, isAuthenticated: false);
  }

  Future<void> _checkAuth() async {
    state = state.copyWith(isLoading: true);
    final token = await _ref.read(storageServiceProvider).getToken();
    if (token != null) {
      try {
        final response = await _ref.read(dioProvider).get(ApiConstants.me);
        // Map the response data to a User object
        final user = User.fromJson(response.data);
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
          isGuest: false,
        );
        // Initialize notifications on auto-login
        _ref.read(pushNotificationServiceProvider).initialize();
      } catch (e) {
        await _ref.read(storageServiceProvider).removeToken();
        state = state.copyWith(isLoading: false, isAuthenticated: false, user: null);
      }
    } else {
      state = state.copyWith(isLoading: false, isAuthenticated: false, user: null);
    }
  }

  Future<void> _handleAuthResponse(dynamic data) async {
    final Map<String, dynamic> map;
    if (data is Map<String, dynamic>) {
      map = data;
    } else if (data is String) {
      map = jsonDecode(data);
    } else if (data is List && data.isNotEmpty) {
      // Handle rare case where response might be wrapped in a list
      map = data.first as Map<String, dynamic>;
    } else {
      throw Exception('Unexpected response format: ${data.runtimeType}');
    }

    final token = map['token'];
    final user = User.fromJson(map['user']);

    await _ref.read(storageServiceProvider).setToken(token);

    state = state.copyWith(
      isLoading: false,
      isAuthenticated: true,
      user: user,
      isGuest: false,
    );

    // Initialize notifications after successful auth
    _ref.read(pushNotificationServiceProvider).initialize();
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _ref.read(dioProvider).post(
            ApiConstants.login,
            data: {'email': email, 'password': password},
          );

      await _handleAuthResponse(response.data);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'Login failed',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<void> register(String name, String email, String password, String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _ref.read(dioProvider).post(
            ApiConstants.register,
            data: {
              'name': name,
              'email': email,
              'password': password,
              'phone': phone,
            },
          );

      await _handleAuthResponse(response.data);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'Registration failed',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<void> logout() async {
    // 1. تحديث الحالة فوراً ليتم التوجيه لشاشة تسجيل الدخول دون تأخير
    state = AuthState(isAuthenticated: false, user: null, isLoading: false);

    // 2. مسح التوكن محلياً
    await _ref.read(storageServiceProvider).removeToken();

    // 3. محاولة مسح التوكن من السيرفر في الخلفية
    try {
      _ref.read(pushNotificationServiceProvider).unregisterDevice().catchError((e) {
        debugPrint('Logout background unregister failed: $e');
      });
    } catch (e) {
      debugPrint('Logout cleanup error: $e');
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      await _ref.read(dioProvider).post(ApiConstants.forgotPassword, data: {'email': email});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> resetPassword(String email, String code, String newPassword) async {
    try {
      await _ref.read(dioProvider).post(ApiConstants.resetPassword, data: {
        'email': email,
        'code': code,
        'newPassword': newPassword,
      });
      return {'success': true};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'Failed to reset password'};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> changePhone(String newPhone) async {
    try {
      final response = await _ref.read(dioProvider).patch(ApiConstants.updatePhone, data: {'phone': newPhone});
      // Update local user data after success
      final updatedUser = User.fromJson(response.data);
      state = state.copyWith(user: updatedUser);
      return {'success': true};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'Failed to update phone'};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _ref.read(dioProvider).delete(ApiConstants.deleteAccount);
      
      // Logout locally
      await _ref.read(storageServiceProvider).removeToken();
      state = AuthState(isAuthenticated: false, user: null, isLoading: false);
      
      return {'success': true};
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false);
      return {'success': false, 'message': e.response?.data['message'] ?? 'Failed to delete account'};
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }
}
