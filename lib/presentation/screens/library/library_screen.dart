import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_exceptions.dart';
import '../../../domain/entities/playlist.dart';
import '../../../domain/entities/song.dart';
import '../../controllers/library/favorites_controller.dart';
import '../../controllers/library/library_content_providers.dart';
import '../../controllers/library/playlist_controller.dart';
import '../../controllers/playback_controller.dart';
import '../../controllers/song_list_controller.dart';
import '../../widgets/dialogs/create_playlist_dialog.dart';
import '../../widgets/player/mini_player.dart';
import '../../widgets/song/song_list_tile.dart';
import '../../widgets/common/library_states.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  static const _tabs = [
    Tab(text: 'Favorites'),
    Tab(text: 'Playlists'),
    Tab(text: 'Tracks'),
    Tab(text: 'Albums'),
    Tab(text: 'Artists'),
  ];
  static const _tracksTabIndex = 2;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(songListControllerProvider.notifier).loadSongs(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlistsAsync = ref.watch(playlistControllerProvider);
    final favoritesAsync = ref.watch(favoritesControllerProvider);
    final songs = ref.watch(songsCatalogProvider);

    return DefaultTabController(
      length: _tabs.length,
      initialIndex: _tracksTabIndex,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 720;
              final horizontalPadding =
                  isWide ? (constraints.maxWidth - 640) / 2 : 16.0;

              return Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding.clamp(16.0, 48.0)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 12, 0, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Sonix Music',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Your offline library',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Search library',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Global search coming soon')),
                              );
                            },
                            icon: const Icon(Icons.search),
                          ),
                          IconButton(
                            tooltip: 'Library options',
                            onPressed: () {
                              showModalBottomSheet<void>(
                                context: context,
                                backgroundColor: AppColors.surface,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(24)),
                                ),
                                builder: (_) => Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      Text('Library settings',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                      SizedBox(height: 12),
                                      Text(
                                          'Sorting, filtering and other preferences will live here soon.'),
                                      SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.more_vert),
                          ),
                        ],
                      ),
                    ),
                    Theme(
                      data: Theme.of(context).copyWith(
                        splashFactory: NoSplash.splashFactory,
                        highlightColor: Colors.transparent,
                      ),
                      child: const TabBar(
                        isScrollable: true,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelStyle: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                        labelColor: Colors.white,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicator: UnderlineTabIndicator(
                          borderSide:
                              BorderSide(color: AppColors.accent, width: 3),
                          insets: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        tabs: _tabs,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TabBarView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _FavoritesTab(
                              songs: songs, favoritesAsync: favoritesAsync),
                          _PlaylistsTab(playlistsAsync: playlistsAsync),
                          _TracksTab(songs: songs),
                          const _AlbumsTab(),
                          const _ArtistsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: const SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: MiniPlayer(),
          ),
        ),
      ),
    );
  }
}

class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab({required this.songs, required this.favoritesAsync});

  final List<Song> songs;
  final AsyncValue<Set<int>> favoritesAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return favoritesAsync.when(
      data: (favorites) {
        final favoriteSongs = songs
            .where((song) => favorites.contains(song.id))
            .toList(growable: false);
        if (favoriteSongs.isEmpty) {
          return const _EmptyState(
            icon: Icons.favorite_border,
            title: 'No favorites yet',
            subtitle: 'Mark songs as favorites to find them here quickly.',
          );
        }

        return _SongListView(songs: favoriteSongs);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => GenericErrorView(
        message: error.toString(),
        onRetry: () => ref.read(favoritesControllerProvider.notifier).refresh(),
      ),
    );
  }
}

class _PlaylistsTab extends ConsumerWidget {
  const _PlaylistsTab({required this.playlistsAsync});

  final AsyncValue<List<Playlist>> playlistsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return playlistsAsync.when(
      data: (playlists) {
        if (playlists.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _EmptyState(
                    icon: Icons.queue_music,
                    title: 'No playlists',
                    subtitle:
                        'Create your first playlist and start organizing music.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      final created =
                          await showCreatePlaylistDialog(context, ref);
                      if (created) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Playlist created')),
                        );
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create playlist'),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
          itemCount: playlists.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _PlaylistCreateTile(onCreate: () async {
                final created = await showCreatePlaylistDialog(context, ref);
                if (created) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Playlist created')),
                  );
                }
              });
            }

