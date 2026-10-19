import 'package:flutter/widgets.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/ui/illustration/teeq_mascot_pose.dart';

/// 자세와 폭만 받아 마스코트를 그린다. 자세별 에셋 매핑은 이 위젯 한 곳에만 둔다.
/// 비율은 이미지 원본을 따르고, 장식이라 접근성 트리에서 뺀다.
class TeeqMascot extends StatelessWidget {
  const TeeqMascot({super.key, required this.pose, required this.width});

  final TeeqMascotPose pose;
  final double width;

  String get _assetPath => switch (pose) {
    TeeqMascotPose.welcome => AppAssets.teeqBunnyWink,
    TeeqMascotPose.excited => AppAssets.teeqBunnyJoyfulJump,
    TeeqMascotPose.celebration => AppAssets.teeqBunnyCelebration,
  };

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assetPath,
      width: width,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );
  }
}
