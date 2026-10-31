import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/ui/illustration/character_illustration.dart';
import 'package:teeq/features/home/domain/character_mood.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';

/// 부모 중심에서 [offset]만큼 옮긴 위치에 [size] 정사각형으로 캐릭터를 그린다.
/// 부모보다 커도 오버플로 경고 없이 그려지며, 잘림은 바깥에서 정한다.
class OffsetCharacterIllustration extends StatelessWidget {
  const OffsetCharacterIllustration({
    super.key,
    required this.characterType,
    required this.characterMood,
    required this.size,
    this.offset = Offset.zero,
  });

  final CharacterType characterType;
  final CharacterMood characterMood;
  final double size;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: OverflowBox(
        minWidth: size,
        maxWidth: size,
        minHeight: size,
        maxHeight: size,
        child: CharacterIllustration(
          characterType: characterType,
          characterMood: characterMood,
          size: size,
        ),
      ),
    );
  }
}
