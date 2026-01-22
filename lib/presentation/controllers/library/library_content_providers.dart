import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/playlist.dart';
import '../../../domain/entities/song.dart';
import '../providers.dart';
import '../song_list_controller.dart';
import 'playlist_controller.dart';
import 'recently_played_controller.dart';

final songsCatalogProvider = Provider<List<Song>>((ref) {
  final songsAsync = ref.watch(songListControllerProvider);
  return songsAsync.maybeWhen(data: (songs) => songs, orElse: () => const []);
});

final playlistsProvider = Provider<List<Playlist>>((ref) {
  final playlistsAsync = ref.watch(playlistControllerProvider);
  return playlistsAsync.maybeWhen(
      data: (items) => items, orElse: () => const []);
});

final recentlyPlayedSongsProvider = Provider<List<Song>>((ref) {
  final idsAsync = ref.watch(recentlyPlayedControllerProvider);
  final songs = ref.watch(songsCatalogProvider);
  return idsAsync.maybeWhen(
    data: (ids) {
      final map = {for (final song in songs) song.id: song};
      return ids.map((id) => map[id]).whereType<Song>().toList();
    },
    orElse: () => const [],
  );
});

final mostPlayedSongsProvider = FutureProvider<List<Song>>((ref) async {
  final repository = ref.watch(libraryRepositoryProvider);
  final ids = await repository.fetchMostPlayedIds(limit: 20);
  final songs = ref.watch(songsCatalogProvider);
  final map = {for (final song in songs) song.id: song};
  return ids.map((id) => map[id]).whereType<Song>().toList();
});

class ArtistCollection {
  ArtistCollection(this.name, this.songs);

  final String name;
  final List<Song> songs;
}

class AlbumCollection {
  AlbumCollection(this.name, this.artist, this.songs);

  final String name;
  final String artist;
  final List<Song> songs;
}

final artistCollectionsProvider = Provider<List<ArtistCollection>>((ref) {
  final songs = ref.watch(songsCatalogProvider);
  final Map<String, List<Song>> grouped = {};
  for (final song in songs) {
    final key = song.artist.isEmpty ? 'Unknown Artist' : song.artist;
    grouped.putIfAbsent(key, () => []).add(song);
  }
  return grouped.entries
      .map((entry) => ArtistCollection(entry.key, entry.value))
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));
});

final albumCollectionsProvider = Provider<List<AlbumCollection>>((ref) {
  final songs = ref.watch(songsCatalogProvider);
  final Map<String, AlbumCollection> grouped = {};
  for (final song in songs) {
    final key = '${song.album}__${song.artist}';
    final collection = grouped[key];
    if (collection == null) {
      grouped[key] = AlbumCollection(
        song.album.isEmpty ? 'Unknown Album' : song.album,
        song.artist.isEmpty ? 'Unknown Artist' : song.artist,
        [song],
      );
    } else {
      collection.songs.add(song);
    }
  }
  final list = grouped.values.toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  return list;
});
