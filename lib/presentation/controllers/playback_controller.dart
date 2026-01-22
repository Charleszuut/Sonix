import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/utils/media_item_mapper.dart';
import '../../domain/entities/song.dart';
import 'library/recently_played_controller.dart';
import 'playback_providers.dart';
import 'providers.dart';

final playbackControllerProvider = Provider<PlaybackController>((ref) {
  return PlaybackController(ref);
});

class PlaybackController {
  PlaybackController(this._ref) {
    _ref.listen<AsyncValue<MediaItem?>>(currentMediaItemProvider,
        (previous, next) {
      next.whenData((item) {
        final songId = item?.extras?['songId'] as int?;
        if (songId == null) return;

        unawaited(_recordSongStart(songId));
      });
    }, fireImmediately: true);
  }

  final Ref _ref;

  Future<void> playSongs(List<Song> songs, {int startIndex = 0}) async {
    if (songs.isEmpty) return;
    final handler = _ref.read(audioHandlerProvider);
    final mediaItems = songs.map(MediaItemMapper.fromSong).toList();
    await handler.replaceQueue(mediaItems, startIndex: startIndex);
    await handler.play();
  }

  Future<void> togglePlayPause() async {
    final PlaybackState playbackState =
        await _ref.read(audioHandlerProvider).playbackState.first;
    if (playbackState.playing) {
      await _ref.read(audioHandlerProvider).pause();
    } else {
      await _ref.read(audioHandlerProvider).play();
    }
  }

  Future<void> playSong(Song song, List<Song> allSongs) async {
    final index = allSongs.indexWhere((element) => element.id == song.id);
    final startIndex = index >= 0 ? index : 0;
    await playSongs(allSongs, startIndex: startIndex);
  }

  Future<void> skipNext() async {
    final handler = _ref.read(audioHandlerProvider);
    await handler.skipToNext();
  }

  Future<void> skipPrevious() async {
    await _ref.read(audioHandlerProvider).skipToPrevious();
  }

  Future<void> seek(Duration position) =>
      _ref.read(audioHandlerProvider).seek(position);

  Future<void> setShuffle(bool enabled) async {
    await _ref.read(audioHandlerProvider).setShuffleModeEnabled(enabled);
  }

  Future<void> cycleLoopMode() async {
    final handler = _ref.read(audioHandlerProvider);
    final current = await handler.loopModeStream.first;
    switch (current) {
      case LoopMode.off:
        await handler.setLoopMode(LoopMode.all);
        break;
      case LoopMode.all:
        await handler.setLoopMode(LoopMode.one);
        break;
      case LoopMode.one:
        await handler.setLoopMode(LoopMode.off);
        break;
    }
  }

  Future<void> _recordSongStart(int songId) async {
    await _ref.read(libraryRepositoryProvider).incrementPlayCount(songId);
    await _ref
        .read(recentlyPlayedControllerProvider.notifier)
        .recordPlay(songId);
  }
}
