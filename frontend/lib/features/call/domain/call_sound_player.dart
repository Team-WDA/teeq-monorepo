/// 통화 화면 효과음(벨소리·연결음·종료음) 재생 계약.
/// 음원 재생 실패는 통화를 막지 않도록 구현체가 던지지 않고 로그로만 남긴다.
abstract interface class CallSoundPlayer {
  /// 벨소리를 스피커로 반복 재생한다. 이전 반복 소리가 있으면 먼저 멈춘다.
  Future<void> startRingtone();

  /// 연결음을 반복 재생한다. [isSpeakerOn]은 오디오 컨텍스트를 정하므로
  /// 방 연결 전(`CallStarting`)에서만 의미가 있다.
  Future<void> startConnectingTone({required bool isSpeakerOn});

  /// 반복 중인 소리를 멈춘다. [shouldFadeOut]이면 볼륨을 줄여 가며 멈춘다.
  Future<void> stopLoopingTone({required bool shouldFadeOut});

  /// 종료음을 한 번 재생한다. 반복 소리 정지에 영향받지 않는다.
  Future<void> playEndTone();
}
