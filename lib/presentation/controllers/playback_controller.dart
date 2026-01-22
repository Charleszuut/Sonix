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

        if (_currentSongId == songId) {
          return;
        }

        if (!_restoringHistory && _currentSongId != null) {
          _historyStack.add(_currentSongId!);
          if (_historyStack.length > _historyLimit) {
            _historyStack.removeRange(0, _historyStack.length - _historyLimit);
          }
        }

        _currentSongId = songId;
        unawaited(_handleSongStart(songId));
      });
    }, fireImmediately: true);
  }

  final Ref _ref;
  final List<int> _historyStack = [];
  int? _currentSongId;
  bool _restoringHistory = false;
  static const int _historyLimit = 100;

  Future<void> playSongs(List<Song> songs, {int startIndex = 0}) async {
    if (songs.isEmpty) return;
    final handler = _ref.read(audioHandlerProvider);
    final mediaItems = songs.map(MediaItemMapper.fromSong).toList();
    _historyStack.clear();
    _currentSongId = null;
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
    final handler = _ref.read(audioHandlerProvider);
    final playbackState = await handler.playbackState.first;
    final shuffleEnabled =
        playbackState.shuffleMode == AudioServiceShuffleMode.all;
    if (shuffleEnabled && _historyStack.isNotEmpty) {
      final previousSongId = _historyStack.removeLast();
      _restoringHistory = true;
      await _jumpToSong(previousSongId);
      _restoringHistory = false;
    } else {
      await handler.skipToPrevious();
    }
  }

  Future<void> seek(Duration position) =>
      _ref.read(audioHandlerProvider).seek(position);

  Future<void> setShuffle(bool enabled) =>
      _ref.read(audioHandlerProvider).setShuffleModeEnabled(enabled).then((_) {
        if (!enabled) {
          _historyStack.clear();
        }
      });

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

  Future<void> _handleSongStart(int songId) async {
    _currentSongId = songId;
    await _ref.read(libraryRepositoryProvider).incrementPlayCount(songId);
    await _ref
        .read(recentlyPlayedControllerProvider.notifier)
        .recordPlay(songId);
  }

  Future<void> _jumpToSong(int songId) async {
    final handler = _ref.read(audioHandlerProvider);
    final queue = await handler.queue.first;
    final targetIndex =
        queue.indexWhere((item) => item.extras?['songId'] == songId);
    if (targetIndex == -1) {
      await handler.skipToPrevious();
      return;
    }

    await handler.playFromQueueIndex(targetIndex);
  }
}
