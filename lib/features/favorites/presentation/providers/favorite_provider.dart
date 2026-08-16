import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/features/favorites/data/repositories/favorite_repository.dart';
import 'package:sakan_app/features/properties/data/models/property_model.dart';

final favoritesListProvider = FutureProvider<List<Property>>((ref) async {
  return ref.read(favoriteRepositoryProvider).getMyFavorites();
});

final favoriteIdsProvider = Provider<Set<String>>((ref) {
  final favoritesAsync = ref.watch(favoritesListProvider);
  return favoritesAsync.maybeWhen(
    data: (properties) => properties.map((p) => p.id).whereType<String>().toSet(),
    orElse: () => <String>{},
  );
});

class FavoriteToggleNotifier extends StateNotifier<AsyncValue<void>> {
  final FavoriteRepository _repository;
  final Ref _ref;
  FavoriteToggleNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> toggle(String propertyId, bool isCurrentlyFavorite) async {
    state = const AsyncValue.loading();
    try {
      if (isCurrentlyFavorite) {
        await _repository.removeFavorite(propertyId);
      } else {
        await _repository.addFavorite(propertyId);
      }
      _ref.invalidate(favoritesListProvider);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final favoriteToggleProvider = StateNotifierProvider<FavoriteToggleNotifier, AsyncValue<void>>((ref) {
  return FavoriteToggleNotifier(ref.read(favoriteRepositoryProvider), ref);
});
