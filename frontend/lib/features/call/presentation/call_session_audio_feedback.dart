import 'dart:async';

import 'package:teeq/features/call/domain/call_audio_environment.dart';
import 'package:teeq/features/call/domain/call_phase.dart';
import 'package:teeq/features/call/domain/call_proximity_screen.dart';
import 'package:teeq/features/call/domain/call_sound_player.dart';
import 'package:teeq/features/call/domain/call_vibrator.dart';

/// 통화 단계에 맞춰 벨소리·진동, 연결음, 근접 센서 화면 끄기를 켜고 끈다.
/// 종료음을 낼지는 컨트롤러가 정하고 여기서는 재생만 한다.
///
/// 만들 때 이어폰 연결 변화를 구독하고 현재 값을 한 번 읽는다. 변경 스트림은 구독 중에만
/// 내보내므로 [dispose]할 때까지 구독을 유지한다.
final class CallSessionAudioFeedback {
  CallSessionAudioFeedback({
    required this._soundPlayer,
    required this._vibrator,
    required this._audioEnvironment,
    required this._proximityScreen,
    required this._readPhase,
    required this._isMounted,
  }) {
    _headsetSubscription = _audioEnvironment.headsetConnectionChanges.listen(
      _handleHeadsetChange,
    );
    unawaited(_readInitialHeadsetConnection());
  }

  final CallSoundPlayer _soundPlayer;
  final CallVibrator _vibrator;
  final CallAudioEnvironment _audioEnvironment;
  final CallProximityScreen _proximityScreen;
  final CallPhase Function() _readPhase;
  final bool Function() _isMounted;
  late final StreamSubscription<bool> _headsetSubscription;

  /// 울리는 화면에 들어올 때 읽은 무음·진동 모드 여부. 연결음도 이 값을 따른다.
  bool _isRingerSilent = false;

  /// 앱이 백그라운드로 가며 벨소리·진동을 멈췄는지 여부. 돌아왔을 때만 다시 울린다.
  bool _isRingingPausedByLifecycle = false;

  /// 이어폰(유선·블루투스) 출력 연결 여부. 변경 이벤트와 시작 때 한 번 읽은 값으로 갱신한다.
  bool _isHeadsetConnected = false;

  /// 변경 이벤트를 한 번이라도 받았는지 여부. 받았다면 늦게 끝난 최초 조회값이 덮어쓰지 않는다.
  bool _hasReceivedHeadsetChange = false;

  /// 근접 센서 화면 끄기에 마지막으로 적용한 값.
  bool _isProximityEnabled = false;

  /// 단계 전이에 맞춰 벨소리·진동과 연결음을 켜고 끄고, 근접 센서 화면 끄기를 맞춘다.
  void syncPhase(CallPhase? previous, CallPhase next) {
    _syncSounds(previous, next);
    _updateProximity();
  }

  /// 앱이 백그라운드로 가면 울리는 중의 벨소리·진동을 멈춘다.
  void handleAppPaused() {
    if (_readPhase() is! CallRinging) {
      return;
    }
    _isRingingPausedByLifecycle = true;
    _stopRinging();
  }

  /// 백그라운드에서 멈춘 벨소리·진동을 아직 울리는 중일 때만 다시 시작한다.
  void handleAppResumed() {
    if (!_isRingingPausedByLifecycle) {
      return;
    }
    _isRingingPausedByLifecycle = false;
    if (_readPhase() is CallRinging) {
      unawaited(_startRinging());
    }
  }

  void playEndTone() => unawaited(_soundPlayer.playEndTone());

  /// 반복 소리·진동·근접 센서를 멈추고 이어폰 구독을 끊는다.
  /// 종료음은 화면이 닫힌 뒤에도 끝까지 들리도록 멈추지 않는다.
  void dispose() {
    unawaited(_headsetSubscription.cancel());
    unawaited(_soundPlayer.stopLoopingTone(shouldFadeOut: false));
    unawaited(_vibrator.stop());
    unawaited(_proximityScreen.disable());
  }

