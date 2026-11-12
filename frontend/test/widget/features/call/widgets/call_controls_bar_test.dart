import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_animation_durations.dart';
import 'package:teeq/core/design/app_assets.dart';
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

/// [assetName]을 그리는 [SvgPicture]를 찾는다.
Finder _findSvgAsset(String assetName) => find.byWidgetPredicate((widget) {
  if (widget is! SvgPicture) {
    return false;
  }
  final loader = widget.bytesLoader;
  return loader is SvgAssetLoader && loader.assetName == assetName;
});

Future<void> _pumpControlsBar(
  WidgetTester tester, {
  required bool isSpeakerOn,
  required bool isMuted,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    _wrap(
      CallControlsBar(
        isSpeakerOn: isSpeakerOn,
        isMuted: isMuted,
        onSpeakerPressed: () {},
        onEndPressed: () {},
        onMutePressed: () {},
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('shows inactive assets for speaker and mute when both are off', (
    tester,
  ) async {
    await _pumpControlsBar(tester, isSpeakerOn: false, isMuted: false);

    expect(_findSvgAsset(AppAssets.callSpeakerIcon), findsOneWidget);
    expect(_findSvgAsset(AppAssets.callMuteIcon), findsOneWidget);
    expect(_findSvgAsset(AppAssets.callControlBackground), findsNWidgets(2));
    expect(_findSvgAsset(AppAssets.callSpeakerActiveIcon), findsNothing);
    expect(_findSvgAsset(AppAssets.callMuteActiveIcon), findsNothing);
    expect(_findSvgAsset(AppAssets.callControlActiveBackground), findsNothing);
  });

  testWidgets('shows active assets only for the speaker when it is on', (
    tester,
  ) async {
    await _pumpControlsBar(tester, isSpeakerOn: true, isMuted: false);

    expect(_findSvgAsset(AppAssets.callSpeakerActiveIcon), findsOneWidget);
    expect(_findSvgAsset(AppAssets.callSpeakerIcon), findsNothing);
    expect(
      _findSvgAsset(AppAssets.callControlActiveBackground),
      findsOneWidget,
    );
    expect(_findSvgAsset(AppAssets.callControlBackground), findsOneWidget);
    expect(_findSvgAsset(AppAssets.callMuteIcon), findsOneWidget);
    expect(_findSvgAsset(AppAssets.callMuteActiveIcon), findsNothing);
  });

  testWidgets('shows active assets only for mute when it is on', (
    tester,
  ) async {
    await _pumpControlsBar(tester, isSpeakerOn: false, isMuted: true);

    expect(_findSvgAsset(AppAssets.callMuteActiveIcon), findsOneWidget);
    expect(_findSvgAsset(AppAssets.callMuteIcon), findsNothing);
    expect(
      _findSvgAsset(AppAssets.callControlActiveBackground),
      findsOneWidget,
    );
    expect(_findSvgAsset(AppAssets.callControlBackground), findsOneWidget);
    expect(_findSvgAsset(AppAssets.callSpeakerIcon), findsOneWidget);
    expect(_findSvgAsset(AppAssets.callSpeakerActiveIcon), findsNothing);
  });

  testWidgets(
    'fades from inactive to active assets when the speaker turns on',
    (tester) async {
      await _pumpControlsBar(tester, isSpeakerOn: false, isMuted: false);
      expect(_findSvgAsset(AppAssets.callSpeakerIcon), findsOneWidget);

      await _pumpControlsBar(
        tester,
        isSpeakerOn: true,
        isMuted: false,
        settle: false,
      );
      await tester.pump(AppAnimationDurations.fast ~/ 2);

      // 전환 중에는 이전 자산과 새 자산이 함께 있다.
      expect(_findSvgAsset(AppAssets.callSpeakerIcon), findsOneWidget);
      expect(_findSvgAsset(AppAssets.callSpeakerActiveIcon), findsOneWidget);

      await tester.pumpAndSettle();

      expect(_findSvgAsset(AppAssets.callSpeakerIcon), findsNothing);
      expect(_findSvgAsset(AppAssets.callSpeakerActiveIcon), findsOneWidget);
    },
  );

  testWidgets('does not give the end button an active appearance', (
    tester,
  ) async {
    await _pumpControlsBar(tester, isSpeakerOn: true, isMuted: true);

    expect(_findSvgAsset(AppAssets.callEndIcon), findsOneWidget);
    expect(_findSvgAsset(AppAssets.callEndControlBackground), findsOneWidget);
    expect(
      _findSvgAsset(AppAssets.callControlActiveBackground),
      findsNWidgets(2),
    );
  });

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
