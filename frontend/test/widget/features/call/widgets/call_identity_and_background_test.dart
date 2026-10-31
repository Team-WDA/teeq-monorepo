import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/ui/illustration/character_illustration.dart';
import 'package:teeq/features/call/presentation/widgets/call_character_background.dart';
import 'package:teeq/features/call/presentation/widgets/call_identity_header.dart';
import 'package:teeq/features/home/domain/character_mood.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';

import '../../../../support/viewport_cases.dart';

void main() {
  for (final viewport in viewportCases) {
    testWidgets('renders background and header at ${viewport.label}', (
      tester,
    ) async {
      await pumpAtViewport(
        tester,
        viewport,
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: CallCharacterBackground(
                    characterType: CharacterType.character1,
                    characterMood: CharacterMood.welcome,
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: CallIdentityHeader(
                    characterName: '티티',
                    statusLabel: '00:12',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(CharacterIllustration), findsOneWidget);
      expect(find.text('티티'), findsOneWidget);
      expect(find.text('00:12'), findsOneWidget);
    });
  }
}
