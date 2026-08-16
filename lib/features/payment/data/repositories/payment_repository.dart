import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/core/api/dio_client.dart';
import 'package:sakan_app/core/constants/api_constants.dart';
import 'package:sakan_app/features/payment/data/models/payment_model.dart';
import 'package:sakan_app/features/admin/data/models/settings_model.dart';

final paymentRepositoryProvider = Provider((ref) => PaymentRepository(ref.read(dioProvider)));

class PaymentRepository {
  final Dio _dio;

  PaymentRepository(this._dio);

  Future<List<Payment>> getMyPayments() async {
    debugPrint('=== getMyPayments: BEFORE request ===');
    final response = await _dio.get(ApiConstants.myPayments);
    debugPrint('=== getMyPayments: AFTER request ===');
    debugPrint('Response type: ${response.data.runtimeType}');
    debugPrint('Response data: ${response.data}');

    final data = response.data;
    List rawList = [];

    if (data is Map && data.containsKey('results')) {
      rawList = data['results'] as List;
    } else if (data is List) {
      rawList = data;
    }

    debugPrint('=== getMyPayments: rawList length: ${rawList.length} ===');

    final List<Payment> result = [];
    for (int i = 0; i < rawList.length; i++) {
      debugPrint('=== Parsing payment index $i ===');
      debugPrint('Raw JSON: ${rawList[i]}');
      try {
        final payment = Payment.fromJson(rawList[i]);
        debugPrint('=== Successfully parsed index $i ===');
        result.add(payment);
      } catch (e, stack) {
        debugPrint('=== FAILED to parse index $i ===');
        debugPrint('Error: $e');
        debugPrint('Stack: $stack');
        rethrow;
      }
    }

    debugPrint('=== getMyPayments: DONE, total parsed: ${result.length} ===');
    return result;
  }

  Future<PlatformSettings> getPaymentMethods() async {
    final response = await _dio.get(ApiConstants.paymentMethods);
    return PlatformSettings.fromJson(response.data);
  }

  Future<Payment> createPayment(FormData data) async {
    final response = await _dio.post(ApiConstants.payments, data: data);
    return Payment.fromJson(response.data);
  }

  Future<void> verifyPayment(String transactionId) async {
    await _dio.post('${ApiConstants.payments}/verify', data: {'transactionId': transactionId});
  }
}
