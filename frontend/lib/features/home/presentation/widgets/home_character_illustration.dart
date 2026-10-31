import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/ui/decoration/soft_glow_decoration.dart';
import 'package:teeq/core/ui/illustration/character_illustration.dart';
import 'package:teeq/core/ui/layout/design_frame_scale_builder.dart';
import 'package:teeq/features/home/domain/character_mood.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';

/// 홈의 캐릭터 이미지와 배경 빛 번짐. 외형(characterType)과 표정(characterMood)에 맞는 이미지를 그린다.
/// 부모 폭에 비례해 균일하게 커지고 작아진다.
class HomeCharacterIllustration extends StatelessWidget {
  const HomeCharacterIllustration({
    super.key,
    required this.characterType,
    required this.characterMood,
  });

  final CharacterType characterType;
  final CharacterMood characterMood;

  @override
  Widget build(BuildContext context) {
    return DesignFrameScaleBuilder(
      builder: (context, scale) {
        final illustrationSize =
            AppLayout.homeCharacterIllustrationSize * scale;
        return SizedBox(
          height: AppLayout.homeCharacterHeight * scale,
          // 큰 표정 이미지는 위쪽으로 넘칠 수 있으므로 바깥 Stack은 자르지 않는다.
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 빛 번짐이 위쪽 인사 카드를 덮지 않도록 빛 번짐만 위쪽을 잘라 낸다.
              ClipRect(
                clipper: const _GlowClipper(),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: AppLayout.homeGlowOffsetX * scale,
                      top: AppLayout.homeGlowOffsetY * scale,
                      child: SoftGlowDecoration(
                        assetPath: AppAssets.glowHome,
                        width: AppLayout.homeGlowWidth * scale,
                        height: AppLayout.homeGlowHeight * scale,
                      ),
                    ),
                  ],
                ),
              ),
              // 바닥 기준선이 영역 바닥에 닿고 이미지는 투명한 아래쪽 여백만큼 아래로 나간다.
              Positioned(
                left:
                    (AppLayout.homeCharacterCenterX -
                        AppLayout.homeCharacterIllustrationSize / 2) *
                    scale,
                bottom:
                    -(1 - AppLayout.characterGroundFraction) * illustrationSize,
                child: CharacterIllustration(
                  characterType: characterType,
                  characterMood: characterMood,
                  size: illustrationSize,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 위쪽은 일러스트 영역 경계까지만, 나머지 방향은 빛 번짐이 번지는 만큼 허용하는 잘라내기.
class _GlowClipper extends CustomClipper<Rect> {
  const _GlowClipper();

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
    -AppLayout.homeGlowWidth,
    0,
    size.width + AppLayout.homeGlowWidth,
    size.height + AppLayout.homeGlowHeight,
  );

  @override
  bool shouldReclip(_GlowClipper oldClipper) => false;
}
