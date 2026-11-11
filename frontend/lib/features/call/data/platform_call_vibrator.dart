import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/logging/app_log_level.dart';
import 'package:teeq/core/logging/app_logger.dart';
import 'package:teeq/features/call/domain/call_audio_timing.dart';
import 'package:teeq/features/call/domain/call_vibrator.dart';
import 'package:vibration/vibration.dart';

part 'platform_call_vibrator.g.dart';

/// 벨소리 구간 진동. 안드로이드는 반복 진동 패턴, iOS는 일정 간격 햅틱을 쓴다.
/// 진동 불가·실패는 통화를 막지 않도록 던지지 않고 경고 로그로 남긴다.
final class PlatformCallVibrator implements CallVibrator {
  PlatformCallVibrator(this._logger);

  static const String _logName = 'PlatformCallVibrator';

  /// 진동 패턴은 [대기, 켜짐, 꺼짐] 순서이며 처음부터 대기 없이 시작한다.
  static const int _noDelayMilliseconds = 0;

  /// 패턴의 첫 항목부터 반복한다.
  static const int _repeatFromStartIndex = 0;

  final AppLogger _logger;
  Timer? _hapticTimer;
  int _generation = 0;

  @override
  Future<void> startRinging() async {
    final generation = ++_generation;
    await _runLoggingFailure('진동 중지 실패', _cancelAll);
    if (generation != _generation) {
      return;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        await _runLoggingFailure(
          '벨소리 진동 시작 실패',
          () => _startAndroidPattern(generation),
        );
      case TargetPlatform.iOS:
        _hapticTimer = Timer.periodic(
          CallAudioTiming.iosRingingHapticInterval,
          (_) => unawaited(
            _runLoggingFailure('벨소리 햅틱 실패', HapticFeedback.heavyImpact),
          ),
        );
        unawaited(_runLoggingFailure('벨소리 햅틱 실패', HapticFeedback.heavyImpact));
      case TargetPlatform.fuchsia ||
          TargetPlatform.linux ||
          TargetPlatform.macOS ||
          TargetPlatform.windows:
        break;
    }
  }

  @override
  Future<void> stop() async {
    _generation++;
    await _runLoggingFailure('진동 중지 실패', _cancelAll);
  }

  Future<void> _startAndroidPattern(int generation) async {
    if (!await Vibration.hasVibrator()) {
      return;
    }
    // 확인하는 사이 stop이 불렸다면 시작하지 않는다.
    if (generation != _generation) {
      return;
    }
    await Vibration.vibrate(
      pattern: [
        _noDelayMilliseconds,
        CallAudioTiming.ringingVibrationOn.inMilliseconds,
        CallAudioTiming.ringingVibrationOff.inMilliseconds,
      ],
      repeat: _repeatFromStartIndex,
    );
  }

  Future<void> _cancelAll() async {
    _hapticTimer?.cancel();
    _hapticTimer = null;
    if (defaultTargetPlatform == TargetPlatform.android) {
      await Vibration.cancel();
    }
  }

  Future<void> _runLoggingFailure(
    String message,
    Future<void> Function() step,
  ) async {
    try {
      await step();
    } on Object catch (error) {
      _logger.log(
        '$message: ${error.runtimeType}',
        name: _logName,
        level: AppLogLevel.warning,
        error: error,
      );
    }
  }
}

@Riverpod(keepAlive: true)
CallVibrator callVibrator(Ref ref) =>
    PlatformCallVibrator(ref.watch(appLoggerProvider));
