import 'package:json_annotation/json_annotation.dart';
import 'package:teeq/features/onboarding/domain/ai_character.dart';

part 'ai_character_response_dto.g.dart';

/// AI 캐릭터 생성·이름 확정 응답(`AiCharacterResponse`). 이름 확정 전에는 `name`이 null이다.
@JsonSerializable(createToJson: false)
class AiCharacterResponseDto {
  const AiCharacterResponseDto({
    required this.name,
    required this.characterNumber,
    required this.personalityTags,
  });

  factory AiCharacterResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AiCharacterResponseDtoFromJson(json);

  final String? name;
  final int characterNumber;
  final List<String> personalityTags;

  AiCharacter toAiCharacter() => AiCharacter(
    name: name,
    characterNumber: characterNumber,
    personalityTags: personalityTags,
  );
}
