import 'package:flutter/foundation.dart';
import 'package:teeq/core/logging/app_log_level.dart';
import 'package:teeq/core/logging/app_logger.dart';

/// 처리되지 않은 에러와 `debugPrint` 출력을 [logger]로도 모은다.
///
/// 기존 핸들러는 그대로 실행하므로 콘솔 출력과 크래시 처리 동작은 바뀌지 않는다.
void installGlobalLogHooks(AppLogger logger) {
  final previousFlutterErrorHandler = FlutterError.onError;
  final previousDebugPrint = debugPrint;
  final previousPlatformErrorHandler = PlatformDispatcher.instance.onError;

  // 기존 핸들러(`presentError`)는 에러를 `debugPrint`로 여러 줄 덤프한다. 그 줄들은
  // 이미 에러 한 건으로 기록했으므로 디버그 로그로 다시 쌓지 않는다.
  var isHandlingFlutterError = false;

  FlutterError.onError = (details) {
    logger.log(
      details.exceptionAsString(),
      name: 'FlutterError',
      level: AppLogLevel.error,
      error: details.exception,
      stackTrace: details.stack,
    );
    isHandlingFlutterError = true;
    try {
      previousFlutterErrorHandler?.call(details);
    } finally {
      isHandlingFlutterError = false;
    }
  };

  debugPrint = (message, {wrapWidth}) {
    if (!isHandlingFlutterError && message != null) {
      logger.log(message, name: 'debugPrint', level: AppLogLevel.debug);
    }
    previousDebugPrint(message, wrapWidth: wrapWidth);
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    logger.log(
      '처리되지 않은 예외',
      name: 'PlatformDispatcher',
      level: AppLogLevel.error,
      error: error,
      stackTrace: stackTrace,
    );
    return previousPlatformErrorHandler?.call(error, stackTrace) ?? false;
  };
}
