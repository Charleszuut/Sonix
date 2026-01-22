import '../entities/playlist.dart';

abstract class LibraryRepository {
  Future<Set<int>> fetchFavoriteSongIds();
  Future<void> toggleFavorite(int songId);

  Future<List<int>> fetchRecentlyPlayedIds({int limit = 25});
  Future<void> recordRecentlyPlayed(int songId, {int limit = 25});
  Future<void> clearRecentlyPlayed();
  Future<List<int>> fetchMostPlayedIds({int limit = 25});
  Future<void> incrementPlayCount(int songId);

  Future<List<Playlist>> fetchPlaylists();
  Future<void> createPlaylist({required String name});
  Future<void> renamePlaylist(String playlistId, String newName);
  Future<void> deletePlaylist(String playlistId);
  Future<void> addSongToPlaylist(String playlistId, int songId);
  Future<void> removeSongFromPlaylist(String playlistId, int songId);
}
