import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/core/api/dio_client.dart';
import 'package:sakan_app/core/constants/api_constants.dart';
import 'package:sakan_app/features/admin/data/models/settings_model.dart';

final settingsRepositoryProvider = Provider((ref) => SettingsRepository(ref.read(dioProvider)));

class SettingsRepository {
  final Dio _dio;

  SettingsRepository(this._dio);

  Future<PlatformSettings> getSettings() async {
    final response = await _dio.get(ApiConstants.adminSettings);
    final data = response.data;
    if (data is Map && data.containsKey('results') && data['results'] != null) {
      return PlatformSettings.fromJson(data['results']);
    }
    return PlatformSettings.fromJson(data);
  }

  Future<PlatformSettings> updateSettings(Map<String, dynamic> data) async {
    final response = await _dio.patch(ApiConstants.adminSettings, data: data);
    return PlatformSettings.fromJson(response.data);
  }
}
