import 'package:json_annotation/json_annotation.dart';
import 'package:teeq/features/call/domain/call_limit_status.dart';

part 'call_limit_status_response_dto.g.dart';

/// 오늘 통화 한도 응답(`CallLimitStatusResponse`) 중 이 화면이 쓰는 필드만 받는다.
@JsonSerializable(createToJson: false)
class CallLimitStatusResponseDto {
  const CallLimitStatusResponseDto({required this.remainingSeconds});

  factory CallLimitStatusResponseDto.fromJson(Map<String, dynamic> json) =>
      _$CallLimitStatusResponseDtoFromJson(json);

  final int remainingSeconds;

  CallLimitStatus toCallLimitStatus() =>
      CallLimitStatus(remainingSeconds: remainingSeconds);
}
