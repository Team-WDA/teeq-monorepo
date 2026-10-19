import 'package:freezed_annotation/freezed_annotation.dart';

part 'feedback_status.freezed.dart';

/// 통화 한 건의 피드백 진행 상태. [previousCallRecallRequired]는 두 번째 통화부터 true다.
@freezed
abstract class FeedbackStatus with _$FeedbackStatus {
  const factory FeedbackStatus({
    required int callIndex,
    required bool previousCallRecallRequired,
    required bool requiredFeedbackSubmitted,
  }) = _FeedbackStatus;
}
