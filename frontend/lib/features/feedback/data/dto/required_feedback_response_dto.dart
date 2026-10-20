import 'package:json_annotation/json_annotation.dart';

part 'required_feedback_response_dto.g.dart';

/// 필수 피드백 제출 응답(`RequiredFeedbackResponse`).
@JsonSerializable(createToJson: false)
class RequiredFeedbackResponseDto {
  const RequiredFeedbackResponseDto({required this.detailedFeedbackInvited});

  factory RequiredFeedbackResponseDto.fromJson(Map<String, dynamic> json) =>
      _$RequiredFeedbackResponseDtoFromJson(json);

  final bool detailedFeedbackInvited;
}
