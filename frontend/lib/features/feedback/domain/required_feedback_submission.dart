import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:teeq/features/feedback/domain/awkward_moment.dart';
import 'package:teeq/features/feedback/domain/previous_call_recall.dart';
import 'package:teeq/features/feedback/domain/revisit_intention.dart';

part 'required_feedback_submission.freezed.dart';

/// 필수 피드백 제출 내용. 첫 통화에서는 [previousCallRecall]이 null이다.
@freezed
abstract class RequiredFeedbackSubmission with _$RequiredFeedbackSubmission {
  const factory RequiredFeedbackSubmission({
    required int rating,
    required RevisitIntention revisitIntention,
    PreviousCallRecall? previousCallRecall,
    required List<AwkwardMoment> awkwardMoments,
  }) = _RequiredFeedbackSubmission;
}
