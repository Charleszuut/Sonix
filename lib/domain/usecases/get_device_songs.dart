import '../entities/song.dart';
import '../repositories/song_repository.dart';

class GetDeviceSongs {
  const GetDeviceSongs(this._repository);

  final SongRepository _repository;

  Future<List<Song>> call() {
    return _repository.fetchAllSongs();
  }
}
