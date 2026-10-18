import 'package:flutter/material.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/features/onboarding/presentation/widgets/offset_decoration_image.dart';

/// 최초 가입 결과 화면 배경. 오른쪽으로 크게 튀어나와 화면 가장자리에서 잘리는 캐릭터와 빛 번짐.
class FirstTimeCharacterResultDecoration extends StatelessWidget {
  const FirstTimeCharacterResultDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        OffsetDecorationImage(
          assetPath: AppAssets.glowWelcome,
          width: AppLayout.welcomeGlowSize,
          height: AppLayout.welcomeGlowSize,
          offset: Offset(
            AppLayout.welcomeGlowOffsetX,
            AppLayout.welcomeGlowOffsetY,
          ),
        ),
        OffsetDecorationImage(
          assetPath: AppAssets.characterWelcome,
          width: AppLayout.welcomeCharacterSize,
          height: AppLayout.welcomeCharacterSize,
          offset: Offset(
            AppLayout.welcomeCharacterOffsetX,
            AppLayout.welcomeCharacterOffsetY,
          ),
        ),
      ],
    );
  }
}
