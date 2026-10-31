/// 통화 화면의 대기 시간 설정. 테스트에서 짧게 바꿀 수 있도록 값으로 분리한다.
final class CallTiming {
  const CallTiming({
    this.agentWaitTimeout = const Duration(seconds: 20),
    this.reconnectNoticeGrace = const Duration(seconds: 5),
  });

  /// 상대(AI) 참가를 기다리는 최대 시간.
  final Duration agentWaitTimeout;

  /// 재연결 안내를 띄우기 전에 기다리는 시간.
  final Duration reconnectNoticeGrace;
}
