import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_exceptions.dart';
import '../../core/utils/permission_manager.dart';
import '../../domain/entities/song.dart';
import 'providers.dart';

final songListControllerProvider =
    StateNotifierProvider<SongListController, AsyncValue<List<Song>>>(
  (ref) => SongListController(ref),
);

class SongListController extends StateNotifier<AsyncValue<List<Song>>> {
  SongListController(this._ref) : super(const AsyncValue.loading());

  final Ref _ref;

  Future<void> loadSongs({bool force = false}) async {
    if (!force &&
        state is AsyncData<List<Song>> &&
        (state.value?.isNotEmpty ?? false)) {
      return;
    }

    state = const AsyncValue.loading();

    final hasPermission = await PermissionManager.ensureAudioPermission();
    if (!hasPermission) {
      state = AsyncValue.error(PermissionDeniedException(), StackTrace.current);
      return;
    }

    try {
      final songs = await _ref.read(getDeviceSongsProvider)();
      if (songs.isEmpty) {
        state = AsyncValue.error(EmptyLibraryException(), StackTrace.current);
      } else {
        state = AsyncValue.data(songs);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
