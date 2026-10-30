import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/features/home/domain/character_mood.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';

void main() {
  group('characterMoodIllustration', () {
    test('characterMoodIllustration_buildsPathFromTypeNumberAndMoodName', () {
      expect(
        AppAssets.characterMoodIllustration(
          CharacterType.character3,
          CharacterMood.curious,
        ),
        'assets/images/character_3_mood_curious.png',
      );
      expect(
        AppAssets.characterMoodIllustration(
          CharacterType.character1,
          CharacterMood.welcome,
        ),
        'assets/images/character_1_mood_welcome.png',
      );
      expect(
        AppAssets.characterMoodIllustration(
          CharacterType.character5,
          CharacterMood.celebrate,
        ),
        'assets/images/character_5_mood_celebrate.png',
      );
    });

    test('characterMoodIllustration_existsFor1x2x3xInEveryCombination', () {
      final missingPaths = <String>[];
      for (final characterType in CharacterType.values) {
        for (final characterMood in CharacterMood.values) {
          final path = AppAssets.characterMoodIllustration(
            characterType,
            characterMood,
          );
          final fileName = path.split('/').last;
          for (final directory in const [
            'assets/images',
            'assets/images/2.0x',
            'assets/images/3.0x',
          ]) {
            final candidate = '$directory/$fileName';
            if (!File(candidate).existsSync()) {
              missingPaths.add(candidate);
            }
          }
        }
      }
      expect(missingPaths, isEmpty, reason: '누락된 캐릭터 표정 이미지: $missingPaths');
    });
  });
}
