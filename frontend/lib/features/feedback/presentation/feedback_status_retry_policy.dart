import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feedback_status_retry_policy.g.dart';

/// AI 서버가 끝난 통화를 아직 보고하지 않아 피드백 상태 조회가 거절될 때의 재시도 정책.
final class FeedbackStatusRetryPolicy {
  const FeedbackStatusRetryPolicy({
    this.maxAttempts = 10,
    this.interval = const Duration(seconds: 1),
  });

  /// 첫 시도를 포함한 최대 시도 횟수.
  final int maxAttempts;

  /// 시도 사이의 대기 시간.
  final Duration interval;
}

@Riverpod(keepAlive: true)
FeedbackStatusRetryPolicy feedbackStatusRetryPolicy(Ref ref) =>
    const FeedbackStatusRetryPolicy();
