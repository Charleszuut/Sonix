import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/library/playlist_controller.dart';

Future<bool> showCreatePlaylistDialog(
    BuildContext context, WidgetRef ref) async {
  var playlistName = '';
  final created = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('New playlist'),
        content: TextField(
          autofocus: true,
          onChanged: (value) => playlistName = value,
          decoration: const InputDecoration(
            hintText: 'Playlist name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (playlistName.trim().isEmpty) {
                return;
              }
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('Create'),
          ),
        ],
      );
    },
  );

  if (created == true) {
    await ref
        .read(playlistControllerProvider.notifier)
        .createPlaylist(playlistName.trim());
    return true;
  }

  return false;
}
