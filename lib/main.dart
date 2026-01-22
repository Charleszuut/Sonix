import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/audio/sonix_audio_handler.dart';
import 'core/init/hive_initializer.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/permission_manager.dart';
import 'presentation/controllers/providers.dart';
import 'presentation/screens/library/library_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveInitializer.init();
  await PermissionManager.ensureNotificationPermission();

  final audioHandler = await AudioService.init(
    builder: SonixAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.sonix.player.channel',
      androidNotificationChannelName: 'Sonix Playback',
      androidNotificationOngoing: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const SonixApp(),
    ),
  );
}

class SonixApp extends ConsumerWidget {
  const SonixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Sonix',
      debugShowCheckedModeBanner: false,
      theme: buildDarkTheme(),
      home: const LibraryScreen(),
    );
  }
}
