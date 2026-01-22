import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../core/audio/sonix_audio_handler.dart';
import '../../core/constants/hive_boxes.dart';
import '../../data/datasources/local_music_data_source.dart';
import '../../data/models/hive/playlist_hive_model.dart';
import '../../data/repositories/library_repository_impl.dart';
import '../../data/repositories/song_repository_impl.dart';
import '../../domain/repositories/library_repository.dart';
import '../../domain/repositories/song_repository.dart';
import '../../domain/usecases/get_device_songs.dart';

final audioHandlerProvider = Provider<SonixAudioHandler>((ref) {
  throw UnimplementedError(
    'audioHandlerProvider must be overridden with a fully initialised handler in main.dart',
  );
});

final onAudioQueryProvider = Provider<OnAudioQuery>((ref) => OnAudioQuery());

final localMusicDataSourceProvider = Provider<LocalMusicDataSource>((ref) {
  return LocalMusicDataSource(ref.watch(onAudioQueryProvider));
});

final songRepositoryProvider = Provider<SongRepository>((ref) {
  return SongRepositoryImpl(ref.watch(localMusicDataSourceProvider));
});

final getDeviceSongsProvider = Provider<GetDeviceSongs>((ref) {
  return GetDeviceSongs(ref.watch(songRepositoryProvider));
});

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepositoryImpl(
    favoritesBox: Hive.box<bool>(HiveBoxes.favorites),
    recentlyPlayedBox: Hive.box<int>(HiveBoxes.recentlyPlayed),
    playlistsBox: Hive.box<PlaylistHiveModel>(HiveBoxes.playlists),
    mostPlayedBox: Hive.box<int>(HiveBoxes.mostPlayed),
  );
});
