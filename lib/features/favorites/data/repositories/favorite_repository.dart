import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/core/api/dio_client.dart';
import 'package:sakan_app/core/constants/api_constants.dart';
import 'package:sakan_app/features/properties/data/models/property_model.dart';

final favoriteRepositoryProvider = Provider((ref) => FavoriteRepository(ref.read(dioProvider)));

class FavoriteRepository {
  final Dio _dio;
  FavoriteRepository(this._dio);

  Future<void> addFavorite(String propertyId) async {
    await _dio.post('${ApiConstants.favorites}/$propertyId');
  }

  Future<void> removeFavorite(String propertyId) async {
    await _dio.delete('${ApiConstants.favorites}/$propertyId');
  }

  Future<List<Property>> getMyFavorites() async {
    final response = await _dio.get(ApiConstants.favorites);
    final data = response.data;
    if (data is List) {
      return data.map((json) => Property.fromJson(json)).toList();
    }
    return [];
  }

  Future<int> getFavoritesCount() async {
    final response = await _dio.get(ApiConstants.favoritesCount);
    return response.data['count'] as int;
  }
}
