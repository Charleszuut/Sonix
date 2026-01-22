import 'dart:typed_data';

class Song {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.uri,
    this.albumId,
    this.artistId,
    this.artwork,
  });

  final int id;
  final String title;
  final String artist;
  final String album;
  final int duration;
  final String uri;
  final int? albumId;
  final int? artistId;
  final Uint8List? artwork;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Song && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
