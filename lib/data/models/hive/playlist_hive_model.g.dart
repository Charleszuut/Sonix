// GENERATED CODE - MANUALLY WRITTEN FOR NOW
// ignore_for_file: type=lint

part of 'playlist_hive_model.dart';

class PlaylistHiveModelAdapter extends TypeAdapter<PlaylistHiveModel> {
  @override
  final int typeId = 0;

  @override
  PlaylistHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlaylistHiveModel(
      id: fields[0] as String,
      name: fields[1] as String,
      songIds: (fields[2] as List?)?.cast<int>() ?? <int>[],
      createdAt: fields[3] as DateTime,
      description: fields[4] as String?,
      coverArt: (fields[5] as List?)?.cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, PlaylistHiveModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.songIds)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.coverArt);
  }
}
