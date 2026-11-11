/// 벨소리 구간의 진동 계약.
abstract interface class CallVibrator {
  /// 벨소리 진동을 반복 시작한다.
  Future<void> startRinging();

  /// 진동을 멈춘다.
  Future<void> stop();
}
