import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/library/playlist_controller.dart';

Future<bool> showCreatePlaylistDialog(
    BuildContext context, WidgetRef ref) async {
  final nameController = TextEditingController();
  final created = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('New playlist'),
        content: TextField(
          controller: nameController,
          autofocus: true,
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
              if (nameController.text.trim().isEmpty) {
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
        .createPlaylist(nameController.text);
    nameController.dispose();
    return true;
  }

  nameController.dispose();
  return false;
}
