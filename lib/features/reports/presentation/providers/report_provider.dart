import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/features/reports/data/repositories/report_repository.dart';

final reportProvider = StateNotifierProvider.autoDispose<ReportNotifier, AsyncValue<void>>((ref) {
  return ReportNotifier(ref.watch(reportRepositoryProvider));
});

class ReportNotifier extends StateNotifier<AsyncValue<void>> {
  final ReportRepository _repository;

  ReportNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> submitReport({
    required String propertyId,
    required String reason,
    String description = '',
  }) async {
    state = const AsyncValue.loading();
    try {
      final data = {
        'propertyId': propertyId,
        'reason': reason,
      };
      if (description.isNotEmpty) {
        data['description'] = description;
      }
      await _repository.createReport(data);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
