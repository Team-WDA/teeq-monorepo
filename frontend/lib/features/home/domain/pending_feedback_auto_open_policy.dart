import 'package:teeq/features/feedback/domain/pending_feedback.dart';

/// 홈에서 대기 피드백을 자동으로 열지 정한다.
///
/// 대기 피드백이 있고, 사용자가 방금 닫고 돌아온 피드백 흐름의 통화가 아닐 때만 연다.
bool shouldAutoOpenPendingFeedback({
  required PendingFeedback? pendingFeedback,
  required String? lastClosedFeedbackCallSessionId,
}) =>
    pendingFeedback != null &&
    pendingFeedback.callSessionId != lastClosedFeedbackCallSessionId;
