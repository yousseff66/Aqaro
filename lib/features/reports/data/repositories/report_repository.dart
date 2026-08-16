import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/core/api/dio_client.dart';
import 'package:sakan_app/core/constants/api_constants.dart';
import 'package:sakan_app/features/reports/data/models/report_model.dart';

final reportRepositoryProvider = Provider((ref) => ReportRepository(ref.read(dioProvider)));

class ReportRepository {
  final Dio _dio;

  ReportRepository(this._dio);

  Future<List<PropertyReport>> getMyReports() async {
    final response = await _dio.get(ApiConstants.myReports);
    final data = response.data;
    List results = [];
    if (data is Map && data.containsKey('results')) {
      results = data['results'] as List;
    } else if (data is List) {
      results = data;
    }
    return results.map((json) => PropertyReport.fromJson(json)).toList();
  }

  Future<List<PropertyReport>> getAllReports() async {
    final response = await _dio.get(ApiConstants.reports);
    final data = response.data;
    List results = [];
    if (data is Map && data.containsKey('results')) {
      results = data['results'] as List;
    } else if (data is List) {
      results = data;
    }
    return results.map((json) => PropertyReport.fromJson(json)).toList();
  }

  Future<void> createReport(Map<String, dynamic> data) async {
    await _dio.post(ApiConstants.reports, data: data);
  }

  Future<void> updateReportStatus(String id, String status, {String? reviewNote}) async {
    await _dio.patch('${ApiConstants.reports}/$id', data: {
      'status': status,
      if (reviewNote != null) 'reviewNote': reviewNote,
    });
  }

  Future<void> deleteReportedProperty(String id) async {
    await _dio.delete('${ApiConstants.reports}/$id/property');
  }
}
