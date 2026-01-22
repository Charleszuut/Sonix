import 'dart:typed_data';

class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    required this.songIds,
    required this.createdAt,
    this.description,
    this.coverArt,
  });

  final String id;
  final String name;
  final List<int> songIds;
  final DateTime createdAt;
  final String? description;
  final Uint8List? coverArt;

  Playlist copyWith({
    String? name,
    List<int>? songIds,
    String? description,
    Uint8List? coverArt,
  }) {
    return Playlist(
      id: id,
      name: name ?? this.name,
      songIds: songIds ?? this.songIds,
      createdAt: createdAt,
      description: description ?? this.description,
      coverArt: coverArt ?? this.coverArt,
    );
  }
}
