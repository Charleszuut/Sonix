import 'dart:typed_data';

import 'package:on_audio_query/on_audio_query.dart';

import '../../domain/entities/song.dart';
import '../../domain/repositories/song_repository.dart';
import '../datasources/local_music_data_source.dart';
import '../models/song_model.dart';

class SongRepositoryImpl implements SongRepository {
  SongRepositoryImpl(this._dataSource);

  final LocalMusicDataSource _dataSource;

  @override
  Future<List<Song>> fetchAllSongs() async {
    final songModels = await _dataSource.fetchDeviceSongs();
    final List<Song> songs = [];

    for (final songModel in songModels) {
      final artworkBytes = await _loadArtwork(songModel);
      songs
          .add(SongMapper.fromSongModel(songModel, artworkBytes: artworkBytes));
    }

    return songs;
  }

  Future<Uint8List?> _loadArtwork(SongModel songModel) async {
    try {
      return await _dataSource.loadArtwork(songModel.id, ArtworkType.AUDIO);
    } catch (_) {
      return null;
    }
  }
}
