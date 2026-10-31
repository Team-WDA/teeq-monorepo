import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/logging/app_log_level.dart';
import 'package:teeq/core/logging/app_logger.dart';
import 'package:teeq/features/call/domain/call_keep_alive.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

part 'foreground_call_keep_alive.g.dart';

/// 통화 중 화면 꺼짐을 막고, 안드로이드에서는 마이크 타입 포그라운드 서비스(알림)를 띄운다.
/// iOS는 백그라운드 오디오 모드로 유지되므로 화면 꺼짐 방지만 한다.
///
/// 시작·종료 실패는 통화를 막지 않도록 던지지 않고 경고 로그로 남긴다.
final class ForegroundCallKeepAlive implements CallKeepAlive {
  ForegroundCallKeepAlive(this._logger);

  static const String _logName = 'ForegroundCallKeepAlive';
  static const String _notificationTitle = 'TeeQ';
  static const String _notificationChannelId = 'call_in_progress';
  static const String _notificationChannelName = '통화 중';
  static const int _serviceId = 1001;

  final AppLogger _logger;
  bool _isForegroundTaskInitialized = false;
  Future<void> _lastOperation = Future<void>.value();

  bool get _usesForegroundService =>
      defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> start({required String notificationBody}) =>
      _runInOrder(() async {
        await _runLoggingFailure('화면 꺼짐 방지 켜기 실패', WakelockPlus.enable);
        if (_usesForegroundService) {
          await _runLoggingFailure(
            '포그라운드 서비스 시작 실패',
            () => _startForegroundService(notificationBody),
          );
        }
      });

  @override
  Future<void> stop() => _runInOrder(() async {
    await _runLoggingFailure('화면 꺼짐 방지 끄기 실패', WakelockPlus.disable);
    if (_usesForegroundService) {
      await _runLoggingFailure('포그라운드 서비스 종료 실패', _stopForegroundService);
    }
  });

  /// start·stop이 겹쳐 불려도 호출 순서대로 하나씩 실행해, 마지막 호출의 결과(예: stop이면 서비스 종료)로 끝나게 한다.
  Future<void> _runInOrder(Future<void> Function() operation) {
    final next = _lastOperation.then((_) => operation());
    _lastOperation = next;
    return next;
  }

  /// 단계 하나의 실패가 통화와 다음 단계를 막지 않도록 예외를 경고 로그로 바꾼다.
  Future<void> _runLoggingFailure(
    String message,
    Future<void> Function() step,
  ) async {
    try {
      await step();
    } on Object catch (error) {
      _logWarning(message, error);
    }
  }

  Future<void> _startForegroundService(String notificationBody) async {
    _initializeForegroundTaskOnce();
    if (await FlutterForegroundTask.isRunningService) {
      return;
    }
    final result = await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      serviceTypes: const [ForegroundServiceTypes.microphone],
      notificationTitle: _notificationTitle,
      notificationText: notificationBody,
      // null이면 앱 아이콘을 쓴다.
      notificationIcon: null,
      callback: startCallKeepAliveTaskHandler,
    );
    if (result is ServiceRequestFailure) {
      _logWarning('포그라운드 서비스 시작 실패', result.error);
    }
  }

  Future<void> _stopForegroundService() async {
    if (!await FlutterForegroundTask.isRunningService) {
      return;
    }
    final result = await FlutterForegroundTask.stopService();
    if (result is ServiceRequestFailure) {
      _logWarning('포그라운드 서비스 종료 실패', result.error);
    }
  }

  void _initializeForegroundTaskOnce() {
    if (_isForegroundTaskInitialized) {
      return;
    }
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _notificationChannelId,
        channelName: _notificationChannelName,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      // 앱 작업이 사라지면 서비스도 함께 끝내고(잔존 알림 방지), 시스템이 죽인 서비스를
      // 다시 띄우거나 부팅 시 자동 시작하지 않는다. 화면 유지는 wakelock이 맡는다.
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: false,
        allowAutoRestart: false,
        stopWithTask: true,
      ),
    );
    // init이 끝난 뒤에만 표시해 실패하면 다음 start에서 다시 시도한다.
    // start·stop은 _runInOrder로 직렬화되므로 동시에 두 번 초기화되지 않는다.
    _isForegroundTaskInitialized = true;
  }

  void _logWarning(String message, Object error) {
    _logger.log(
      '$message: ${error.runtimeType}',
      name: _logName,
      level: AppLogLevel.warning,
      error: error,
    );
  }
}

/// 포그라운드 서비스가 띄우는 작업 핸들러 진입점. 최상위 함수여야 한다.
@pragma('vm:entry-point')
void startCallKeepAliveTaskHandler() {
  FlutterForegroundTask.setTaskHandler(_CallKeepAliveTaskHandler());
}

/// 알림 유지만 하는 핸들러. 통화 처리는 앱 쪽 isolate가 한다.
class _CallKeepAliveTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // 앱 없이 시스템이 서비스를 다시 띄운 경우는 통화가 없으므로 바로 내려 잔존 알림을 지운다.
    if (starter == TaskStarter.system) {
      await FlutterForegroundTask.stopService();
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

@Riverpod(keepAlive: true)
CallKeepAlive callKeepAlive(Ref ref) =>
    ForegroundCallKeepAlive(ref.watch(appLoggerProvider));
