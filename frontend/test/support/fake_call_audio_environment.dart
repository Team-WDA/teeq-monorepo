import 'dart:async';

import 'package:teeq/features/call/domain/call_audio_environment.dart';

/// 값을 직접 정하는 테스트용 오디오 환경.
/// [ringerSilentGate]를 두면 `isRingerSilent()`가 게이트가 완료될 때까지 대기한다.
class FakeCallAudioEnvironment implements CallAudioEnvironment {
  final StreamController<bool> _headsetController =
      StreamController<bool>.broadcast();

  bool headsetConnected = false;
  bool ringerSilent = false;
  Completer<void>? ringerSilentGate;

  /// 이어폰 연결 상태를 바꾸고 변경 이벤트를 내보낸다.
  void emitHeadset(bool isConnected) {
    headsetConnected = isConnected;
    _headsetController.add(isConnected);
  }

  @override
  Stream<bool> get headsetConnectionChanges => _headsetController.stream;

  @override
  Future<bool> isHeadsetConnected() async => headsetConnected;

  @override
  Future<bool> isRingerSilent() async {
    await ringerSilentGate?.future;
    return ringerSilent;
  }
}
