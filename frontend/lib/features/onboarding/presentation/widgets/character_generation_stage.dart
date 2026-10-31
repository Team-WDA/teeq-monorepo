import 'package:teeq/core/design/app_assets.dart';

/// 캐릭터 생성 중 화면의 연출 단계.
enum CharacterGenerationStage {
  analyzingPreferences(
    orbAssetPath: AppAssets.generationOrbStageOne,
    hintMessage: null,
  ),
  reflectingConversationMood(
    orbAssetPath: AppAssets.generationOrbStageTwo,
    hintMessage: '말투와 분위기를 맞추고 있어.',
  ),
  shapingCharacter(
    orbAssetPath: AppAssets.generationOrbStageThree,
    hintMessage: '마지막 형태를 다듬는 중!',
  );

  const CharacterGenerationStage({
    required this.orbAssetPath,
    required this.hintMessage,
  });

  final String orbAssetPath;

  /// 구체 아래 말풍선 문구. 첫 단계에는 없다.
  final String? hintMessage;
}
