import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/ui/tag/accent_outline_hint_tag.dart';
import 'package:teeq/features/onboarding/presentation/widgets/character_generation_stage.dart';

/// 생성 단계별 구체 일러스트와 그 아래 말풍선. 말풍선이 없는 단계도 같은 높이를 유지한다.
class CharacterGenerationStageIllustration extends StatelessWidget {
  const CharacterGenerationStageIllustration({super.key, required this.stage});

  final CharacterGenerationStage stage;

  @override
  Widget build(BuildContext context) {
    final hintMessage = stage.hintMessage;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Image.asset(stage.orbAssetPath),
          ),
        ),
        const SizedBox(height: AppSpacing.space24),
        SizedBox(
          height: AppLayout.hintTagHeight,
          child: hintMessage == null
              ? null
              : AccentOutlineHintTag(message: hintMessage),
        ),
      ],
    );
  }
}
