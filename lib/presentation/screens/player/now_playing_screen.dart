import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/song.dart';
import '../../controllers/library/favorites_controller.dart';
import '../../controllers/library/library_content_providers.dart';
import '../../controllers/playback_controller.dart';
import '../../controllers/playback_providers.dart';
import '../../widgets/player/seek_bar.dart';
import '../../widgets/song/song_actions_menu.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaItemAsync = ref.watch(currentMediaItemProvider);

    return mediaItemAsync.when(
      data: (mediaItem) {
        if (mediaItem == null) {
          return const SizedBox.shrink();
        }

        final artwork = mediaItem.extras?['artwork'] as Uint8List?;
        final playbackState = ref.watch(playbackStateProvider).value;
        final position = ref.watch(positionProvider).value ?? Duration.zero;
        final bufferedPosition =
            ref.watch(bufferedPositionProvider).value ?? Duration.zero;
        final loopMode = ref.watch(loopModeProvider).value ?? LoopMode.off;
        final shuffleEnabled =
            ref.watch(shuffleModeEnabledProvider).value ?? false;
        final duration = mediaItem.duration ?? Duration.zero;
        final controller = ref.read(playbackControllerProvider);
        final songsCatalog = ref.watch(songsCatalogProvider);
        final songId = mediaItem.extras?['songId'] as int?;
        Song? currentSong;
        if (songId != null) {
          for (final song in songsCatalog) {
            if (song.id == songId) {
              currentSong = song;
              break;
            }
          }
        }
        final favoritesAsync = ref.watch(favoritesControllerProvider);
        final isFavorite = songId != null
            ? favoritesAsync.maybeWhen(
                data: (favorites) => favorites.contains(songId),
                orElse: () => false,
              )
            : false;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              _BlurredArtworkBackground(artwork: artwork),
              const _GradientOverlay(),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxContentWidth = constraints.maxWidth > 720
                        ? 480.0
                        : constraints.maxWidth;
                    final horizontalPadding = constraints.maxWidth > 720
                        ? (constraints.maxWidth - maxContentWidth) / 2
                        : 20.0;

                    final isTall = constraints.maxHeight > 760;

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: isTall ? 20 : 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _TopBar(
                            onClose: () => Navigator.of(context).pop(),
                            onEqualizer: () =>
                                _showComingSoon(context, 'Sound settings'),
                            onCast: () =>
                                _showComingSoon(context, 'Cast to device'),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: ConstrainedBox(
                                constraints:
                                    BoxConstraints(maxWidth: maxContentWidth),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            child: Center(
                                              child: FractionallySizedBox(
                                                widthFactor:
                                                    constraints.maxWidth > 420
                                                        ? 0.68
                                                        : 0.78,
                                                child: Hero(
                                                  tag: 'now-playing-art',
                                                  child: _LargeArtwork(
                                                      artwork: artwork),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            mediaItem.title,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize:
                                                  constraints.maxWidth > 420
                                                      ? 20
                                                      : 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            mediaItem.artist ??
                                                'Unknown Artist',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize:
                                                  constraints.maxWidth > 420
                                                      ? 13
                                                      : 12,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          _ActionRow(
                                            isFavorite: isFavorite,
                                            onToggleFavorite: () {
                                              if (songId != null) {
                                                ref
                                                    .read(
                                                        favoritesControllerProvider
                                                            .notifier)
                                                    .toggleFavorite(songId);
                                              }
                                            },
                                            onAddToPlaylist: () {
                                              final song = currentSong;
                                              if (song != null) {
                                                showAddToPlaylistSheet(
                                                  context,
                                                  ref,
                                                  song,
                                                );
                                              } else {
                                                _showComingSoon(
                                                  context,
                                                  'Add to playlist',
                                                );
                                              }
                                            },
                                            onQueue: () => _showComingSoon(
                                                context, 'Up next queue'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const SizedBox(height: 12),
                                        SeekBar(
                                          duration: duration,
                                          position: position,
                                          bufferedPosition: bufferedPosition,
                                          onChanged: controller.seek,
                                        ),
                                        const SizedBox(height: 12),
                                        _TransportControls(
                                          isPlaying:
                                              playbackState?.playing ?? false,
                                          shuffleEnabled: shuffleEnabled,
                                          loopMode: loopMode,
                                          onToggleShuffle: () => controller
                                              .setShuffle(!shuffleEnabled),
                                          onPrevious: controller.skipPrevious,
                                          onPlayPause:
                                              controller.togglePlayPause,
                                          onNext: controller.skipNext,
                                          onCycleLoop: controller.cycleLoopMode,
                                        ),
                                        const SizedBox(height: 12),
                                        _BottomActions(
                                          onQueue: () => _showComingSoon(
                                              context, 'Queue manager'),
                                          onLyrics: () => _showComingSoon(
                                              context, 'Live lyrics'),
                                          onShare: () => _showComingSoon(
                                              context, 'Share track'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('Playback error: $error'),
        ),
      ),
    );
  }
}

void _showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$feature coming soon'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class _BlurredArtworkBackground extends StatelessWidget {
  const _BlurredArtworkBackground({this.artwork});

  final Uint8List? artwork;

  @override
  Widget build(BuildContext context) {
    if (artwork == null) {
      return Container(color: AppColors.background);
    }

    return Positioned.fill(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: MemoryImage(artwork!),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientOverlay extends StatelessWidget {
  const _GradientOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xEE040404),
              Color(0xCC0B2416),
              Color(0xCC06232C),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onClose,
    required this.onEqualizer,
    required this.onCast,
  });

  final VoidCallback onClose;
  final VoidCallback onEqualizer;
  final VoidCallback onCast;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          onPressed: onClose,
        ),
        const Text(
          'Now Playing',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.equalizer),
              onPressed: onEqualizer,
            ),
            IconButton(
              icon: const Icon(Icons.cast_rounded),
              onPressed: onCast,
            ),
          ],
        ),
      ],
    );
  }
}

