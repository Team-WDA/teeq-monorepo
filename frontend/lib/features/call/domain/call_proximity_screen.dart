/// 통화 중 기기를 귀에 가져가면 화면을 끄는 근접 센서 동작의 계약.
/// 실패는 통화를 막지 않도록 구현체가 던지지 않고 로그로만 남긴다.
abstract interface class CallProximityScreen {
  /// 근접 센서로 화면 끄기를 켠다. 이미 켜져 있으면 아무것도 하지 않는다.
  Future<void> enable();

  /// 근접 센서로 화면 끄기를 끈다. 켠 적이 없거나 여러 번 불려도 안전하다.
  Future<void> disable();
}
