import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/features/payment/data/models/payment_model.dart';
import 'package:sakan_app/features/payment/data/repositories/payment_repository.dart';
import 'package:sakan_app/features/admin/data/models/settings_model.dart';

final paymentMethodsProvider = FutureProvider<PlatformSettings>((ref) async {
  return ref.read(paymentRepositoryProvider).getPaymentMethods();
});

final myPaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  return ref.read(paymentRepositoryProvider).getMyPayments();
});

class PaymentNotifier extends StateNotifier<AsyncValue<Payment?>> {
  final PaymentRepository _repository;
  PaymentNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> processPayment(FormData data) async {
    state = const AsyncValue.loading();
    try {
      final payment = await _repository.createPayment(data);
      state = AsyncValue.data(payment);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final paymentProcessProvider = StateNotifierProvider<PaymentNotifier, AsyncValue<Payment?>>((ref) {
  return PaymentNotifier(ref.read(paymentRepositoryProvider));
});
