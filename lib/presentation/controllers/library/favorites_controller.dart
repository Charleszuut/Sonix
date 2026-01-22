import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

final favoritesControllerProvider =
    StateNotifierProvider<FavoritesController, AsyncValue<Set<int>>>(
  (ref) => FavoritesController(ref),
);

class FavoritesController extends StateNotifier<AsyncValue<Set<int>>> {
  FavoritesController(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    try {
      final favorites =
          await _ref.read(libraryRepositoryProvider).fetchFavoriteSongIds();
      state = AsyncValue.data(favorites);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleFavorite(int songId) async {
    try {
      await _ref.read(libraryRepositoryProvider).toggleFavorite(songId);
      await _load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _load();
}
