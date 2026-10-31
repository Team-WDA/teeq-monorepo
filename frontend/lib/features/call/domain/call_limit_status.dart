/// 통화 시작 전 남은 통화 가능 시간.
final class CallLimitStatus {
  const CallLimitStatus({required this.remainingSeconds});

  final int remainingSeconds;
}
