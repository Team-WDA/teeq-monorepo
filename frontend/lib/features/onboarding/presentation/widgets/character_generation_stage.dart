import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/ui/progress/stage_progress_stepper.dart';

/// 캐릭터 생성 중 화면의 연출 단계.
enum CharacterGenerationStage {
  analyzingPreferences(
    orbAssetPath: AppAssets.generationOrbStageOne,
    hintMessage: null,
    stepperStatuses: [
      StageProgressStatus.completed,
      StageProgressStatus.inProgress,
      StageProgressStatus.pending,
    ],
  ),
  reflectingConversationMood(
    orbAssetPath: AppAssets.generationOrbStageTwo,
    hintMessage: '말투와 분위기를 맞추고 있어.',
    stepperStatuses: [
      StageProgressStatus.completed,
      StageProgressStatus.completed,
      StageProgressStatus.inProgress,
    ],
  ),
  shapingCharacter(
    orbAssetPath: AppAssets.generationOrbStageThree,
    hintMessage: '마지막 형태를 다듬는 중!',
    stepperStatuses: [
      StageProgressStatus.completed,
      StageProgressStatus.completed,
      StageProgressStatus.completed,
    ],
  );

  const CharacterGenerationStage({
    required this.orbAssetPath,
    required this.hintMessage,
    required this.stepperStatuses,
  });

  final String orbAssetPath;

  /// 구체 아래 말풍선 문구. 첫 단계에는 없다.
  final String? hintMessage;
  final List<StageProgressStatus> stepperStatuses;
}