class _LargeArtwork extends StatelessWidget {
  const _LargeArtwork({this.artwork});

  final Uint8List? artwork;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: const BoxDecoration(color: AppColors.surfaceAlt),
            child: artwork != null
                ? Image.memory(artwork!, fit: BoxFit.cover)
                : const Icon(Icons.music_note,
                    size: 96, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onAddToPlaylist,
    required this.onQueue,
  });

  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onAddToPlaylist;
  final VoidCallback onQueue;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionChip(
          icon: Icons.queue_music,
          label: 'Up next',
          onTap: onQueue,
        ),
        _ActionChip(
          icon: isFavorite ? Icons.favorite : Icons.favorite_border,
          label: isFavorite ? 'Favorited' : 'Favorite',
          onTap: onToggleFavorite,
          highlighted: isFavorite,
        ),
        _ActionChip(
          icon: Icons.playlist_add,
          label: 'Add',
          onTap: onAddToPlaylist,
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final bgColor = highlighted
        ? AppColors.accent.withOpacity(0.18)
        : Colors.white.withOpacity(0.08);
    final iconColor = highlighted ? Colors.white : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransportControls extends StatelessWidget {
  const _TransportControls({
    required this.isPlaying,
    required this.shuffleEnabled,
    required this.loopMode,
    required this.onToggleShuffle,
    required this.onPrevious,
    required this.onPlayPause,
    required this.onNext,
    required this.onCycleLoop,
  });

  final bool isPlaying;
  final bool shuffleEnabled;
  final LoopMode loopMode;
  final Future<void> Function() onToggleShuffle;
  final Future<void> Function() onPrevious;
  final Future<void> Function() onPlayPause;
  final Future<void> Function() onNext;
  final Future<void> Function() onCycleLoop;

  @override
  Widget build(BuildContext context) {
    final loopIcon = switch (loopMode) {
      LoopMode.one => Icons.repeat_one,
      LoopMode.all => Icons.repeat,
      _ => Icons.repeat,
    };

    final loopColor =
        loopMode == LoopMode.off ? AppColors.textSecondary : AppColors.accent;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(
            shuffleEnabled ? Icons.shuffle_on : Icons.shuffle,
            color: shuffleEnabled ? AppColors.accent : AppColors.textSecondary,
          ),
          onPressed: onToggleShuffle,
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded, size: 32),
          onPressed: onPrevious,
        ),
        ElevatedButton(
          onPressed: onPlayPause,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(22),
          ),
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 36,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.skip_next_rounded, size: 32),
          onPressed: onNext,
        ),
        IconButton(
          icon: Icon(loopIcon, color: loopColor),
          onPressed: onCycleLoop,
        ),
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.onQueue,
    required this.onLyrics,
    required this.onShare,
  });

  final VoidCallback onQueue;
  final VoidCallback onLyrics;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _BottomActionButton(
          icon: Icons.queue_music,
          label: 'Queue',
          onTap: onQueue,
        ),
        _BottomActionButton(
          icon: Icons.lyrics,
          label: 'Lyrics',
          onTap: onLyrics,
        ),
        _BottomActionButton(
          icon: Icons.share_outlined,
          label: 'Share',
          onTap: onShare,
        ),
      ],
    );
  }
}

class _BottomActionButton extends StatelessWidget {
  const _BottomActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
