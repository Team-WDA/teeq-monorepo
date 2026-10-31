import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/features/call/presentation/widgets/call_controls_bar.dart';

import '../../../../support/viewport_cases.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppLayout.horizontalMargin,
      ),
      child: Center(child: child),
    ),
  ),
);

void main() {
  testWidgets('calls the matching callback for each control', (tester) async {
    final pressedControls = <String>[];
    await tester.pumpWidget(
      _wrap(
        CallControlsBar(
          isSpeakerOn: false,
          isMuted: false,
          onSpeakerPressed: () => pressedControls.add('speaker'),
          onEndPressed: () => pressedControls.add('end'),
          onMutePressed: () => pressedControls.add('mute'),
        ),
      ),
    );

    await tester.tap(find.text('스피커'));
    await tester.tap(find.text('종료'));
    await tester.tap(find.text('음소거'));

    expect(pressedControls, ['speaker', 'end', 'mute']);
  });

  testWidgets('exposes speaker and mute state as toggled semantics', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(
        CallControlsBar(
          isSpeakerOn: true,
          isMuted: false,
          onSpeakerPressed: () {},
          onEndPressed: () {},
          onMutePressed: () {},
        ),
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('스피커')),
      matchesSemantics(
        label: '스피커',
        isButton: true,
        hasToggledState: true,
        isToggled: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('음소거')),
      matchesSemantics(
        label: '음소거',
        isButton: true,
        hasToggledState: true,
        isToggled: false,
        hasTapAction: true,
      ),
    );
    semanticsHandle.dispose();
  });

  for (final viewport in viewportCases) {
    testWidgets('renders without overflow at ${viewport.label}', (
      tester,
    ) async {
      await pumpAtViewport(
        tester,
        viewport,
        _wrap(
          CallControlsBar(
            isSpeakerOn: false,
            isMuted: false,
            onSpeakerPressed: () {},
            onEndPressed: () {},
            onMutePressed: () {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  }
}
