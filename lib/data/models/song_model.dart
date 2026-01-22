import 'dart:typed_data';

import 'package:on_audio_query/on_audio_query.dart';

import '../../domain/entities/song.dart';

class SongMapper {
  const SongMapper._();

  static Song fromSongModel(SongModel model, {Uint8List? artworkBytes}) {
    return Song(
      id: model.id,
      title: model.title,
      artist: model.artist ?? 'Unknown Artist',
      album: model.album ?? 'Unknown Album',
      duration: model.duration ?? 0,
      uri: model.data,
      albumId: model.albumId,
      artistId: model.artistId,
      artwork: artworkBytes,
    );
  }
}
