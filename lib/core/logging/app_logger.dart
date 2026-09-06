import 'package:flutter/foundation.dart';

/// Structured, privacy-conscious logger for Project Sift.
class AppLogger {
  final String scope;

  const AppLogger(this.scope);

  void d(String message, [Object? extra]) {
    if (kDebugMode) {
      debugPrint(
          '[DEBUG][$scope] $message ${extra != null ? extra.toString() : ''}');
    }
  }

  void i(String message, [Object? extra]) {
    if (kDebugMode) {
      debugPrint(
          '[INFO][$scope] $message ${extra != null ? extra.toString() : ''}');
    }
  }

  void w(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint(
        '[WARN][$scope] $message ${error != null ? 'Error: $error' : ''}');
    if (stackTrace != null && kDebugMode) {
      debugPrint(stackTrace.toString());
    }
  }

  void e(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint(
        '[ERROR][$scope] $message ${error != null ? 'Error: $error' : ''}');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}
