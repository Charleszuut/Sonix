import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class SonixAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  SonixAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState);
    _player.currentIndexStream.listen(_handlePlayerIndexChange);
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        stop();
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();

  final List<int> _historyStack = [];
  static const int _historyLimit = 100;
  bool _restoringFromHistory = false;
  int? _pendingHistoryPlayerIndex;
  int? _lastPlayerIndex;

  /// Streams exposed to the UI layer.
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  Stream<LoopMode> get loopModeStream => _player.loopModeStream;
  Stream<bool> get shuffleModeStream => _player.shuffleModeEnabledStream;

  LoopMode get loopMode => _player.loopMode;
  bool get isShuffleEnabled => _player.shuffleModeEnabled;

  Future<void> replaceQueue(List<MediaItem> items, {int startIndex = 0}) async {
    if (items.isEmpty) return;

    _historyStack.clear();
    _restoringFromHistory = false;
    _pendingHistoryPlayerIndex = null;
    _lastPlayerIndex = null;

    queue.add(items);
    final audioSources = items
        .map((item) => AudioSource.uri(Uri.parse(item.id), tag: item))
        .toList();

    await _player.setAudioSource(
      ConcatenatingAudioSource(children: audioSources),
      initialIndex: startIndex,
      preload: true,
    );

    mediaItem.add(items[startIndex]);
    _lastPlayerIndex = startIndex;
  }

  Future<void> setShuffleModeEnabled(bool enabled) async {
    await _player.setShuffleModeEnabled(enabled);
    _historyStack.clear();
    _restoringFromHistory = false;
    _pendingHistoryPlayerIndex = null;
  }

  Future<void> setLoopMode(LoopMode loopMode) async {
    await _player.setLoopMode(loopMode);
  }

  void _handlePlayerIndexChange(int? playerIndex) {
    if (playerIndex == null) return;
    final sequence = _player.sequence;
    if (sequence == null || playerIndex < 0 || playerIndex >= sequence.length) {
      return;
    }

    final currentTag = sequence[playerIndex].tag;
    if (currentTag is MediaItem) {
      mediaItem.add(currentTag);
    }

    if (_restoringFromHistory) {
      if (_pendingHistoryPlayerIndex == playerIndex) {
        _restoringFromHistory = false;
        _pendingHistoryPlayerIndex = null;
      }
    } else {
      final previousPlayerIndex = _lastPlayerIndex;
      if (previousPlayerIndex != null && previousPlayerIndex != playerIndex) {
        if (_historyStack.isEmpty ||
            _historyStack.last != previousPlayerIndex) {
          _historyStack.add(previousPlayerIndex);
          if (_historyStack.length > _historyLimit) {
            _historyStack.removeAt(0);
          }
        }
      }
    }

    _lastPlayerIndex = playerIndex;
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    final queueIndex = event.currentIndex;
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        androidCompactActionIndices: const [0, 1, 3],
        processingState: _mapProcessingState(_player.processingState),
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: queueIndex,
        shuffleMode: _player.shuffleModeEnabled
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        repeatMode: _mapLoopMode(_player.loopMode),
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
      ),
    );
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  AudioServiceRepeatMode _mapLoopMode(LoopMode loopMode) {
    switch (loopMode) {
      case LoopMode.off:
        return AudioServiceRepeatMode.none;
      case LoopMode.one:
        return AudioServiceRepeatMode.one;
      case LoopMode.all:
        return AudioServiceRepeatMode.all;
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    await _player.seekToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_historyStack.isNotEmpty) {
      final targetPlayerIndex = _historyStack.removeLast();
      _restoringFromHistory = true;
      _pendingHistoryPlayerIndex = targetPlayerIndex;
      await _seekToPlayerIndex(targetPlayerIndex);
      return;
    }

    await _player.seekToPrevious();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    final currentIndex = _player.currentIndex;
    if (currentIndex != null) {
      _historyStack.add(currentIndex);
      if (_historyStack.length > _historyLimit) {
        _historyStack.removeAt(0);
      }
    }

    final playerIndex = _player.shuffleModeEnabled
        ? _player.shuffleIndices?.indexOf(index) ?? index
        : index;

    _restoringFromHistory = true;
    _pendingHistoryPlayerIndex = playerIndex;
    await _seekToPlayerIndex(playerIndex);
  }

  Future<void> _seekToPlayerIndex(int playerIndex) async {
    final previousLoopMode = _player.loopMode;
    if (previousLoopMode == LoopMode.one) {
      await _player.setLoopMode(LoopMode.off);
    }

    await _player.seek(Duration.zero, index: playerIndex);
    if (_player.playing) {
      await _player.play();
    }

    if (previousLoopMode == LoopMode.one) {
      await _player.setLoopMode(previousLoopMode);
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
    await super.onTaskRemoved();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
