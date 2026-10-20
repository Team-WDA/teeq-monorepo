import 'package:json_annotation/json_annotation.dart';
import 'package:teeq/features/feedback/domain/feedback_status.dart';

part 'feedback_status_response_dto.g.dart';

/// 피드백 상태 응답(`FeedbackStatusResponse`).
@JsonSerializable(createToJson: false)
class FeedbackStatusResponseDto {
  const FeedbackStatusResponseDto({
    required this.callIndex,
    required this.previousCallRecallRequired,
    required this.requiredFeedbackSubmitted,
  });

  factory FeedbackStatusResponseDto.fromJson(Map<String, dynamic> json) =>
      _$FeedbackStatusResponseDtoFromJson(json);

  final int callIndex;
  final bool previousCallRecallRequired;
  final bool requiredFeedbackSubmitted;

  FeedbackStatus toFeedbackStatus() => FeedbackStatus(
    callIndex: callIndex,
    previousCallRecallRequired: previousCallRecallRequired,
    requiredFeedbackSubmitted: requiredFeedbackSubmitted,
  );
}
