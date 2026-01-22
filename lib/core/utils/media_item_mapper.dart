import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';

import '../../domain/entities/song.dart';

class MediaItemMapper {
  const MediaItemMapper._();

  static MediaItem fromSong(Song song) {
    return MediaItem(
      id: Uri.file(song.uri).toString(),
      title: song.title,
      album: song.album,
      artist: song.artist,
      duration: Duration(milliseconds: song.duration),
      extras: <String, dynamic>{
        'songId': song.id,
        'albumId': song.albumId,
        'artistId': song.artistId,
        if (song.artwork != null) 'artwork': song.artwork,
      },
    );
  }

  static Uint8List? getArtwork(MediaItem mediaItem) {
    final value = mediaItem.extras?['artwork'];
    if (value is Uint8List) {
      return value;
    }
    return null;
  }
}
