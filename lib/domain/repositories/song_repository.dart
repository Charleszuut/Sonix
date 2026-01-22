import '../entities/song.dart';

abstract class SongRepository {
  Future<List<Song>> fetchAllSongs();
}
