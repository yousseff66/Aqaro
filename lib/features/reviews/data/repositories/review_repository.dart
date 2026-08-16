import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/core/api/dio_client.dart';
import 'package:sakan_app/core/constants/api_constants.dart';
import 'package:sakan_app/features/reviews/data/models/review_model.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.read(dioProvider));
});

class ReviewRepository {
  final Dio _dio;

  ReviewRepository(this._dio);

  Future<void> createReview({
    required String propertyId,
    required int rating,
    String? comment,
  }) async {
    final Map<String, dynamic> data = {
      'propertyId': propertyId,
      'rating': rating,
    };
    if (comment != null) {
      data['comment'] = comment;
    }

    await _dio.post(ApiConstants.reviews, data: data);
  }

  Future<List<Review>> getUserReviews(String userId) async {
    final response = await _dio.get(ApiConstants.userReviews(userId));
    final List<dynamic> data = response.data;
    return data.map((json) => Review.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> getUserRating(String userId) async {
    final response = await _dio.get(ApiConstants.userRating(userId));
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteReview(String reviewId) async {
    await _dio.delete('${ApiConstants.reviews}/$reviewId');
  }

  Future<void> updateReview({
    required String reviewId,
    required int rating,
    String? comment,
  }) async {
    final Map<String, dynamic> data = {
      'rating': rating,
    };
    if (comment != null) {
      data['comment'] = comment;
    }
    await _dio.patch('${ApiConstants.reviews}/$reviewId', data: data);
  }
}
