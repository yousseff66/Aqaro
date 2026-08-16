import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/core/api/dio_client.dart';
import 'package:sakan_app/core/constants/api_constants.dart';
import 'package:sakan_app/features/properties/data/models/property_model.dart';

final propertyRepositoryProvider = Provider((ref) => PropertyRepository(ref.read(dioProvider)));

class PropertyRepository {
  final Dio _dio;

  PropertyRepository(this._dio);

  Future<Map<String, dynamic>> getProperties({
    int page = 1,
    int limit = 10,
    String? city,
    String? governorate,
    double? minPrice,
    double? maxPrice,
    int? bedrooms,
    String? propertyType,
    String? search,
    String? sort,
    bool? featured,
    String? listingPurpose,
  }) async {
    final queryParameters = {
      'page': page,
      'limit': limit,
      if (city != null) 'city': city,
      if (governorate != null) 'governorate': governorate,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (bedrooms != null) 'bedrooms': bedrooms,
      if (propertyType != null) 'propertyType': propertyType,
      if (search != null) 'search': search,
      if (sort != null) 'sort': sort,
      if (featured != null) 'featured': featured,
      if (listingPurpose != null) 'listingPurpose': listingPurpose,
    };

    final response = await _dio.get(ApiConstants.properties, queryParameters: queryParameters);

    final data = response.data;
    List results = [];
    if (data is Map && data.containsKey('results')) {
      results = data['results'] as List;
    } else if (data is List) {
      results = data;
    }

    return {
      'total': data is Map ? data['total'] : results.length,
      'page': data is Map ? data['page'] : 1,
      'pages': data is Map ? data['pages'] : 1,
      'results': results.map((json) => Property.fromJson(json)).toList(),
    };
  }

  Future<Property> getPropertyById(String id) async {
    final response = await _dio.get('${ApiConstants.properties}/$id');
    return Property.fromJson(response.data);
  }

  Future<List<Property>> getMyProperties() async {
    final response = await _dio.get(
      ApiConstants.myProperties,
      queryParameters: {'limit': 100, 'page': 1},
    );
    final data = response.data;
    List results = [];
    if (data is Map && data.containsKey('results')) {
      results = data['results'] as List;
    } else if (data is List) {
      results = data;
    }
    return results.map((json) => Property.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> getMyPropertyStats() async {
    final response = await _dio.get(ApiConstants.propertyStats);
    return response.data;
  }

  Future<Property> createProperty(FormData data) async {
    final response = await _dio.post(ApiConstants.properties, data: data);
    return Property.fromJson(response.data);
  }

  // تحديث الحقول النصية فقط (مش الصور) - PATCH /properties/:id
  Future<Property> updateProperty(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('${ApiConstants.properties}/$id', data: data);
    return Property.fromJson(response.data);
  }

  // تحديث الصور فقط (إضافة جديدة + حذف قديمة) - PATCH /properties/:id/images
  // ده endpoint منفصل تمامًا عن updateProperty، زي ما الباك متوقع بالظبط
  Future<Property> updatePropertyImages(
      String id, {
        required List<MultipartFile> newImages,
        required List<String> removedImagePublicIds,
      }) async {
    final formData = FormData();
    if (removedImagePublicIds.isNotEmpty) {
      formData.fields.add(MapEntry('removedImages', jsonEncode(removedImagePublicIds)));
    }
    for (final img in newImages) {
      formData.files.add(MapEntry('images', img));
    }
    final response = await _dio.patch('${ApiConstants.properties}/$id/images', data: formData);
    return Property.fromJson(response.data);
  }

  Future<void> deleteProperty(String id) async {
    await _dio.delete('${ApiConstants.properties}/$id');
  }
}