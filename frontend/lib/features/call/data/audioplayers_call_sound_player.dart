import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/logging/app_log_level.dart';
import 'package:teeq/core/logging/app_logger.dart';
import 'package:teeq/features/call/domain/call_audio_timing.dart';
import 'package:teeq/features/call/domain/call_sound_player.dart';

part 'audioplayers_call_sound_player.g.dart';

/// audioplayers로 벨소리·연결음(반복)과 종료음(1회)을 재생한다.
///
/// 오디오 컨텍스트는 방 연결 전인 [startRingtone]과 [startConnectingTone]에서만 정하고,
/// 방 연결 뒤 출력 경로 변경은 LiveKit이 맡는다.
///
/// - iOS: 컨텍스트가 전역 하나뿐이라 전역으로 정한다(`playAndRecord`).
/// - 안드로이드: 전역 설정은 쓰지 않고 플레이어별로만 정한다. audioplayers_android의 전역 설정은
///   직전 기본값의 모드·스피커폰을 `AudioManager`에 쓰고, 새 플레이어가 그 기본값을 복사해
///   같은 값의 플레이어별 설정이 무시되기 때문이다. 플레이어별 설정은 `AudioManager` 모드와
///   스피커폰 값을 기기 전체에 쓰므로 항상 일반 모드·스피커폰 끔으로 두고, 경로는 용도(usage)로
///   고른다. LiveKit(AudioSwitch)은 방 연결 때 현재 모드를 저장했다가 통화 뒤 되돌리므로,
///   여기서 통화 모드를 쓰면 통화가 끝난 뒤에도 기기가 통화 모드로 남는다.
/// - 종료음은 두 플랫폼 모두 컨텍스트를 정하지 않는다(LiveKit 경로를 덮지 않는다).
///
/// 음원 파일이 없거나 재생이 실패해도 던지지 않고 경고 로그만 남긴다.
final class AudioplayersCallSoundPlayer implements CallSoundPlayer {
  AudioplayersCallSoundPlayer(this._logger);

  static const String _logName = 'AudioplayersCallSoundPlayer';
  static const double _fullVolume = 1;

  final AppLogger _logger;

  /// 시작·정지 순서를 호출 순서대로 직렬화한다.
  Future<void> _lastOperation = Future<void>.value();

  /// 시작·정지를 호출할 때마다 올린다. 실행 차례에 값이 달라졌으면 그 사이 정지가 불린 것이다.
  int _generation = 0;

  AudioPlayer? _loopingPlayer;
  AudioPlayer? _endTonePlayer;

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> startRingtone() {
    final generation = ++_generation;
    return _runInOrder(() async {
      if (generation != _generation) {
        return;
      }
      // keepAlive라 이전 통화의 컨텍스트가 남아 있으므로 벨소리는 항상 스피커 컨텍스트로 정한다.
      await _applyIosAudioContext(isSpeakerOn: true);
      await _startLooping(
        generation: generation,
        androidContext: _ringtoneAndroidContext,
        assetPath: AppAssets.callRingtoneSound,
        failureMessage: '벨소리 재생 실패',
      );
    });
  }

  @override
  Future<void> startConnectingTone({required bool isSpeakerOn}) {
    final generation = ++_generation;
    return _runInOrder(() async {
      if (generation != _generation) {
        return;
      }
      await _applyIosAudioContext(isSpeakerOn: isSpeakerOn);
      await _startLooping(
        generation: generation,
        androidContext: _buildConnectingToneAndroidContext(
          isSpeakerOn: isSpeakerOn,
        ),
        assetPath: AppAssets.callConnectingToneSound,
        failureMessage: '연결음 재생 실패',
      );
    });
  }

  @override
  Future<void> stopLoopingTone({required bool shouldFadeOut}) {
    _generation++;
    return _runInOrder(() async {
      await _runLoggingFailure('반복 소리 정지 실패', () async {
        final player = _loopingPlayer;
        _loopingPlayer = null;
        if (player == null) {
          return;
        }
        if (shouldFadeOut) {
          await _fadeOut(player);
        }
        await _stopAndDispose(player);
      });
    });
  }

  /// 종료음은 컨텍스트를 정하지 않는다. 안드로이드는 플레이어 기본값(미디어 용도)으로 재생해
  /// `AudioManager` 모드·스피커폰을 쓰지 않고, iOS는 전역 컨텍스트를 건드리지 않는다.
  @override
  Future<void> playEndTone() async {
    AudioPlayer? player;
    try {
      final previous = _endTonePlayer;
      _endTonePlayer = null;
      if (previous != null) {
        await _stopAndDispose(previous);
      }
      final created = _createPlayer(ReleaseMode.release);
      player = created;
      _endTonePlayer = created;
      unawaited(
        // 재생 전에 해제되면 스트림이 닫혀 오류로 끝나므로 완료·해제 모두 조용히 정리한다.
        created.onPlayerComplete.first.then<void>(
          (_) => _disposeEndTone(created),
          onError: (Object _) {},
        ),
      );
      await created.play(AssetSource(AppAssets.callEndToneSound));
    } on Object catch (error) {
      _logWarning('종료음 재생 실패', error);
      if (player != null) {
        await _disposeEndTone(player);
      }
    }
  }