  void _syncSounds(CallPhase? previous, CallPhase next) {
    if (next is CallRinging && previous is! CallRinging) {
      unawaited(_startRinging());
    } else if (next is! CallRinging && previous is CallRinging) {
      _stopRinging();
    }
    final wasConnectingTonePhase = _isConnectingTonePhase(previous);
    final isConnectingTonePhase = _isConnectingTonePhase(next);
    if (next is CallStarting && !wasConnectingTonePhase) {
      // 연결음 컨텍스트는 방 연결 전에만 정하므로 시작 요청에서만 튼다.
      // 재연결(시간 초과 카드의 다시 연결하기 포함)은 방이 있는 채 연결중으로 바로 들어가 틀지 않는다.
      if (!_isRingerSilent) {
        unawaited(
          _soundPlayer.startConnectingTone(isSpeakerOn: next.isSpeakerOn),
        );
      }
    } else if (!isConnectingTonePhase && wasConnectingTonePhase) {
      // 워커가 들어와 통화중이 될 때만 줄여 가며 멈춘다.
      unawaited(
        _soundPlayer.stopLoopingTone(shouldFadeOut: next is CallInProgress),
      );
    }
  }

  bool _isConnectingTonePhase(CallPhase? phase) =>
      phase is CallStarting || phase is CallConnecting;

  /// 진동은 바로, 벨소리는 무음·진동 모드가 아닐 때만 시작한다.
  Future<void> _startRinging() async {
    unawaited(_vibrator.startRinging());
    final isRingerSilent = await _audioEnvironment.isRingerSilent();
    if (!_isMounted()) {
      return;
    }
    // 확인하는 사이 받았어도 연결음이 이 값을 따르도록 울림 여부와 상관없이 먼저 저장한다.
    _isRingerSilent = isRingerSilent;
    // 확인하는 사이 받기·백그라운드 전환으로 울림이 끝났으면 벨소리는 시작하지 않는다.
    if (_readPhase() is! CallRinging || _isRingingPausedByLifecycle) {
      return;
    }
    if (!isRingerSilent) {
      unawaited(_soundPlayer.startRingtone());
    }
  }

  void _stopRinging() {
    unawaited(_soundPlayer.stopLoopingTone(shouldFadeOut: false));
    unawaited(_vibrator.stop());
  }

  void _handleHeadsetChange(bool isConnected) {
    _hasReceivedHeadsetChange = true;
    _isHeadsetConnected = isConnected;
    _updateProximity();
  }

  Future<void> _readInitialHeadsetConnection() async {
    final isConnected = await _audioEnvironment.isHeadsetConnected();
    // 조회하는 사이 변경 이벤트가 왔다면 그 값이 더 새로우므로 덮어쓰지 않는다.
    if (!_isMounted() || _hasReceivedHeadsetChange) {
      return;
    }
    _isHeadsetConnected = isConnected;
    _updateProximity();
  }

  /// 수화기로 듣는 연결중·통화중이고 카드가 없을 때만 근접 센서로 화면을 끈다.
  /// 스피커나 이어폰을 쓰거나 카드가 떠 있으면 화면이 꺼지지 않게 한다.
  void _updateProximity() {
    final shouldEnable = _shouldEnableProximity(_readPhase());
    if (shouldEnable == _isProximityEnabled) {
      return;
    }
    _isProximityEnabled = shouldEnable;
    unawaited(
      shouldEnable ? _proximityScreen.enable() : _proximityScreen.disable(),
    );
  }

  bool _shouldEnableProximity(CallPhase phase) {
    if (_isHeadsetConnected) {
      return false;
    }
    return switch (phase) {
      CallConnecting(:final isSpeakerOn) => !isSpeakerOn,
      CallInProgress() =>
        !phase.isSpeakerOn &&
            !phase.isEndConfirmationVisible &&
            !phase.isEndingSoonVisible &&
            !phase.isReconnectNoticeVisible,
      _ => false,
    };
  }
}
