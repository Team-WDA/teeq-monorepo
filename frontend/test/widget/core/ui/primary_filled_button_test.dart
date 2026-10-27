import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/core/ui/progress/button_loading_indicator.dart';

Widget _buildButton({
  required VoidCallback? onPressed,
  bool isLoading = false,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: PrimaryFilledButton(
        label: '다음',
        onPressed: onPressed,
        isLoading: isLoading,
      ),
    ),
  );
}

Color? _backgroundColor(WidgetTester tester) {
  final container = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(PrimaryFilledButton),
          matching: find.byType(Container),
        )
        .first,
  );
  return (container.decoration as BoxDecoration).color;
}

void main() {
  testWidgets('비활성 상태에서는 탭해도 콜백을 부르지 않고 보조 글자색을 쓴다', (tester) async {
    await tester.pumpWidget(_buildButton(onPressed: null));
    await tester.pumpAndSettle();

    final gestureDetector = tester.widget<GestureDetector>(
      find.descendant(
        of: find.byType(PrimaryFilledButton),
        matching: find.byType(GestureDetector),
      ),
    );
    expect(gestureDetector.onTap, isNull);
    final style = DefaultTextStyle.of(tester.element(find.text('다음'))).style;
    expect(style.color, AppColors.textSecondary);
  });

  testWidgets('접근성 탭 액션은 활성 상태에서만 노출한다', (tester) async {
    final semanticsHandle = tester.ensureSemantics();

    await tester.pumpWidget(_buildButton(onPressed: () {}));
    await tester.pumpAndSettle();
    expect(
      tester
          .getSemantics(find.byType(PrimaryFilledButton))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );

    await tester.pumpWidget(_buildButton(onPressed: null));
    await tester.pumpAndSettle();
    expect(
      tester
          .getSemantics(find.byType(PrimaryFilledButton))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isFalse,
    );
    semanticsHandle.dispose();
  });

  testWidgets('활성 상태에서 탭하면 콜백을 한 번 부르고 기본 글자색을 쓴다', (tester) async {
    var pressedCount = 0;
    await tester.pumpWidget(_buildButton(onPressed: () => pressedCount++));
    await tester.pumpAndSettle();

    await tester.tap(find.text('다음'));
    await tester.pump();

    expect(pressedCount, 1);
    final style = DefaultTextStyle.of(tester.element(find.text('다음'))).style;
    expect(style.color, AppColors.textPrimary);
  });

  testWidgets('로딩 중에는 스피너만 보이고 탭을 무시하며 활성 배경을 유지한다', (tester) async {
    final semanticsHandle = tester.ensureSemantics();
    var pressedCount = 0;
    await tester.pumpWidget(
      _buildButton(onPressed: () => pressedCount++, isLoading: true),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ButtonLoadingIndicator), findsOneWidget);
    expect(find.text('다음'), findsNothing);
    expect(_backgroundColor(tester), AppColors.accent);
    final data = tester
        .getSemantics(find.byType(PrimaryFilledButton))
        .getSemanticsData();
    expect(data.label, buttonLoadingSemanticsLabel);
    expect(data.hasAction(SemanticsAction.tap), isFalse);
    final gestureDetector = tester.widget<GestureDetector>(
      find.descendant(
        of: find.byType(PrimaryFilledButton),
        matching: find.byType(GestureDetector),
      ),
    );
    expect(gestureDetector.onTap, isNull);
    await tester.tap(find.byType(PrimaryFilledButton));
    await tester.pump();
    expect(pressedCount, 0);
    semanticsHandle.dispose();
  });

  testWidgets('onPressed가 null이어도 로딩이 이겨 강조 배경을 쓴다', (tester) async {
    await tester.pumpWidget(_buildButton(onPressed: null, isLoading: true));
    await tester.pump(const Duration(milliseconds: 300));

    expect(_backgroundColor(tester), AppColors.accent);
  });

  testWidgets('로딩 중과 아닐 때의 버튼 높이가 같다', (tester) async {
    await tester.pumpWidget(_buildButton(onPressed: () {}));
    await tester.pump(const Duration(milliseconds: 300));
    final idleHeight = tester.getSize(find.byType(PrimaryFilledButton)).height;

    await tester.pumpWidget(_buildButton(onPressed: () {}, isLoading: true));
    await tester.pump(const Duration(milliseconds: 300));
    final loadingHeight = tester
        .getSize(find.byType(PrimaryFilledButton))
        .height;

    expect(loadingHeight, idleHeight);
  });

  testWidgets('로딩이 아니고 onPressed가 null이면 회색 비활성 배경이다', (tester) async {
    await tester.pumpWidget(_buildButton(onPressed: null));
    await tester.pump(const Duration(milliseconds: 300));

    expect(_backgroundColor(tester), AppColors.neutralSurface);
  });
}
