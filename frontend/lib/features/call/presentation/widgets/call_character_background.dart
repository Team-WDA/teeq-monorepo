import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/ui/illustration/character_illustration.dart';
import 'package:teeq/core/ui/layout/design_frame_scale_builder.dart';
import 'package:teeq/features/home/domain/character_mood.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';

/// 통화 화면 전체를 덮는 배경. 어두운 바탕 위에 좌우를 뒤집은 큰 캐릭터를 놓고 그 위를 스크림으로 덮는다.
/// 부모가 준 크기를 모두 채우며, 캐릭터 크기와 위치는 화면 폭에 비례한다.
class CallCharacterBackground extends StatelessWidget {
  const CallCharacterBackground({
    super.key,
    required this.characterType,
    required this.characterMood,
  });

  final CharacterType characterType;
  final CharacterMood characterMood;

  @override
  Widget build(BuildContext context) {
    return DesignFrameScaleBuilder(
      builder: (context, scale) {
        final illustrationSize = AppLayout.callBackgroundCharacterSize * scale;
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: AppColors.callScreenBackground),
              Positioned(
                left:
                    AppLayout.callBackgroundCharacterCenterX * scale -
                    illustrationSize / 2,
                top:
                    AppLayout.callBackgroundCharacterGroundY * scale -
                    AppLayout.characterGroundFraction * illustrationSize,
                width: illustrationSize,
                height: illustrationSize,
                // 시안은 캐릭터를 좌우로 뒤집어 놓았다.
                child: Transform.flip(
                  flipX: true,
                  child: CharacterIllustration(
                    characterType: characterType,
                    characterMood: characterMood,
                    size: illustrationSize,
                  ),
                ),
              ),
              const ColoredBox(color: AppColors.callBackgroundScrim),
            ],
          ),
        );
      },
    );
  }
}
