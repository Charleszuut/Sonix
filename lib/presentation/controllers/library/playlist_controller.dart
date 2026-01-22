import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/playlist.dart';
import '../providers.dart';

final playlistControllerProvider =
    StateNotifierProvider<PlaylistController, AsyncValue<List<Playlist>>>(
  (ref) => PlaylistController(ref),
);

class PlaylistController extends StateNotifier<AsyncValue<List<Playlist>>> {
  PlaylistController(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    try {
      final playlists =
          await _ref.read(libraryRepositoryProvider).fetchPlaylists();
      state = AsyncValue.data(playlists);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createPlaylist(String name) async {
    if (name.trim().isEmpty) return;
    await _ref
        .read(libraryRepositoryProvider)
        .createPlaylist(name: name.trim());
    await _load();
  }

  Future<void> rename(String playlistId, String newName) async {
    if (newName.trim().isEmpty) return;
    await _ref
        .read(libraryRepositoryProvider)
        .renamePlaylist(playlistId, newName.trim());
    await _load();
  }

  Future<void> delete(String playlistId) async {
    await _ref.read(libraryRepositoryProvider).deletePlaylist(playlistId);
    await _load();
  }

  Future<void> addSong(String playlistId, int songId) async {
    await _ref
        .read(libraryRepositoryProvider)
        .addSongToPlaylist(playlistId, songId);
    await _load();
  }

  Future<void> removeSong(String playlistId, int songId) async {
    await _ref
        .read(libraryRepositoryProvider)
        .removeSongFromPlaylist(playlistId, songId);
    await _load();
  }

  Future<void> refresh() => _load();
}
