import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/ui/illustration/character_illustration.dart';
import 'package:teeq/features/home/domain/character_mood.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';

void main() {
  testWidgets('characterIllustration_drawsMatchingAssetAtGivenSize', (
    tester,
  ) async {
    const illustrationSize = 120.0;
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: CharacterIllustration(
            characterType: CharacterType.character3,
            characterMood: CharacterMood.curious,
            size: illustrationSize,
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      image.image,
      const AssetImage('assets/images/character_3_mood_curious.png'),
    );
    expect(image.width, illustrationSize);
    expect(image.height, illustrationSize);
    expect(image.fit, BoxFit.contain);
    expect(image.excludeFromSemantics, isTrue);
  });
}
