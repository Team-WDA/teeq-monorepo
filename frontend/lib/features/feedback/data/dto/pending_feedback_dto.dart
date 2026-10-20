import 'package:json_annotation/json_annotation.dart';
import 'package:teeq/features/feedback/domain/pending_feedback.dart';

part 'pending_feedback_dto.g.dart';

/// 홈 응답의 `pendingFeedback`(`PendingFeedbackResponse`).
@JsonSerializable(createToJson: false)
class PendingFeedbackDto {
  const PendingFeedbackDto({
    required this.callSessionId,
    required this.callIndex,
  });

  factory PendingFeedbackDto.fromJson(Map<String, dynamic> json) =>
      _$PendingFeedbackDtoFromJson(json);

  final String callSessionId;
  final int callIndex;

  PendingFeedback toPendingFeedback() =>
      PendingFeedback(callSessionId: callSessionId, callIndex: callIndex);
}