            final playlist = playlists[index - 1];
            return ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              tileColor: AppColors.surface,
              leading: CircleAvatar(
                backgroundColor: AppColors.surfaceAlt,
                child: const Icon(Icons.queue_music),
              ),
              title: Text(playlist.name),
              subtitle: Text(
                '${playlist.songIds.length} song${playlist.songIds.length == 1 ? '' : 's'} · ${_formatDate(playlist.createdAt)}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showPlaylistActions(context, ref, playlist),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Playlist "${playlist.name}" playback coming soon'),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(24),
        child: GenericErrorView(
          message: error.toString(),
          onRetry: () =>
              ref.read(playlistControllerProvider.notifier).refresh(),
        ),
      ),
    );
  }

  void _showPlaylistActions(
      BuildContext context, WidgetRef ref, Playlist playlist) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(playlist.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename playlist'),
              onTap: () async {
                Navigator.of(context).pop();
                final controller = TextEditingController(text: playlist.name);
                final renamed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Rename playlist'),
                    content: TextField(
                      controller: controller,
                      autofocus: true,
                      decoration:
                          const InputDecoration(hintText: 'Playlist name'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () {
                          if (controller.text.trim().isEmpty) return;
                          Navigator.of(dialogContext).pop(true);
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                );

                if (renamed == true) {
                  await ref
                      .read(playlistControllerProvider.notifier)
                      .rename(playlist.id, controller.text.trim());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Renamed to "${controller.text.trim()}"')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete playlist'),
              onTap: () async {
                Navigator.of(context).pop();
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Delete playlist?'),
                    content:
                        Text('"${playlist.name}" will be removed from Sonix.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await ref
                      .read(playlistControllerProvider.notifier)
                      .delete(playlist.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deleted "${playlist.name}"')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _TracksTab extends ConsumerWidget {
  const _TracksTab({required this.songs});

  final List<Song> songs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(songListControllerProvider);

    return songsAsync.when(
      data: (songsData) {
        if (songsData.isEmpty) {
          return const EmptyLibraryMessage();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Sorting options coming soon')),
                      );
                    },
                    icon: const Icon(Icons.sort),
                    label: const Text('Date added'),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Shuffle play',
                    onPressed: () {
                      ref.read(playbackControllerProvider).playSongs(songsData);
                    },
                    icon: const Icon(Icons.shuffle),
                  ),
                  IconButton(
                    tooltip: 'Play all',
                    onPressed: () {
                      if (songsData.isNotEmpty) {
                        ref
                            .read(playbackControllerProvider)
                            .playSongs(songsData);
                      }
                    },
                    icon: const Icon(Icons.play_circle_fill),
                  ),
                ],
              ),
            ),
            Expanded(child: _SongListView(songs: songsData)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
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

class _AlbumsTab extends ConsumerWidget {
  const _AlbumsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(albumCollectionsProvider);
    if (albums.isEmpty) {
      return const _EmptyState(
        icon: Icons.album_outlined,
        title: 'No albums found',
        subtitle: 'Albums from your library will appear here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      itemCount: albums.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final album = albums[index];
        return ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          tileColor: AppColors.surface,
          leading: CircleAvatar(
            backgroundColor: AppColors.surfaceAlt,
            child: const Icon(Icons.album),
          ),
          title: Text(album.name),
          subtitle: Text(
              '${album.artist} · ${album.songs.length} track${album.songs.length == 1 ? '' : 's'}'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Album "${album.name}" playback coming soon')),
            );
          },
        );
      },
    );
  }
}

class _ArtistsTab extends ConsumerWidget {
  const _ArtistsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artists = ref.watch(artistCollectionsProvider);
    if (artists.isEmpty) {
      return const _EmptyState(
        icon: Icons.person_outline,
        title: 'No artists yet',
        subtitle: 'Artists detected from your library will show up here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      itemCount: artists.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final artist = artists[index];
        return ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          tileColor: AppColors.surface,
          leading: CircleAvatar(
            backgroundColor: AppColors.surfaceAlt,
            child: const Icon(Icons.person),
          ),
          title: Text(artist.name),
          subtitle: Text(
              '${artist.songs.length} track${artist.songs.length == 1 ? '' : 's'}'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Artist "${artist.name}" view coming soon')),
            );
          },
        );
      },
    );
  }
}

class _SongListView extends ConsumerWidget {
  const _SongListView({required this.songs});

  final List<Song> songs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: songs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final song = songs[index];
        return SongListTile(
          song: song,
          onTap: () =>
              ref.read(playbackControllerProvider).playSong(song, songs),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistCreateTile extends StatelessWidget {
  const _PlaylistCreateTile({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: AppColors.surfaceAlt,
      leading: const Icon(Icons.add, color: Colors.white),
      title: const Text('Create new playlist'),
      onTap: onCreate,
    );
  }
}
