import 'dart:developer' as developer;

class AppLogger {
  const AppLogger._();

  static void info(String message, {String name = 'Sonix'}) {
    developer.log(message, name: name);
  }

  static void error(Object error,
      {String name = 'Sonix', StackTrace? stackTrace}) {
    developer.log('Error: $error', name: name, stackTrace: stackTrace);
  }
}
