class PermissionDeniedException implements Exception {
  PermissionDeniedException([this.message]);

  final String? message;

  @override
  String toString() => message ?? 'Permission denied';
}

class EmptyLibraryException implements Exception {
  EmptyLibraryException([this.message]);

  final String? message;

  @override
  String toString() => message ?? 'No audio files were found on this device.';
}
