import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/ui/button/destructive_tonal_button.dart';
import 'package:teeq/core/ui/button/neutral_filled_button.dart';
import 'package:teeq/core/ui/button/rounded_pill_button.dart';
import 'package:teeq/core/ui/progress/button_loading_indicator.dart';

Widget _wrap(Widget button) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: button),
  );
}

/// 로딩 중 버튼이 스피너만 보이고, 라벨이 '처리 중'이며, 탭을 무시하는지 확인한다.
void _expectLoadingBehavior(
  WidgetTester tester, {
  required Type buttonType,
  required String label,
}) {
  expect(find.byType(ButtonLoadingIndicator), findsOneWidget);
  expect(find.text(label), findsNothing);
  final data = tester.getSemantics(find.byType(buttonType)).getSemanticsData();
  expect(data.label, buttonLoadingSemanticsLabel);
  expect(data.hasAction(SemanticsAction.tap), isFalse);
}

void main() {
  Future<void> verifyLoading(
    WidgetTester tester, {
    required Widget Function(VoidCallback onPressed) build,
    required Type buttonType,
    required String label,
  }) async {
    final semanticsHandle = tester.ensureSemantics();
    var pressedCount = 0;
    await tester.pumpWidget(_wrap(build(() => pressedCount++)));
    await tester.pump(const Duration(milliseconds: 300));

    _expectLoadingBehavior(tester, buttonType: buttonType, label: label);
    await tester.tap(find.byType(buttonType));
    await tester.pump();
    expect(pressedCount, 0);
    semanticsHandle.dispose();
  }

  testWidgets('NeutralFilledButton은 로딩 중 스피너만 보이고 탭을 무시한다', (tester) async {
    await verifyLoading(
      tester,
      buttonType: NeutralFilledButton,
      label: '취소',
      build: (onPressed) => NeutralFilledButton(
        label: '취소',
        onPressed: onPressed,
        isLoading: true,
      ),
    );
  });

  testWidgets('DestructiveTonalButton은 로딩 중 스피너만 보이고 탭을 무시한다', (tester) async {
    await verifyLoading(
      tester,
      buttonType: DestructiveTonalButton,
      label: '로그아웃',
      build: (onPressed) => DestructiveTonalButton(
        label: '로그아웃',
        onPressed: onPressed,
        isLoading: true,
      ),
    );
  });

  testWidgets('RoundedPillButton 채움 방식은 로딩 중 스피너만 보이고 탭을 무시한다', (tester) async {
    await verifyLoading(
      tester,
      buttonType: RoundedPillButton,
      label: '확인',
      build: (onPressed) =>
          RoundedPillButton(label: '확인', onPressed: onPressed, isLoading: true),
    );
  });

  testWidgets('RoundedPillButton 테두리 방식은 로딩 중 스피너만 보이고 탭을 무시한다', (
    tester,
  ) async {
    await verifyLoading(
      tester,
      buttonType: RoundedPillButton,
      label: '확인',
      build: (onPressed) => RoundedPillButton(
        label: '확인',
        onPressed: onPressed,
        style: RoundedPillButtonStyle.outlined,
        isLoading: true,
      ),
    );
  });

  testWidgets('로딩이 아니면 글자를 보이고 스피너는 없다', (tester) async {
    await tester.pumpWidget(
      _wrap(NeutralFilledButton(label: '취소', onPressed: () {})),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('취소'), findsOneWidget);
    expect(find.byType(ButtonLoadingIndicator), findsNothing);
  });
}
