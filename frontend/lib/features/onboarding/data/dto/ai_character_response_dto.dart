import 'package:json_annotation/json_annotation.dart';
import 'package:teeq/features/onboarding/data/dto/character_type_json.dart';
import 'package:teeq/features/onboarding/domain/ai_character.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';

part 'ai_character_response_dto.g.dart';

/// AI 캐릭터 생성·이름 확정 응답(`AiCharacterResponse`). 이름 확정 전에는 `name`이 null이다.
@JsonSerializable(createToJson: false)
class AiCharacterResponseDto {
  const AiCharacterResponseDto({
    required this.name,
    required this.characterType,
    required this.personalityTags,
  });

  factory AiCharacterResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AiCharacterResponseDtoFromJson(json);

  final String? name;
  @JsonKey(fromJson: characterTypeFromJson)
  final CharacterType characterType;
  final List<String> personalityTags;

  AiCharacter toAiCharacter() => AiCharacter(
    name: name,
    characterType: characterType,
    personalityTags: personalityTags,
  );
}
