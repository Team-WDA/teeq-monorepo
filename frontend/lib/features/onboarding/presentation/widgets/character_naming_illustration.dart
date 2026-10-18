import 'package:flutter/material.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/ui/decoration/soft_glow_decoration.dart';

/// 이름 입력 화면의 캐릭터 일러스트. 뒤에 빛 번짐이 깔린다.
class CharacterNamingIllustration extends StatelessWidget {
  const CharacterNamingIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppLayout.characterNamingIllustrationHeight,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          const OverflowBox(
            maxWidth: AppLayout.namingGlowSize,
            maxHeight: AppLayout.namingGlowSize,
            child: SoftGlowDecoration(
              assetPath: AppAssets.glowNaming,
              width: AppLayout.namingGlowSize,
              height: AppLayout.namingGlowSize,
            ),
          ),
          Image.asset(
            AppAssets.characterNaming,
            width: AppLayout.characterNamingIllustrationWidth,
            height: AppLayout.characterNamingIllustrationHeight,
            fit: BoxFit.fill,
          ),
        ],
      ),
    );
  }
}
