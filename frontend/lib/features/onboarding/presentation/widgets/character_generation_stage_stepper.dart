import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/ui/progress/stage_progress_stepper.dart';
import 'package:teeq/features/onboarding/presentation/widgets/character_generation_stage.dart';

/// 생성 단계에 맞는 3단계 진행 표시기.
class CharacterGenerationStageStepper extends StatelessWidget {
  const CharacterGenerationStageStepper({super.key, required this.stage});

  final CharacterGenerationStage stage;

  static const List<String> _labels = ['성향 분석 완료', '대화 무드 반영 중', '형태 만드는 중'];

  @override
  Widget build(BuildContext context) {
    return StageProgressStepper(
      labels: _labels,
      statuses: stage.stepperStatuses,
    );
  }
}
