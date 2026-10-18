import 'package:flutter/material.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/features/onboarding/presentation/widgets/offset_decoration_image.dart';

/// 수정 결과 화면 배경. 화면 가운데의 초록 캐릭터와 빛 번짐.
class EditCharacterResultDecoration extends StatelessWidget {
  const EditCharacterResultDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        OffsetDecorationImage(
          assetPath: AppAssets.glowEdit,
          width: AppLayout.editResultGlowWidth,
          height: AppLayout.editResultGlowHeight,
          offset: Offset(0, AppLayout.editResultGlowOffsetY),
        ),
        OffsetDecorationImage(
          assetPath: AppAssets.characterEditResult,
          width: AppLayout.editResultCharacterWidth,
          height: AppLayout.editResultCharacterHeight,
          offset: Offset(0, AppLayout.editResultCharacterOffsetY),
        ),
      ],
    );
  }
}
