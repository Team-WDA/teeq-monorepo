import 'package:flutter/material.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/ui/layout/design_frame_scale_builder.dart';
import 'package:teeq/features/onboarding/presentation/widgets/offset_decoration_image.dart';

/// 최초 가입 결과 화면 배경. 오른쪽으로 크게 튀어나와 화면 가장자리에서 잘리는 캐릭터와 빛 번짐.
/// 크기와 위치는 화면 폭에 비례한다.
class FirstTimeCharacterResultDecoration extends StatelessWidget {
  const FirstTimeCharacterResultDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return DesignFrameScaleBuilder(
      builder: (context, scale) {
        return Stack(
          fit: StackFit.expand,
          children: [
            OffsetDecorationImage(
              assetPath: AppAssets.glowWelcome,
              width: AppLayout.welcomeGlowSize * scale,
              height: AppLayout.welcomeGlowSize * scale,
              offset: Offset(
                AppLayout.welcomeGlowOffsetX * scale,
                AppLayout.welcomeGlowOffsetY * scale,
              ),
            ),
            OffsetDecorationImage(
              assetPath: AppAssets.characterWelcome,
              width: AppLayout.welcomeCharacterSize * scale,
              height: AppLayout.welcomeCharacterSize * scale,
              offset: Offset(
                AppLayout.welcomeCharacterOffsetX * scale,
                AppLayout.welcomeCharacterOffsetY * scale,
              ),
            ),
          ],
        );
      },
    );
  }
}
