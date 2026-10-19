import 'package:json_annotation/json_annotation.dart';
import 'package:teeq/features/home/domain/home_summary.dart';

part 'home_response_dto.g.dart';

/// 홈 응답(`HomeResponse`) 중 이 화면이 쓰는 필드만 받는다. `callLimit`, `pendingFeedback`은 받지 않는다.
@JsonSerializable(createToJson: false)
class HomeResponseDto {
  const HomeResponseDto({
    required this.characterName,
    required this.personalityTags,
    required this.greeting,
  });

  factory HomeResponseDto.fromJson(Map<String, dynamic> json) =>
      _$HomeResponseDtoFromJson(json);

  final String characterName;
  final List<String> personalityTags;
  final String greeting;

  HomeSummary toHomeSummary() => HomeSummary(
    characterName: characterName,
    personalityTags: personalityTags,
    greeting: greeting,
  );
}
