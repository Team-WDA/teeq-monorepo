import 'dart:async';

import 'package:proximity_sensor/proximity_sensor.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/logging/app_log_level.dart';
import 'package:teeq/core/logging/app_logger.dart';
import 'package:teeq/features/call/domain/call_proximity_screen.dart';

part 'platform_call_proximity_screen.g.dart';

/// `proximity_sensor` 패키지로 근접 센서 화면 끄기를 제어한다.
/// 안드로이드는 `PROXIMITY_SCREEN_OFF_WAKE_LOCK`, iOS는 근접 모니터링이 화면을 끈다.
/// 두 플랫폼 모두 센서 이벤트 스트림을 구독하는 동안에만 동작하므로, 이벤트 값은 쓰지 않고 구독만 유지한다.
///
/// 시작·종료 실패는 통화를 막지 않도록 던지지 않고 경고 로그로 남긴다.
final class PlatformCallProximityScreen implements CallProximityScreen {
  PlatformCallProximityScreen(this._logger);

  static const String _logName = 'PlatformCallProximityScreen';

  final AppLogger _logger;
  StreamSubscription<int>? _subscription;
  Future<void> _lastOperation = Future<void>.value();

  @override
  Future<void> enable() => _runInOrder(() async {
    if (_subscription != null) {
      return;
    }
    try {
      // 안드로이드는 구독 시작 시점에 wake lock을 잡으므로 구독보다 먼저 켠다.
      await ProximitySensor.setProximityScreenOff(true);
      _subscription = ProximitySensor.events.listen(
        (_) {},
        onError: (Object error) => _logWarning('근접 센서 이벤트 오류', error),
      );
    } on Object catch (error) {
      _logWarning('근접 센서 화면 끄기 켜기 실패', error);
    }
  });

  @override
  Future<void> disable() => _runInOrder(() async {
    final subscription = _subscription;
    _subscription = null;
    // 구독 취소가 실패해도 화면 끄기 해제는 항상 실행되도록 단계를 나눈다.
    try {
      await subscription?.cancel();
    } on Object catch (error) {
      _logWarning('근접 센서 구독 취소 실패', error);
    }
    try {
      await ProximitySensor.setProximityScreenOff(false);
    } on Object catch (error) {
      _logWarning('근접 센서 화면 끄기 끄기 실패', error);
    }
  });

  /// enable·disable이 겹쳐 불려도 호출 순서대로 하나씩 실행해, 마지막 호출의 결과로 끝나게 한다.
  Future<void> _runInOrder(Future<void> Function() operation) {
    final next = _lastOperation.then((_) => operation());
    _lastOperation = next;
    return next;
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

@Riverpod(keepAlive: true)
CallProximityScreen callProximityScreen(Ref ref) =>
    PlatformCallProximityScreen(ref.watch(appLoggerProvider));
