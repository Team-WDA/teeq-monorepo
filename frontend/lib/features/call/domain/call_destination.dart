/// 통화가 끝난 뒤 이동할 곳.
sealed class CallDestination {
  const CallDestination();
}

/// 홈으로 이동한다.
final class CallDestinationHome extends CallDestination {
  const CallDestinationHome();
}

/// 피드백 화면으로 이동한다.
final class CallDestinationFeedback extends CallDestination {
  const CallDestinationFeedback({required this.callSessionId});

  final String callSessionId;
}
