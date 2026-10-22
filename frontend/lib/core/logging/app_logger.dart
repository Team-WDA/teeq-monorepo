import 'dart:async';
import 'dart:developer' as developer;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/debug_console/debug_console_store.dart';
import 'package:teeq/core/logging/app_log_entry.dart';
import 'package:teeq/core/logging/app_log_level.dart';

part 'app_logger.g.dart';

/// 앱의 로그를 남기는 한 곳. `dart:developer`로 내보내고, [onEntry]가 있으면 같은 내용을 넘긴다.
class AppLogger {
  AppLogger({this.onEntry, this._clock = DateTime.now});

  /// 로그 한 건을 받는 쪽. 디버그 콘솔 저장소가 여기에 연결된다.
  final void Function(AppLogEntry entry)? onEntry;
  final DateTime Function() _clock;

  void log(
    String message, {
    required String name,
    AppLogLevel level = AppLogLevel.info,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: name,
      level: level.developerLogValue,
      error: error,
      stackTrace: stackTrace,
    );
    onEntry?.call(
      AppLogEntry(
        timestamp: _clock(),
        level: level,
        name: name,
        message: message,
        errorDescription: error?.toString(),
        stackTraceText: stackTrace?.toString(),
      ),
    );
  }
}

/// 위젯을 빌드하는 도중 발생한 `FlutterError`가 이 로거로 들어오면 provider 상태를 바꾸는 순간
/// Riverpod이 "빌드 중 provider 수정" 오류를 낸다. 그래서 저장소 기록은 마이크로태스크로 미룬다.
@Riverpod(keepAlive: true)
AppLogger appLogger(Ref ref) {
  final store = ref.read(debugConsoleStoreProvider.notifier);
  return AppLogger(
    onEntry: (entry) => scheduleMicrotask(() => store.recordLog(entry)),
  );
}
