import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_exceptions.dart';
import '../../controllers/library/favorites_controller.dart';
import '../../controllers/playback_controller.dart';
import '../../controllers/search_query_provider.dart';
import '../../controllers/song_list_controller.dart';
import '../../widgets/common/library_states.dart';
import '../../widgets/song/song_list_tile.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final songsAsync = ref.watch(songListControllerProvider);
    final favoritesAsync = ref.watch(favoritesControllerProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Songs, artists, albums',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) =>
                ref.read(searchQueryProvider.notifier).state = value.trim(),
          ),
        ),
        Expanded(
          child: songsAsync.when(
            data: (songs) {
              final filtered = songs.where((song) {
                if (query.isEmpty) return true;
                final q = query.toLowerCase();
                return song.title.toLowerCase().contains(q) ||
                    song.artist.toLowerCase().contains(q) ||
                    song.album.toLowerCase().contains(q);
              }).toList();

              if (filtered.isEmpty) {
                return const Center(
                    child: Text('No results match your search.'));
              }

              return favoritesAsync.when(
                data: (favorites) => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final song = filtered[index];
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
                      onTap: () => ref
                          .read(playbackControllerProvider)
                          .playSong(song, songs),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => GenericErrorView(
                  message: error.toString(),
                  onRetry: () =>
                      ref.read(favoritesControllerProvider.notifier).refresh(),
                ),
              );
            },
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
          ),
        ),
      ],
    );
  }
}
