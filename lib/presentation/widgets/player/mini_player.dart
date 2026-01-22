import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../controllers/playback_controller.dart';
import '../../controllers/playback_providers.dart';
import '../../screens/player/now_playing_screen.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaItem = ref.watch(currentMediaItemProvider).asData?.value;
    if (mediaItem == null) {
      return const SizedBox.shrink();
    }

    final playbackState = ref.watch(playbackStateProvider).asData?.value;
    final isPlaying = playbackState?.playing ?? false;
    final artwork = mediaItem.extras?['artwork'] as Uint8List?;

    return SafeArea(
      minimum: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                opaque: false,
                pageBuilder: (_, __, ___) => const NowPlayingScreen(),
                transitionsBuilder: (_, animation, __, child) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              ),
            );
          },
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Hero(
                  tag: 'now-playing-art',
                  child: _MiniArtwork(artwork: artwork),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mediaItem.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mediaItem.artist ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    size: 36,
                    color: AppColors.accent,
                  ),
                  onPressed: () =>
                      ref.read(playbackControllerProvider).togglePlayPause(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniArtwork extends StatelessWidget {
  const _MiniArtwork({this.artwork});

  final Uint8List? artwork;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(color: AppColors.surfaceAlt),
        child: artwork != null
            ? Image.memory(artwork!, fit: BoxFit.cover)
            : const Icon(Icons.music_note, color: AppColors.textSecondary),
      ),
    );
  }
}
