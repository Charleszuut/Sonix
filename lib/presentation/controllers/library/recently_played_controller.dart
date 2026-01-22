import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

final recentlyPlayedControllerProvider =
    StateNotifierProvider<RecentlyPlayedController, AsyncValue<List<int>>>(
  (ref) => RecentlyPlayedController(ref),
);

class RecentlyPlayedController extends StateNotifier<AsyncValue<List<int>>> {
  RecentlyPlayedController(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    try {
      final ids =
          await _ref.read(libraryRepositoryProvider).fetchRecentlyPlayedIds();
      state = AsyncValue.data(ids);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> recordPlay(int songId) async {
    try {
      await _ref.read(libraryRepositoryProvider).recordRecentlyPlayed(songId);
      await _load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clearHistory() async {
    try {
      await _ref.read(libraryRepositoryProvider).clearRecentlyPlayed();
      await _load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
