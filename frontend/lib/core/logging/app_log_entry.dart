import 'package:teeq/core/logging/app_log_level.dart';

/// 디버그 콘솔에 쌓이는 앱 로그 한 건.
final class AppLogEntry {
  const AppLogEntry({
    required this.timestamp,
    required this.level,
    required this.name,
    required this.message,
    this.errorDescription,
    this.stackTraceText,
  });

  final DateTime timestamp;
  final AppLogLevel level;

  /// 로그를 남긴 곳의 이름(예: `ErrorHandler`).
  final String name;
  final String message;
  final String? errorDescription;
  final String? stackTraceText;
}