  Future<void> _disposeEndTone(AudioPlayer player) async {
    if (identical(_endTonePlayer, player)) {
      _endTonePlayer = null;
    }
    await _runLoggingFailure('종료음 정리 실패', player.dispose);
  }

  /// 방 연결 전에만 호출한다. iOS 컨텍스트는 전역이라 여기서 정하고, 안드로이드는 정하지 않는다.
  Future<void> _applyIosAudioContext({required bool isSpeakerOn}) async {
    if (_isAndroid) {
      return;
    }
    await _runLoggingFailure(
      '오디오 컨텍스트 설정 실패',
      () => AudioPlayer.global.setAudioContext(
        AudioContext(iOS: _buildIosAudioContext(isSpeakerOn: isSpeakerOn)),
      ),
    );
  }

  Future<void> _startLooping({
    required int generation,
    required AudioContextAndroid androidContext,
    required String assetPath,
    required String failureMessage,
  }) => _runLoggingFailure(failureMessage, () async {
    // 실행 차례가 오기 전에 정지·새 시작이 불렸다면 재생하지 않는다.
    if (generation != _generation) {
      return;
    }
    final previous = _loopingPlayer;
    _loopingPlayer = null;
    if (previous != null) {
      await _stopAndDispose(previous);
    }
    final player = _createPlayer(ReleaseMode.loop);
    _loopingPlayer = player;
    if (_isAndroid) {
      await player.setAudioContext(AudioContext(android: androidContext));
    }
    await player.play(AssetSource(assetPath), volume: _fullVolume);
  });

  AudioPlayer _createPlayer(ReleaseMode releaseMode) {
    // 에셋 경로가 이미 'assets/'를 포함하므로 audioplayers 기본 접두사를 끈다.
    final player = AudioPlayer()..audioCache = AudioCache(prefix: '');
    unawaited(
      _runLoggingFailure(
        '재생 모드 설정 실패',
        () => player.setReleaseMode(releaseMode),
      ),
    );
    return player;
  }

  Future<void> _fadeOut(AudioPlayer player) async {
    const stepCount = CallAudioTiming.connectingToneFadeStepCount;
    final stepDuration = CallAudioTiming.connectingToneFadeOut ~/ stepCount;
    for (var step = 1; step <= stepCount; step++) {
      await Future<void>.delayed(stepDuration);
      await player.setVolume(_fullVolume * (stepCount - step) / stepCount);
    }
  }

  Future<void> _stopAndDispose(AudioPlayer player) async {
    await _runLoggingFailure('소리 정지 실패', player.stop);
    await _runLoggingFailure('플레이어 해제 실패', player.dispose);
  }

  /// 안드로이드 벨소리: 일반 모드의 벨소리 용도라 스피커로 나온다.
  /// 플레이어 기본값과 달라 적용될 때 `AudioManager`를 일반 모드·스피커폰 끔으로 되돌린다.
  static const AudioContextAndroid _ringtoneAndroidContext =
      AudioContextAndroid(
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.notificationRingtone,
        audioFocus: AndroidAudioFocus.none,
      );

  /// 안드로이드 연결음: 일반 모드를 유지한 채 스피커를 고르지 않았으면 통화 용도(수화부,
  /// 이어폰 연결 시 이어폰), 골랐으면 미디어 용도(스피커)로 낸다. 방이 연결되면 통화 모드는
  /// LiveKit이 정하고, 통화 용도 연결음은 그 경로를 따른다.
  static AudioContextAndroid _buildConnectingToneAndroidContext({
    required bool isSpeakerOn,
  }) => isSpeakerOn
      ? const AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.none,
        )
      : const AudioContextAndroid(
          contentType: AndroidContentType.speech,
          usageType: AndroidUsageType.voiceCommunication,
          audioFocus: AndroidAudioFocus.none,
        );

  /// iOS는 LiveKit과 같은 playAndRecord로 맞춘다. 스피커가 꺼져 있으면 시스템 기본 경로
  /// (이어폰 연결 시 이어폰, 없으면 수화부)를 쓴다.
  static AudioContextIOS _buildIosAudioContext({required bool isSpeakerOn}) =>
      AudioContextIOS(
        category: AVAudioSessionCategory.playAndRecord,
        options: {
          AVAudioSessionOptions.mixWithOthers,
          AVAudioSessionOptions.allowBluetooth,
          if (isSpeakerOn) AVAudioSessionOptions.defaultToSpeaker,
        },
      );

  /// 시작·정지가 겹쳐 불려도 호출 순서대로 하나씩 실행한다.
  Future<void> _runInOrder(Future<void> Function() operation) {
    final next = _lastOperation.then((_) => operation());
    _lastOperation = next;
    return next;
  }

  /// 단계 하나의 실패가 통화를 막지 않도록 예외를 경고 로그로 바꾼다.
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
CallSoundPlayer callSoundPlayer(Ref ref) =>
    AudioplayersCallSoundPlayer(ref.watch(appLoggerProvider));
