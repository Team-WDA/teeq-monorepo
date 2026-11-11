/// 통화 효과음·진동의 시간·간격 상수. 다른 곳에서 시간 리터럴을 쓰지 않는다.
abstract final class CallAudioTiming {
  /// 연결음을 줄여 가며 멈추는 시간.
  static const Duration connectingToneFadeOut = Duration(milliseconds: 150);

  /// 연결음 페이드아웃의 볼륨 감소 단계 수.
  static const int connectingToneFadeStepCount = 5;

  /// 안드로이드 벨소리 진동의 켜짐 구간.
  static const Duration ringingVibrationOn = Duration(milliseconds: 800);

  /// 안드로이드 벨소리 진동의 꺼짐 구간.
  static const Duration ringingVibrationOff = Duration(milliseconds: 1200);

  /// iOS 벨소리 햅틱 반복 간격.
  static const Duration iosRingingHapticInterval = Duration(seconds: 2);
}
