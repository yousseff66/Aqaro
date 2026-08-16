import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/features/properties/data/models/property_model.dart';
import 'package:sakan_app/features/properties/data/repositories/property_repository.dart';

final homePurposeFilterProvider = StateProvider<String?>((ref) => null); // null = All

final propertyListProvider = StateNotifierProvider<PropertyListNotifier, AsyncValue<List<Property>>>((ref) {
  final notifier = PropertyListNotifier(ref.read(propertyRepositoryProvider));
  // Initial fetch for home screen with refresh: true to ensure loading state
  notifier.fetchProperties(refresh: true);
  return notifier;
});

final searchResultsProvider = StateNotifierProvider.autoDispose<PropertyListNotifier, AsyncValue<List<Property>>>((ref) {
  final notifier = PropertyListNotifier(ref.read(propertyRepositoryProvider));
  // Fetch all properties by default when the search screen is opened
  notifier.fetchProperties(refresh: true);
  return notifier;
});

class PropertyListNotifier extends StateNotifier<AsyncValue<List<Property>>> {
  final PropertyRepository _repository;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  PropertyListNotifier(
    this._repository, {
    AsyncValue<List<Property>>? initialState,
  }) : super(initialState ?? const AsyncValue.loading());

  Future<void> fetchProperties({
    String? city,
    String? governorate,
    double? minPrice,
    double? maxPrice,
    int? bedrooms,
    String? propertyType,
    String? search,
    String? sort,
    String? listingPurpose,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      state = const AsyncValue.loading();
    }

    if (!_hasMore) return;

    try {
      final result = await _repository.getProperties(
        page: _currentPage,
        city: city,
        governorate: governorate,
        minPrice: minPrice,
        maxPrice: maxPrice,
        bedrooms: bedrooms,
        propertyType: propertyType,
        search: search,
        sort: sort,
        listingPurpose: listingPurpose,
      );

      final List<Property> properties = result['results'];
      final int totalPages = result['pages'];

      // Sort properties so featured ones are always on top
      properties.sort((a, b) {
        if (a.isFeatured && !b.isFeatured) return -1;
        if (!a.isFeatured && b.isFeatured) return 1;
        return 0;
      });

      if (refresh) {
        state = AsyncValue.data(properties);
      } else {
        final currentList = state.value ?? [];
        final newList = [...currentList, ...properties];
        
        // Re-sort the entire list to ensure featured items stay at the top even after pagination
        newList.sort((a, b) {
          if (a.isFeatured && !b.isFeatured) return -1;
          if (!a.isFeatured && b.isFeatured) return 1;
          return 0;
        });
        
        state = AsyncValue.data(newList);
      }

      _currentPage++;
      _hasMore = _currentPage <= totalPages;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    await fetchProperties();
    _isLoadingMore = false;
  }
}

final propertyDetailsProvider = FutureProvider.family<Property, String>((ref, id) async {
  return ref.read(propertyRepositoryProvider).getPropertyById(id);
});

final myPropertiesProvider = FutureProvider<List<Property>>((ref) async {
  return ref.read(propertyRepositoryProvider).getMyProperties();
});

final featuredPropertiesProvider = FutureProvider<List<Property>>((ref) async {
  final purpose = ref.watch(homePurposeFilterProvider);
  final result = await ref.read(propertyRepositoryProvider).getProperties(
        featured: true,
        limit: 5,
        listingPurpose: purpose,
      );
  return result['results'] as List<Property>;
});
