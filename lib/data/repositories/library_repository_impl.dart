import 'dart:typed_data';

import 'package:hive/hive.dart';

import '../../domain/entities/playlist.dart';
import '../../domain/repositories/library_repository.dart';
import '../models/hive/playlist_hive_model.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  LibraryRepositoryImpl({
    required this.favoritesBox,
    required this.recentlyPlayedBox,
    required this.playlistsBox,
    required this.mostPlayedBox,
  });

  final Box<bool> favoritesBox;
  final Box<int> recentlyPlayedBox;
  final Box<PlaylistHiveModel> playlistsBox;
  final Box<int> mostPlayedBox;

  @override
  Future<Set<int>> fetchFavoriteSongIds() async {
    return favoritesBox.keys
        .where((key) => favoritesBox.get(key, defaultValue: false) ?? false)
        .map((key) => int.tryParse(key.toString()))
        .whereType<int>()
        .toSet();
  }

  @override
  Future<void> toggleFavorite(int songId) async {
    final key = songId.toString();
    final current = favoritesBox.get(key, defaultValue: false) ?? false;
    await favoritesBox.put(key, !current);
  }

  @override
  Future<List<int>> fetchRecentlyPlayedIds({int limit = 25}) async {
    final values = recentlyPlayedBox.values.toList().reversed.toList();
    return values.length > limit ? values.take(limit).toList() : values;
  }

  @override
  Future<void> recordRecentlyPlayed(int songId, {int limit = 25}) async {
    final values = recentlyPlayedBox.values.toList();
    values.remove(songId);
    values.add(songId);

    if (values.length > limit) {
      values.removeRange(0, values.length - limit);
    }

    await recentlyPlayedBox.clear();
    for (final id in values) {
      await recentlyPlayedBox.add(id);
    }
  }

  @override
  Future<void> clearRecentlyPlayed() async {
    await recentlyPlayedBox.clear();
  }

  @override
  Future<List<int>> fetchMostPlayedIds({int limit = 25}) async {
    final entries = mostPlayedBox.toMap().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final ids = entries
        .map((entry) => int.tryParse(entry.key.toString()))
        .whereType<int>()
        .toList();
    return ids.length > limit ? ids.take(limit).toList() : ids;
  }

  @override
  Future<void> incrementPlayCount(int songId) async {
    final key = songId.toString();
    final current = mostPlayedBox.get(key, defaultValue: 0) ?? 0;
    await mostPlayedBox.put(key, current + 1);
  }

  @override
  Future<List<Playlist>> fetchPlaylists() async {
    return playlistsBox.values
        .map((model) => Playlist(
              id: model.id,
              name: model.name,
              songIds: List<int>.from(model.songIds),
              createdAt: model.createdAt,
              description: model.description,
              coverArt: _decodeCoverArt(model.coverArt),
            ))
        .toList();
  }

  @override
  Future<void> createPlaylist({required String name}) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final model = PlaylistHiveModel(
      id: id,
      name: name,
      songIds: <int>[],
      createdAt: DateTime.now(),
    );
    await playlistsBox.put(id, model);
  }

  @override
  Future<void> renamePlaylist(String playlistId, String newName) async {
    final playlist = playlistsBox.get(playlistId);
    if (playlist == null) return;
    playlist
      ..name = newName
      ..save();
  }

  @override
  Future<void> deletePlaylist(String playlistId) async {
    await playlistsBox.delete(playlistId);
  }

  @override
  Future<void> addSongToPlaylist(String playlistId, int songId) async {
    final playlist = playlistsBox.get(playlistId);
    if (playlist == null) return;
    if (!playlist.songIds.contains(songId)) {
      playlist.songIds = [...playlist.songIds, songId];
      await playlist.save();
    }
  }

  @override
  Future<void> removeSongFromPlaylist(String playlistId, int songId) async {
    final playlist = playlistsBox.get(playlistId);
    if (playlist == null) return;
    playlist.songIds = playlist.songIds.where((id) => id != songId).toList();
    await playlist.save();
  }

  Uint8List? _decodeCoverArt(List<int>? coverArt) {
    if (coverArt == null) return null;
    return Uint8List.fromList(coverArt);
  }
}
