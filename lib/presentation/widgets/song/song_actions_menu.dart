import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/song.dart';
import '../../controllers/library/favorites_controller.dart';
import '../../controllers/library/playlist_controller.dart';
import '../dialogs/create_playlist_dialog.dart';

class SongActionsMenu extends ConsumerWidget {
  const SongActionsMenu({super.key, required this.song});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesControllerProvider);
    final isFavorite = favoritesAsync.maybeWhen(
      data: (favorites) => favorites.contains(song.id),
      orElse: () => false,
    );

    return PopupMenuButton<_SongAction>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (action) => _handleAction(context, ref, action, isFavorite),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _SongAction.addToPlaylist,
          child: Text('Add to playlist'),
        ),
        PopupMenuItem(
          value: _SongAction.toggleFavorite,
          child:
              Text(isFavorite ? 'Remove from favorites' : 'Add to favorites'),
        ),
        const PopupMenuItem(
          value: _SongAction.delete,
          child: Text('Delete music'),
        ),
        const PopupMenuItem(
          value: _SongAction.details,
          child: Text('Song details'),
        ),
      ],
    );
  }

  void _handleAction(
    BuildContext context,
    WidgetRef ref,
    _SongAction action,
    bool isFavorite,
  ) {
    switch (action) {
      case _SongAction.addToPlaylist:
        showAddToPlaylistSheet(context, ref, [song]);
        break;
      case _SongAction.toggleFavorite:
        ref.read(favoritesControllerProvider.notifier).toggleFavorite(song.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFavorite ? 'Removed from favorites' : 'Added to favorites',
            ),
          ),
        );
        break;
      case _SongAction.delete:
        _showDeleteNotSupported(context);
        break;
      case _SongAction.details:
        _showSongDetails(context, song);
        break;
    }
  }
}

enum _SongAction { addToPlaylist, toggleFavorite, delete, details }

Future<void> showAddToPlaylistSheet(
  BuildContext context,
  WidgetRef ref,
  List<Song> songs,
) async {
  if (songs.isEmpty) return;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Consumer(
          builder: (context, ref, _) {
            final playlistsAsync = ref.watch(playlistControllerProvider);
            return playlistsAsync.when(
              data: (playlists) {
                if (playlists.isEmpty) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        songs.length == 1
                            ? 'Add to playlist'
                            : 'Add ${songs.length} tracks',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'You have no playlists yet. Create one to start adding songs.',
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () async {
                          final created = await showCreatePlaylistDialog(
                            sheetContext,
                            ref,
                          );
                          if (created) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Playlist created'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.playlist_add),
                        label: const Text('Create playlist'),
                      ),
                    ],
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add to playlist',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final created = await showCreatePlaylistDialog(
                              sheetContext,
                              ref,
                            );
                            if (created) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Playlist created'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('New playlist'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...playlists.map(
                      (playlist) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading:
                            const Icon(Icons.queue_music, color: Colors.white),
                        title: Text(playlist.name),
                        subtitle: Text(
                          '${playlist.songIds.length} song${playlist.songIds.length == 1 ? '' : 's'}',
                        ),
                        onTap: () async {
                          final notifier =
                              ref.read(playlistControllerProvider.notifier);
                          for (final track in songs) {
                            await notifier.addSong(playlist.id, track.id);
                          }
                          Navigator.of(sheetContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                songs.length == 1
                                    ? 'Added to "${playlist.name}"'
                                    : 'Added ${songs.length} tracks to "${playlist.name}"',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Something went wrong loading playlists'),
                  const SizedBox(height: 12),
                  Text(
                    error.toString(),
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        ref.read(playlistControllerProvider.notifier).refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

void _showSongDetails(BuildContext context, Song song) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Song details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _DetailRow(label: 'Title', value: song.title),
            _DetailRow(label: 'Artist', value: song.artist),
            _DetailRow(label: 'Album', value: song.album),
            _DetailRow(
              label: 'Duration',
              value: _formatDuration(song.duration),
            ),
            if (song.uri.isNotEmpty)
              _DetailRow(label: 'Source', value: song.uri),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}

void _showDeleteNotSupported(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Delete music'),
        content: const Text(
          'Removing audio files requires elevated device permissions and is not yet supported inside Sonix.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

String _formatDuration(int durationMs) {
  final duration = Duration(milliseconds: durationMs);
  final minutes = duration.inMinutes;
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
