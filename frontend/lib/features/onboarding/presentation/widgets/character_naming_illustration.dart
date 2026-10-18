import 'package:flutter/material.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/ui/decoration/soft_glow_decoration.dart';
import 'package:teeq/core/ui/layout/design_frame_scale_builder.dart';

/// 이름 입력 화면의 캐릭터 일러스트. 뒤에 빛 번짐이 깔린다.
/// 크기는 좌우 여백 안쪽 본문 폭에 비례한다.
class CharacterNamingIllustration extends StatelessWidget {
  const CharacterNamingIllustration({super.key});

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
              Image.asset(
                AppAssets.characterNaming,
                width: AppLayout.characterNamingIllustrationWidth * scale,
                height: AppLayout.characterNamingIllustrationHeight * scale,
                fit: BoxFit.fill,
              ),
            ],
          ),
        );
      },
    );
  }
}
