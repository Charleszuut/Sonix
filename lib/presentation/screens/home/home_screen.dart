import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_exceptions.dart';
import '../../controllers/library/favorites_controller.dart';
import '../../controllers/playback_controller.dart';
import '../../controllers/song_list_controller.dart';
import '../../widgets/common/library_states.dart';
import '../../widgets/song/song_list_tile.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(songListControllerProvider.notifier).loadSongs());
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(songListControllerProvider);
    final favoritesAsync = ref.watch(favoritesControllerProvider);

    return songsAsync.when(
      data: (songs) => favoritesAsync.when(
        data: (favorites) => RefreshIndicator(
          onRefresh: () => ref
              .read(songListControllerProvider.notifier)
              .loadSongs(force: true),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            itemCount: songs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final song = songs[index];
              final isFavorite = favorites.contains(song.id);
              return SongListTile(
                song: song,
                trailing: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.redAccent : Colors.white,
                  ),
                  onPressed: () => ref
                      .read(favoritesControllerProvider.notifier)
                      .toggleFavorite(song.id),
                ),
                onTap: () =>
                    ref.read(playbackControllerProvider).playSong(song, songs),
              );
            },
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => GenericErrorView(
          message: error.toString(),
          onRetry: () =>
              ref.read(favoritesControllerProvider.notifier).refresh(),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) {
        if (error is PermissionDeniedException) {
          return PermissionRequestCard(onRetry: () {
            ref
                .read(songListControllerProvider.notifier)
                .loadSongs(force: true);
          });
        }

        if (error is EmptyLibraryException) {
          return const EmptyLibraryMessage();
        }

        return GenericErrorView(
          message: error.toString(),
          onRetry: () => ref
              .read(songListControllerProvider.notifier)
              .loadSongs(force: true),
        );
      },
    );
  }
}
