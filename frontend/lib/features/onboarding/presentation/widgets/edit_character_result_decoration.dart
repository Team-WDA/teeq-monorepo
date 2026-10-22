import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/ui/layout/design_frame_scale_builder.dart';
import 'package:teeq/features/onboarding/presentation/widgets/offset_decoration_image.dart';

/// 수정 결과 화면 배경. 화면 가운데의 초록 캐릭터와 빛 번짐.
/// 크기와 위치는 화면 폭에 비례한다.
class EditCharacterResultDecoration extends StatelessWidget {
  const EditCharacterResultDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return DesignFrameScaleBuilder(
      builder: (context, scale) {
        return Stack(
          fit: StackFit.expand,
          children: [
            OffsetDecorationImage(
              assetPath: AppAssets.glowEdit,
              width: AppLayout.editResultGlowWidth * scale,
              height: AppLayout.editResultGlowHeight * scale,
              offset: Offset(0, AppLayout.editResultGlowOffsetY * scale),
            ),
            OffsetDecorationImage(
              assetPath: AppAssets.characterEditResult,
              width: AppLayout.editResultCharacterWidth * scale,
              height: AppLayout.editResultCharacterHeight * scale,
              offset: Offset(0, AppLayout.editResultCharacterOffsetY * scale),
            ),
          ],
        );
      },
    );
  }
}
