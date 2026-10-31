import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/features/call/presentation/widgets/call_slide_to_answer.dart';

import '../../../../support/viewport_cases.dart';

const _defaultViewport = ViewportCase(width: 393, height: 852, textScale: 1.0);

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

Finder get _handle => find.descendant(
  of: find.byType(CallSlideToAnswer),
  matching: find.byType(GestureDetector),
);

void main() {
  testWidgets('calls onCompleted exactly once when dragged to the end', (
    tester,
  ) async {
    var completedCount = 0;
    await pumpAtViewport(
      tester,
      _defaultViewport,
      _wrap(CallSlideToAnswer(onCompleted: () => completedCount++)),
    );

    final gesture = await tester.startGesture(tester.getCenter(_handle));
    await gesture.moveBy(const Offset(200, 0));
    await gesture.moveBy(const Offset(200, 0));
    await gesture.moveBy(const Offset(100, 0));
    await gesture.up();
    await tester.pump();

    expect(completedCount, 1);

    // 완료 뒤 다시 끌어도 다시 부르지 않는다.
    await tester.drag(_handle, const Offset(500, 0));
    await tester.pump();
    expect(completedCount, 1);
  });

  testWidgets('does not complete and returns when released midway', (
    tester,
  ) async {
    var completedCount = 0;
    await pumpAtViewport(
      tester,
      _defaultViewport,
      _wrap(CallSlideToAnswer(onCompleted: () => completedCount++)),
    );
    final startPosition = tester.getTopLeft(_handle);

    await tester.drag(_handle, const Offset(100, 0));
    await tester.pump();

    expect(completedCount, 0);
    expect(tester.getTopLeft(_handle), startPosition);
  });

  testWidgets('follows the finger while dragging', (tester) async {
    await pumpAtViewport(
      tester,
      _defaultViewport,
      _wrap(CallSlideToAnswer(onCompleted: () {})),
    );
    final startPosition = tester.getTopLeft(_handle);

    final gesture = await tester.startGesture(tester.getCenter(_handle));
    await gesture.moveBy(const Offset(40, 0));
    await gesture.moveBy(const Offset(60, 0));
    await tester.pump();

    expect(tester.getTopLeft(_handle).dx, greaterThan(startPosition.dx));
    await gesture.up();
  });

  testWidgets('keeps the handle inside the track when the width shrinks', (
    tester,
  ) async {
    var completedCount = 0;
    Widget sliderWithWidth(double width) => _wrap(
      SizedBox(
        width: width,
        child: CallSlideToAnswer(onCompleted: () => completedCount++),
      ),
    );
    await pumpAtViewport(tester, _defaultViewport, sliderWithWidth(345));

    final gesture = await tester.startGesture(tester.getCenter(_handle));
    await gesture.moveBy(const Offset(40, 0));
    await gesture.moveBy(const Offset(160, 0));
    await tester.pump();

    await tester.pumpWidget(sliderWithWidth(200));
    final trackRect = tester.getRect(find.byType(CallSlideToAnswer));
    expect(tester.getRect(_handle).right, lessThanOrEqualTo(trackRect.right));
    expect(completedCount, 0);
    await gesture.up();
  });

  for (final viewport in viewportCases) {
    testWidgets('renders without overflow at ${viewport.label}', (
      tester,
    ) async {
      await pumpAtViewport(
        tester,
        viewport,
        _wrap(CallSlideToAnswer(onCompleted: () {})),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('밀어서 통화하기'), findsOneWidget);
    });
  }
}
