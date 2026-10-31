import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/ui/decoration/soft_glow_decoration.dart';
import 'package:teeq/core/ui/layout/design_frame_scale_builder.dart';
import 'package:teeq/features/home/domain/character_mood.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';
import 'package:teeq/features/onboarding/presentation/widgets/offset_character_illustration.dart';

/// 이름 입력 화면의 캐릭터 일러스트. 뒤에 빛 번짐이 깔린다.
/// 크기는 좌우 여백 안쪽 본문 폭에 비례한다.
class CharacterNamingIllustration extends StatelessWidget {
  const CharacterNamingIllustration({super.key, required this.characterType});

  final CharacterType characterType;

  static const CharacterMood _characterMood = CharacterMood.welcome;

  /// 바닥 기준선을 상자 위쪽 기준 [AppLayout.characterNamingBaselineY]에 맞추는 이미지 중심의 세로 이동량(상자 중심 기준).
  static const double _centerOffsetY =
      AppLayout.characterNamingBaselineY -
      AppLayout.characterGroundFraction *
          AppLayout.characterNamingIllustrationSize +
      AppLayout.characterNamingIllustrationSize / 2 -
      AppLayout.characterNamingIllustrationHeight / 2;

  @override
  Widget build(BuildContext context) {
    return DesignFrameScaleBuilder(
      designWidth: AppLayout.designContentWidth,
      builder: (context, scale) {
        final glowSize = AppLayout.namingGlowSize * scale;
        return SizedBox(
          height: AppLayout.characterNamingIllustrationHeight * scale,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              OverflowBox(
                maxWidth: glowSize,
                maxHeight: glowSize,
                child: SoftGlowDecoration(
                  assetPath: AppAssets.glowNaming,
                  width: glowSize,
                  height: glowSize,
                ),
              ),
              OffsetCharacterIllustration(
                characterType: characterType,
                characterMood: _characterMood,
                size: AppLayout.characterNamingIllustrationSize * scale,
                offset: Offset(0, _centerOffsetY * scale),
              ),
            ],
          ),
        );
      },
    );
  }
}
