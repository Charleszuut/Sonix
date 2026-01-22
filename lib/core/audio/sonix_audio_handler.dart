import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class SonixAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  SonixAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState);
    _player.currentIndexStream.listen((index) {
      final currentQueue = queue.value;
      if (index != null && index >= 0 && index < currentQueue.length) {
        mediaItem.add(currentQueue[index]);
      }
    });
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        stop();
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();
  final _random = Random();
  ConcatenatingAudioSource? _playlist;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  Stream<LoopMode> get loopModeStream => _player.loopModeStream;
  Stream<bool> get shuffleModeStream => _player.shuffleModeEnabledStream;

  bool get isShuffleEnabled => _player.shuffleModeEnabled;
  LoopMode get loopMode => _player.loopMode;

  Future<void> replaceQueue(List<MediaItem> items, {int startIndex = 0}) async {
    if (items.isEmpty) {
      return;
    }

    queue.add(items);
    _playlist = ConcatenatingAudioSource(
      children:
          items.map((item) => AudioSource.uri(Uri.parse(item.id))).toList(),
      useLazyPreparation: true,
    );

    await _player.setAudioSource(
      _playlist!,
      initialIndex: startIndex,
      preload: true,
    );

    mediaItem.add(items[startIndex]);
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

  Future<void> setShuffleModeEnabled(bool enabled) async {
    await _player.setShuffleModeEnabled(enabled);
    _broadcastState(_player.playbackEvent);
  }

  Future<void> setLoopMode(LoopMode loopMode) async {
    await _player.setLoopMode(loopMode);
    _broadcastState(_player.playbackEvent);
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
    if (_player.shuffleModeEnabled) {
      await _playRandomTrack();
      return;
    }

    final previousLoopMode = _player.loopMode;
    if (previousLoopMode == LoopMode.one) {
      await _player.setLoopMode(LoopMode.off);
    }

    await _player.seekToNext();

    if (previousLoopMode != _player.loopMode) {
      await _player.setLoopMode(previousLoopMode);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.shuffleModeEnabled) {
      await _playRandomTrack();
      return;
    }

    final previousLoopMode = _player.loopMode;
    if (previousLoopMode == LoopMode.one) {
      await _player.setLoopMode(LoopMode.off);
    }

    await _player.seekToPrevious();

    if (previousLoopMode != _player.loopMode) {
      await _player.setLoopMode(previousLoopMode);
    }
  }

  Future<void> _playRandomTrack() async {
    final total = _playlist?.length ?? 0;
    if (total <= 1) {
      return;
    }

    final currentIndex = _player.currentIndex ?? 0;
    var randomIndex = _random.nextInt(total);
    if (total > 1) {
      while (randomIndex == currentIndex) {
        randomIndex = _random.nextInt(total);
      }
    }

    await _player.seek(Duration.zero, index: randomIndex);
    if (_player.playing) {
      await _player.play();
    }
  }

  Future<void> playFromQueueIndex(int index) async {
    if (_playlist == null) return;
    final total = _playlist!.length;
    if (index < 0 || index >= total) return;

    final previousLoopMode = _player.loopMode;
    if (previousLoopMode == LoopMode.one) {
      await _player.setLoopMode(LoopMode.off);
    }

    await _player.seek(Duration.zero, index: index);
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
