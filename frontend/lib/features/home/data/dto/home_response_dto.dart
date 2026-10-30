import 'package:json_annotation/json_annotation.dart';
import 'package:teeq/features/feedback/data/dto/pending_feedback_dto.dart';
import 'package:teeq/features/home/data/dto/character_mood_json.dart';
import 'package:teeq/features/home/domain/character_mood.dart';
import 'package:teeq/features/home/domain/home_summary.dart';
import 'package:teeq/features/onboarding/data/dto/character_type_json.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';

part 'home_response_dto.g.dart';

/// 홈 응답(`HomeResponse`) 중 이 화면이 쓰는 필드만 받는다. `callLimit`은 받지 않는다.
@JsonSerializable(createToJson: false)
class HomeResponseDto {
  const HomeResponseDto({
    required this.characterName,
    required this.characterType,
    required this.characterMood,
    required this.personalityTags,
    required this.greeting,
    this.pendingFeedback,
  });

  factory HomeResponseDto.fromJson(Map<String, dynamic> json) =>
      _$HomeResponseDtoFromJson(json);

  final String characterName;
  @JsonKey(fromJson: characterTypeFromJson)
  final CharacterType characterType;
  @JsonKey(fromJson: characterMoodFromJson)
  final CharacterMood characterMood;
  final List<String> personalityTags;
  final String greeting;
  final PendingFeedbackDto? pendingFeedback;

  HomeSummary toHomeSummary() => HomeSummary(
    characterName: characterName,
    characterType: characterType,
    characterMood: characterMood,
    personalityTags: personalityTags,
    greeting: greeting,
    pendingFeedback: pendingFeedback?.toPendingFeedback(),
  );
}
