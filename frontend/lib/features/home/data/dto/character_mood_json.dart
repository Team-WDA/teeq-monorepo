import 'package:teeq/features/home/domain/character_mood.dart';

/// 서버의 캐릭터 표정 문자열을 [CharacterMood]로 바꾼다. 모르는 값은 환영 표정으로 대신한다.
CharacterMood characterMoodFromJson(String value) => switch (value) {
  'WELCOME' => CharacterMood.welcome,
  'CURIOUS' => CharacterMood.curious,
  'WORRIED' => CharacterMood.worried,
  'EXCITED' => CharacterMood.excited,
  'CELEBRATE' => CharacterMood.celebrate,
  _ => CharacterMood.welcome,
};
