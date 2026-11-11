// audio_session의 장치 조회 API(AudioDevice, AudioDeviceType)는 패키지에서 experimental로 표시되어 있다.
// ignore_for_file: experimental_member_use

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/logging/app_log_level.dart';
import 'package:teeq/core/logging/app_logger.dart';
import 'package:teeq/features/call/domain/call_audio_environment.dart';

part 'platform_call_audio_environment.g.dart';

/// `audio_session`의 장치 조회와 안드로이드 MethodChannel로 오디오 환경을 읽는다.
/// 세션 설정·활성화·인터럽션 구독은 하지 않고 장치 조회만 한다.
///
/// 조회 실패는 던지지 않고 경고 로그를 남긴 뒤 false로 처리한다.
final class PlatformCallAudioEnvironment implements CallAudioEnvironment {
  PlatformCallAudioEnvironment(this._logger);

  static const String _logName = 'PlatformCallAudioEnvironment';
  static const MethodChannel _channel = MethodChannel('teeq/call_audio');
  static const String _getRingerModeMethod = 'getRingerMode';

  /// `AudioManager.RINGER_MODE_NORMAL` 값.
  static const int _ringerModeNormal = 2;

  /// 내장 이어피스·스피커를 뺀 이어폰(유선·블루투스) 출력 장치 종류.
  static const Set<AudioDeviceType> _headsetDeviceTypes = {
    AudioDeviceType.wiredHeadset,
    AudioDeviceType.wiredHeadphones,
    AudioDeviceType.bluetoothSco,
    AudioDeviceType.bluetoothA2dp,
    AudioDeviceType.bluetoothLe,
  };

  final AppLogger _logger;

  @override
  Stream<bool> get headsetConnectionChanges async* {
    try {
      final session = await AudioSession.instance;
      yield* session.devicesChangedEventStream
          .asyncMap((_) => isHeadsetConnected())
          .distinct();
    } on Object catch (error) {
      _logWarning('이어폰 연결 변화 구독 실패', error);
    }
  }

  @override
  Future<bool> isHeadsetConnected() async {
    try {
      final session = await AudioSession.instance;
      final devices = await session.getDevices(includeInputs: false);
      return devices.any(
        (device) =>
            device.isOutput && _headsetDeviceTypes.contains(device.type),
      );
    } on Object catch (error) {
      _logWarning('이어폰 연결 확인 실패', error);
      return false;
    }
  }

  @override
  Future<bool> isRingerSilent() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      final ringerMode = await _channel.invokeMethod<int>(_getRingerModeMethod);
      return ringerMode != null && ringerMode != _ringerModeNormal;
    } on Object catch (error) {
      _logWarning('무음 모드 확인 실패', error);
      return false;
    }
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
CallAudioEnvironment callAudioEnvironment(Ref ref) =>
    PlatformCallAudioEnvironment(ref.watch(appLoggerProvider));
