import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  const PermissionManager._();

  static Future<bool> ensureAudioPermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final audioStatus = await Permission.audio.status;
    if (audioStatus.isGranted || audioStatus.isLimited) {
      return true;
    }

    final requestedAudio = await Permission.audio.request();
    if (requestedAudio.isGranted || requestedAudio.isLimited) {
      return true;
    }

    final storageStatus = await Permission.storage.status;
    if (storageStatus.isGranted || storageStatus.isLimited) {
      return true;
    }

    final requestedStorage = await Permission.storage.request();
    if (requestedStorage.isGranted || requestedStorage.isLimited) {
      return true;
    }

    return false;
  }

  static Future<bool> hasAudioPermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final audioStatus = await Permission.audio.status;
    if (audioStatus.isGranted || audioStatus.isLimited) {
      return true;
    }

    final storageStatus = await Permission.storage.status;
    return storageStatus.isGranted || storageStatus.isLimited;
  }

  static Future<bool> openSettings() {
    return openAppSettings();
  }

  static Future<void> ensureNotificationPermission() async {
    if (!Platform.isAndroid) {
      return;
    }

    final status = await Permission.notification.status;
    if (status.isGranted || status.isLimited) {
      return;
    }

    await Permission.notification.request();
  }
}
