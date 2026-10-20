import 'package:teeq/features/feedback/domain/detailed_feedback_submission.dart';
import 'package:teeq/features/feedback/domain/feedback_status.dart';
import 'package:teeq/features/feedback/domain/required_feedback_submission.dart';

/// 통화 후 피드백 API 계약. 오류는 호출한 쪽이 `ErrorHandler`로 처리한다.
abstract interface class FeedbackRepository {
  Future<FeedbackStatus> fetchStatus(String callSessionId);

  /// 필수 피드백을 제출하고 상세 피드백 초대 여부(`detailedFeedbackInvited`)를 돌려준다.
  Future<bool> submitRequired(
    String callSessionId,
    RequiredFeedbackSubmission submission,
  );

  Future<void> submitDetailed(
    String callSessionId,
    DetailedFeedbackSubmission submission,
  );
}
