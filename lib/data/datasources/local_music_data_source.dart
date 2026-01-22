import 'dart:typed_data';

import 'package:on_audio_query/on_audio_query.dart';

class LocalMusicDataSource {
  LocalMusicDataSource(this._audioQuery);

  final OnAudioQuery _audioQuery;

  Future<List<SongModel>> fetchDeviceSongs() {
    return _audioQuery.querySongs(
      sortType: SongSortType.DISPLAY_NAME,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
  }

  Future<List<AlbumModel>> fetchAlbums() {
    return _audioQuery.queryAlbums(
      sortType: AlbumSortType.ALBUM,
      orderType: OrderType.ASC_OR_SMALLER,
      ignoreCase: true,
    );
  }

  Future<List<ArtistModel>> fetchArtists() {
    return _audioQuery.queryArtists(
      sortType: ArtistSortType.ARTIST,
      orderType: OrderType.ASC_OR_SMALLER,
      ignoreCase: true,
    );
  }

  Future<Uint8List?> loadArtwork(int id, ArtworkType type) {
    return _audioQuery.queryArtwork(id, type, format: ArtworkFormat.JPEG);
  }
}
