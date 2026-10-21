import 'package:teeq/features/onboarding/domain/character_type.dart';

/// 서버의 캐릭터 종류 문자열을 [CharacterType]으로 바꾼다. 모르는 값은 매핑 오류로 던진다.
CharacterType characterTypeFromJson(String value) => switch (value) {
  'CHARACTER_1' => CharacterType.character1,
  'CHARACTER_2' => CharacterType.character2,
  'CHARACTER_3' => CharacterType.character3,
  'CHARACTER_4' => CharacterType.character4,
  'CHARACTER_5' => CharacterType.character5,
  _ => throw FormatException('알 수 없는 캐릭터 종류: $value'),
};
