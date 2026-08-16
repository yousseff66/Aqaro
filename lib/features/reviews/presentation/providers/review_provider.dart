import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/features/reviews/data/models/review_model.dart';
import 'package:sakan_app/features/reviews/data/repositories/review_repository.dart';

final userReviewsProvider = FutureProvider.family<List<Review>, String>((ref, userId) async {
  return ref.read(reviewRepositoryProvider).getUserReviews(userId);
});

final userRatingProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  return ref.read(reviewRepositoryProvider).getUserRating(userId);
});

class ReviewSubmitNotifier extends StateNotifier<AsyncValue<void>> {
  final ReviewRepository _repository;
  final Ref _ref;

  ReviewSubmitNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> submit({
    required String propertyId,
    required int rating,
    String? comment,
    required String ownerId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createReview(
        propertyId: propertyId,
        rating: rating,
        comment: comment,
      );
      
      // Invalidate both lists and rating to refresh UI
      _ref.invalidate(userReviewsProvider(ownerId));
      _ref.invalidate(userRatingProvider(ownerId));
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final reviewSubmitProvider = StateNotifierProvider.autoDispose<ReviewSubmitNotifier, AsyncValue<void>>((ref) {
  return ReviewSubmitNotifier(ref.read(reviewRepositoryProvider), ref);
});
