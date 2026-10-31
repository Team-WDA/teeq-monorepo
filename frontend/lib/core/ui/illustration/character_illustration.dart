import 'package:flutter/widgets.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/features/home/domain/character_mood.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';

/// 외형과 표정에 맞는 캐릭터 이미지를 정사각형으로 그린다. 이미지는 바닥 기준선·가로 중심이 정렬돼 있어 화면이 표정별로 보정하지 않는다.
class CharacterIllustration extends StatelessWidget {
  const CharacterIllustration({
    super.key,
    required this.characterType,
    required this.characterMood,
    required this.size,
  });

  final CharacterType characterType;
  final CharacterMood characterMood;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.characterMoodIllustration(characterType, characterMood),
      width: size,
      height: size,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );
  }
}
