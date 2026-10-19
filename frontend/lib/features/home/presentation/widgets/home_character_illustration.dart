import 'package:flutter/material.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/ui/decoration/soft_glow_decoration.dart';
import 'package:teeq/core/ui/layout/design_frame_scale_builder.dart';

/// 홈의 윙크 토끼와 배경 빛 번짐. 부모 폭에 비례해 균일하게 커지고 작아진다.
class HomeCharacterIllustration extends StatelessWidget {
  const HomeCharacterIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return DesignFrameScaleBuilder(
      builder: (context, scale) {
        return SizedBox(
          height: AppLayout.homeCharacterHeight * scale,
          // 빛 번짐이 위쪽 인사 카드를 덮지 않도록 위쪽만 잘라 낸다.
          child: ClipRect(
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
                Positioned(
                  left: AppLayout.homeCharacterOffsetX * scale,
                  top: 0,
                  child: Image.asset(
                    AppAssets.homeCharacterWink,
                    width: AppLayout.homeCharacterWidth * scale,
                    height: AppLayout.homeCharacterHeight * scale,
                    fit: BoxFit.fill,
                  ),
                ),
              ],
            ),
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
