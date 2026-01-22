import 'package:hive_flutter/hive_flutter.dart';

import '../constants/hive_boxes.dart';
import '../../data/models/hive/playlist_hive_model.dart';

class HiveInitializer {
  const HiveInitializer._();

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(PlaylistHiveModelAdapter().typeId)) {
      Hive.registerAdapter(PlaylistHiveModelAdapter());
    }

    await Future.wait([
      Hive.openBox<PlaylistHiveModel>(HiveBoxes.playlists),
      Hive.openBox<bool>(HiveBoxes.favorites),
      Hive.openBox<int>(HiveBoxes.recentlyPlayed),
      Hive.openBox<int>(HiveBoxes.mostPlayed),
      Hive.openBox<dynamic>(HiveBoxes.preferences),
    ]);
  }
}
