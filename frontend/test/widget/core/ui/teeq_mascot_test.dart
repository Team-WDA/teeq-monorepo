import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/ui/illustration/teeq_mascot.dart';
import 'package:teeq/core/ui/illustration/teeq_mascot_pose.dart';
import 'package:teeq/features/home/presentation/current_character_type_provider.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';

const _mascotWidth = 120.0;
const _heightRatioByPose = {
  TeeqMascotPose.welcome: 0.8598,
  TeeqMascotPose.excited: 1.0,
  TeeqMascotPose.celebration: 0.9364,
};
const _assetNameByPose = {
  TeeqMascotPose.welcome: 'welcome',
  TeeqMascotPose.excited: 'excited',
  TeeqMascotPose.celebration: 'celebrate',
};

Future<void> _pumpMascot(
  WidgetTester tester,
  TeeqMascotPose pose, {
  List overrides = const [],
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [...overrides],
      child: MaterialApp(
        home: Center(
          child: TeeqMascot(pose: pose, width: _mascotWidth),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('mascot_layoutBoxFollowsPoseRatio', (tester) async {
    for (final pose in TeeqMascotPose.values) {
      await _pumpMascot(tester, pose);
      final box = tester.getSize(
        find
            .descendant(
              of: find.byType(TeeqMascot),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(box.width, _mascotWidth, reason: pose.name);
      expect(
        box.height,
        closeTo(_mascotWidth * _heightRatioByPose[pose]!, 0.001),
        reason: pose.name,
      );
    }
  });

  testWidgets('mascot_withoutMember_drawsCharacterOneForEachPose', (
    tester,
  ) async {
    for (final pose in TeeqMascotPose.values) {
      await _pumpMascot(tester, pose);
      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as AssetImage).assetName,
        'assets/images/character_1_mood_${_assetNameByPose[pose]}.png',
        reason: pose.name,
      );
      expect(image.width, _mascotWidth, reason: pose.name);
      expect(image.excludeFromSemantics, isTrue, reason: pose.name);
      expect(tester.takeException(), isNull, reason: pose.name);
    }
  });

  testWidgets('mascot_usesCurrentCharacterType', (tester) async {
    await _pumpMascot(
      tester,
      TeeqMascotPose.excited,
      overrides: [
        currentCharacterTypeProvider.overrideWithValue(
          CharacterType.character3,
        ),
      ],
    );
    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/character_3_mood_excited.png',
    );
  });
}
