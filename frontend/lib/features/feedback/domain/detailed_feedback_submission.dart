import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:teeq/features/feedback/domain/detailed_feedback_question.dart';
import 'package:teeq/features/feedback/domain/start_reason.dart';

part 'detailed_feedback_submission.freezed.dart';

/// 상세 피드백 제출 내용. [memoryNotApplicable]이 true이면 [scores]에 기억 문항이 없고,
/// [reasons]에는 비어 있지 않은 이유만 들어 있다.
@freezed
abstract class DetailedFeedbackSubmission with _$DetailedFeedbackSubmission {
  const factory DetailedFeedbackSubmission({
    required Map<DetailedFeedbackQuestion, int> scores,
    required Map<DetailedFeedbackQuestion, String> reasons,
    required bool memoryNotApplicable,
    String? freeText,
    required List<StartReason> startReasons,
    String? startReasonOtherText,
  }) = _DetailedFeedbackSubmission;
}
