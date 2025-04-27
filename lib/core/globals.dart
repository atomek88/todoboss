// Global keys and utilities
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:talker/talker.dart';
import 'package:talker_flutter/talker_flutter.dart';

class AppGlobals {
  static final navigatorKey = GlobalKey<NavigatorState>();
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
}

/// Global logger instance for the entire app
final talker = TalkerFlutter.init(
  settings: TalkerSettings(
    // Enable logs in debug mode only
    enabled: kDebugMode,
    // Use pretty console logger in debug mode
    useConsoleLogs: kDebugMode,
    // Maximum number of logs to keep in memory
    maxHistoryItems: 1000,
  ),
  // Configure logger with different log levels
  logger: TalkerLogger(
    settings: TalkerLoggerSettings(
      // Configure colored output
      enableColors: true,
      // Configure log levels
      level: LogLevel.debug,
    ),
  ),
);

/// Extension on Object to add logging capabilities to any class
extension LoggerExtension on Object {
  /// Log debug message
  void logDebug(String message) {
    talker.debug('[$runtimeType] $message');
  }

  /// Log info message
  void logInfo(String message) {
    talker.info('[$runtimeType] $message');
  }

  /// Log warning message
  void logWarning(String message) {
    talker.warning('[$runtimeType] $message');
  }

  /// Log error message
  void logError(String message,
      [Exception? exception, StackTrace? stackTrace]) {
    talker.error('[$runtimeType] $message', exception, stackTrace);
  }
}
