import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/ui/illustration/character_illustration.dart';
import 'package:teeq/core/ui/illustration/teeq_mascot_pose.dart';
import 'package:teeq/features/home/domain/character_mood.dart';
import 'package:teeq/features/home/presentation/current_character_type_provider.dart';

// 자세별 레이아웃 상자의 가로 대비 세로 비율. 옛 이미지 크기(271x233, 265x265, 393x368)에서 온 값이다.
const double _welcomeHeightRatio = 0.8598;
const double _excitedHeightRatio = 1.0;
const double _celebrationHeightRatio = 0.9364;

/// 자세와 폭만 받아 내 캐릭터를 그린다. 자세별 표정·상자 비율 매핑은 이 위젯 한 곳에만 둔다.
/// 정사각형 이미지를 상자 바닥 기준선에 맞춰 위로 넘치게 놓고, 장식이라 접근성 트리에서 뺀다.
class TeeqMascot extends ConsumerWidget {
  const TeeqMascot({super.key, required this.pose, required this.width});

  final TeeqMascotPose pose;
  final double width;

  CharacterMood get _characterMood => switch (pose) {
    TeeqMascotPose.welcome => CharacterMood.welcome,
    TeeqMascotPose.excited => CharacterMood.excited,
    TeeqMascotPose.celebration => CharacterMood.celebrate,
  };

  double get _heightRatio => switch (pose) {
    TeeqMascotPose.welcome => _welcomeHeightRatio,
    TeeqMascotPose.excited => _excitedHeightRatio,
    TeeqMascotPose.celebration => _celebrationHeightRatio,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: width,
      height: width * _heightRatio,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: -(1 - AppLayout.characterGroundFraction) * width,
            child: CharacterIllustration(
              characterType: ref.watch(currentCharacterTypeProvider),
              characterMood: _characterMood,
              size: width,
            ),
          ),
        ],
      ),
    );
  }
}
