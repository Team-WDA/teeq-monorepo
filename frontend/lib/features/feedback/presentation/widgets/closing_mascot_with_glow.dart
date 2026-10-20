import 'package:flutter/widgets.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/ui/decoration/soft_glow_decoration.dart';
import 'package:teeq/core/ui/illustration/teeq_mascot.dart';
import 'package:teeq/core/ui/illustration/teeq_mascot_pose.dart';

/// 통화 마무리 화면의 마스코트와 그 뒤의 큰 빛 번짐. 빛 번짐은 화면 폭을 넘어 번지며 장식이라 터치를 받지 않는다.
class ClosingMascotWithGlow extends StatelessWidget {
  const ClosingMascotWithGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: AppLayout.closingGlowTopOffset,
          left: 0,
          right: 0,
          height: AppLayout.closingGlowSize,
          child: const OverflowBox(
            minWidth: 0,
            maxWidth: AppLayout.closingGlowSize,
            child: SoftGlowDecoration(
              assetPath: AppAssets.closingGlow,
              width: AppLayout.closingGlowSize,
              height: AppLayout.closingGlowSize,
            ),
          ),
        ),
        const TeeqMascot(
          pose: TeeqMascotPose.welcome,
          width: AppLayout.closingMascotWidth,
        ),
      ],
    );
  }
}
