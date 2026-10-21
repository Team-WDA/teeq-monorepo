import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';

part 'ai_character.freezed.dart';

/// 생성되었거나 이름이 확정된 AI 캐릭터. 이름 확정 전에는 [name]이 null이다.
@freezed
abstract class AiCharacter with _$AiCharacter {
  const factory AiCharacter({
    String? name,
    required CharacterType characterType,
    required List<String> personalityTags,
  }) = _AiCharacter;
}
