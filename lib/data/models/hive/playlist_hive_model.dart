import 'package:hive/hive.dart';

part 'playlist_hive_model.g.dart';

@HiveType(typeId: 0)
class PlaylistHiveModel extends HiveObject {
  PlaylistHiveModel({
    required this.id,
    required this.name,
    required this.songIds,
    required this.createdAt,
    this.description,
    this.coverArt,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<int> songIds;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  String? description;

  @HiveField(5)
  List<int>? coverArt;
}
