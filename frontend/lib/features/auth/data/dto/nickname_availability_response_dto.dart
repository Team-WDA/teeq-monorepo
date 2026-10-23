import 'package:json_annotation/json_annotation.dart';

part 'nickname_availability_response_dto.g.dart';

/// 닉네임 사용 가능 여부 응답(`NicknameAvailabilityResponse`).
@JsonSerializable(createToJson: false)
class NicknameAvailabilityResponseDto {
  const NicknameAvailabilityResponseDto({required this.available});

  factory NicknameAvailabilityResponseDto.fromJson(Map<String, dynamic> json) =>
      _$NicknameAvailabilityResponseDtoFromJson(json);

  final bool available;
}
