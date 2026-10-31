import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/ui/progress/stage_progress_stepper.dart';

/// 생성 연출 진행도에 맞춰 이어서 채워지는 3단계 진행 표시기.
class CharacterGenerationStageStepper extends StatelessWidget {
  const CharacterGenerationStageStepper({super.key, required this.progress});

  /// 전체 연출 진행도(0.0~1.0).
  final double progress;

  static const List<String> _labels = ['성향 분석 완료', '대화 무드 반영 중', '형태 만드는 중'];

  @override
  Widget build(BuildContext context) {
    return StageProgressStepper(labels: _labels, progress: progress);
  }
}
