/// 통화 중 기기의 오디오 환경(이어폰 연결, 무음 모드) 조회 계약.
/// 조회 실패는 통화를 막지 않도록 구현체가 던지지 않고 로그로만 남긴다.
abstract interface class CallAudioEnvironment {
  /// 이어폰·블루투스 출력 연결 여부가 바뀔 때마다 현재 연결 여부를 내보낸다.
  ///
  /// 바뀔 때만 내보내고 구독 시점의 현재 값은 내보내지 않으며, 구독하는 동안에만 내보낸다.
  /// 쓰는 쪽은 먼저 구독한 뒤 [isHeadsetConnected]로 현재 값을 한 번 읽는다.
  /// 기기 오디오 세션을 얻지 못하면 경고 로그를 남기고 아무것도 내보내지 않은 채 끝난다.
  Stream<bool> get headsetConnectionChanges;

  /// 이어폰(유선·블루투스) 출력이 연결되어 있는지 확인한다. 실패하면 false.
  Future<bool> isHeadsetConnected();

  /// 기기가 무음·진동 모드인지 확인한다. 안드로이드만 지원하며 iOS와 실패 시 false.
  Future<bool> isRingerSilent();
}
