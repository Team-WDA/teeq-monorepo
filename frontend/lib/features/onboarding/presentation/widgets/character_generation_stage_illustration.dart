import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/ui/tag/accent_outline_hint_tag.dart';
import 'package:teeq/features/onboarding/presentation/widgets/character_generation_stage.dart';

/// 생성 단계별 구체 일러스트와 그 아래 말풍선.
/// 구체 세 장을 같은 영역에 겹쳐 두고 단계 경계 근처에서 이어서 바꿔 보인다.
/// 말풍선 자리는 단계와 관계없이 같은 위치·높이를 유지한다.
class CharacterGenerationStageIllustration extends StatelessWidget {
  const CharacterGenerationStageIllustration({
    super.key,
    required this.progress,
  });

  /// 전체 연출 진행도(0.0~1.0).
  final double progress;

  /// 단계 경계 앞뒤로 크로스페이드하는 폭. 단계 하나의 길이에 대한 비율이다.
  static const double _crossfadeHalfWidthInStages = 0.1;

  /// 완전히 사라진 구체의 배율. 나타나면서 1배로 커진다.
  static const double _hiddenOrbScale = 0.92;

  /// [stage]가 보이는 정도(0.0~1.0). 앞 경계에서 나타나고 뒤 경계에서 사라진다.
  double _visibilityOf(CharacterGenerationStage stage) {
    final stageCount = CharacterGenerationStage.values.length;
    final stagePosition = progress * stageCount;
    final fadeIn = stage.index == 0
        ? 1.0
        : _crossfadeFraction(stagePosition, stage.index.toDouble());
    final fadeOut = stage.index == stageCount - 1
        ? 1.0
        : 1 - _crossfadeFraction(stagePosition, stage.index + 1.0);
    return Curves.easeInOut.transform(fadeIn * fadeOut);
  }

  /// [boundary] 경계를 지나는 크로스페이드 구간에서의 진행 비율(0.0~1.0).
  double _crossfadeFraction(double stagePosition, double boundary) {
    return ((stagePosition - boundary + _crossfadeHalfWidthInStages) /
            (_crossfadeHalfWidthInStages * 2))
        .clamp(0.0, 1.0);
  }

  /// 구체 아래 간격과 말풍선 자리. 구체가 줄어들어도 이 높이는 유지한다.
  static const double _hintAreaHeight =
      AppSpacing.space24 + AppLayout.hintTagHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight >= _hintAreaHeight) {
          return _buildContent();
        }
        // 말풍선 자리보다 좁은 화면에서는 구체를 숨기고 전체를 비율대로 줄인다.
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: constraints.maxWidth,
            height: _hintAreaHeight,
            child: _buildContent(),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: AppLayout.generationOrbWidth,
              height: AppLayout.generationOrbHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (final stage in CharacterGenerationStage.values)
                    _buildOrb(stage),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space24),
        SizedBox(
          height: AppLayout.hintTagHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (final stage in CharacterGenerationStage.values)
                ?_buildHintTag(stage),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrb(CharacterGenerationStage stage) {
    final visibility = _visibilityOf(stage);
    return Opacity(
      opacity: visibility,
      child: Transform.scale(
        scale: lerpDouble(_hiddenOrbScale, 1, visibility),
        child: Image.asset(stage.orbAssetPath),
      ),
    );
  }

  /// 문구가 있고 보이는 단계만 말풍선을 그린다.
  Widget? _buildHintTag(CharacterGenerationStage stage) {
    final hintMessage = stage.hintMessage;
    final visibility = _visibilityOf(stage);
    if (hintMessage == null || visibility == 0) {
      return null;
    }
    return Opacity(
      opacity: visibility,
      child: AccentOutlineHintTag(message: hintMessage),
    );
  }
}
