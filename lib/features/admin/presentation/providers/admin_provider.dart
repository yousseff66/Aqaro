import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/features/admin/data/models/admin_stats_model.dart';
import 'package:sakan_app/features/admin/data/repositories/admin_repository.dart';
import 'package:sakan_app/features/properties/data/models/property_model.dart';
import 'package:sakan_app/features/payment/data/models/payment_model.dart';
import 'package:sakan_app/shared/models/user_model.dart';

class DashboardDateRange {
  final DateTime? start;
  final DateTime? end;
  const DashboardDateRange({this.start, this.end});
}

final dashboardDateRangeProvider = StateProvider<DashboardDateRange>((ref) => const DashboardDateRange());

final adminStatsProvider = FutureProvider.autoDispose<AdminStats>((ref) async {
  final range = ref.watch(dashboardDateRangeProvider);
  return ref.read(adminRepositoryProvider).getDashboardStats(startDate: range.start, endDate: range.end);
});

final pendingPropertiesProvider = FutureProvider.autoDispose<List<Property>>((ref) async {
  return ref.read(adminRepositoryProvider).getPendingProperties();
});

final allPaymentsProvider = FutureProvider.autoDispose<List<Payment>>((ref) async {
  return ref.read(adminRepositoryProvider).getAllPayments();
});

final allUsersProvider = FutureProvider.autoDispose<List<User>>((ref) async {
  return ref.read(adminRepositoryProvider).getAllUsers();
});

class AdminActionNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminRepository _repository;
  final Ref _ref;
  AdminActionNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  void _refreshAll() {
    _ref.invalidate(adminStatsProvider);
    _ref.invalidate(pendingPropertiesProvider);
    _ref.invalidate(allPaymentsProvider);
    _ref.invalidate(allUsersProvider);
  }

  Future<void> updatePropertyStatus(String id, String status, {String? reviewNote}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updatePropertyStatus(id, status, reviewNote: reviewNote);
      _refreshAll();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> approvePayment(String id, {String? reviewNote}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.approvePayment(id, reviewNote: reviewNote);
      _refreshAll();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> rejectPayment(String id, {String? reviewNote}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.rejectPayment(id, reviewNote: reviewNote);
      _refreshAll();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateUserRole(String id, String role) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateUserRole(id, role);
      _ref.invalidate(allUsersProvider);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleBanUser(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.toggleBanUser(id);
      _ref.invalidate(allUsersProvider);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteUser(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteUser(id);
      _ref.invalidate(allUsersProvider);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final adminActionProvider = StateNotifierProvider<AdminActionNotifier, AsyncValue<void>>((ref) {
  return AdminActionNotifier(ref.read(adminRepositoryProvider), ref);
});
