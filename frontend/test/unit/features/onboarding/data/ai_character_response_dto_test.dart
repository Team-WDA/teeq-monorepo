import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/onboarding/data/dto/ai_character_response_dto.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';

Map<String, dynamic> _json(String characterType) => {
  'name': null,
  'characterType': characterType,
  'personalityTags': ['다정한'],
};

void main() {
  group('AiCharacterResponseDto characterType', () {
    test('CHARACTER_1~CHARACTER_5를 CharacterType으로 바꾼다', () {
      const expected = {
        'CHARACTER_1': CharacterType.character1,
        'CHARACTER_2': CharacterType.character2,
        'CHARACTER_3': CharacterType.character3,
        'CHARACTER_4': CharacterType.character4,
        'CHARACTER_5': CharacterType.character5,
      };
      for (final entry in expected.entries) {
        final character = AiCharacterResponseDto.fromJson(_json(entry.key))
            .toAiCharacter();
        expect(character.characterType, entry.value);
      }
    });

    test('모르는 값은 FormatException을 던진다', () {
      expect(
        () => AiCharacterResponseDto.fromJson(_json('CHARACTER_6')),
        throwsFormatException,
      );
    });
  });
}
