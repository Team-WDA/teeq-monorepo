import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/ui/progress/button_loading_indicator.dart';
import 'package:teeq/features/auth/presentation/widgets/google_sign_in_button.dart';

Widget _buildButton({
  required VoidCallback? onPressed,
  bool isLoading = false,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: GoogleSignInButton(onPressed: onPressed, isLoading: isLoading),
    ),
  );
}

BoxDecoration _decoration(WidgetTester tester) {
  final container = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(GoogleSignInButton),
          matching: find.byType(Container),
        )
        .first,
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  testWidgets('활성 상태에서는 흰 배경과 테두리를 쓰고 접근성 탭을 한 번만 부른다', (tester) async {
    final semanticsHandle = tester.ensureSemantics();
    var pressedCount = 0;
    await tester.pumpWidget(_buildButton(onPressed: () => pressedCount++));

    expect(_decoration(tester).color, AppColors.background);
    expect(_decoration(tester).border, isNotNull);
    tester.semantics.tap(find.semantics.byLabel('Google로 시작하기'));
    await tester.pump();
    expect(pressedCount, 1);
    semanticsHandle.dispose();
  });

  testWidgets('로딩 중에는 스피너만 보이고 탭을 무시하며 흰 배경을 유지한다', (tester) async {
    final semanticsHandle = tester.ensureSemantics();
    var pressedCount = 0;
    await tester.pumpWidget(
      _buildButton(onPressed: () => pressedCount++, isLoading: true),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ButtonLoadingIndicator), findsOneWidget);
    expect(find.text('Google로 시작하기'), findsNothing);
    expect(_decoration(tester).color, AppColors.background);
    final data = tester
        .getSemantics(find.byType(GoogleSignInButton))
        .getSemanticsData();
    expect(data.label, buttonLoadingSemanticsLabel);
    expect(data.hasAction(SemanticsAction.tap), isFalse);
    await tester.tap(find.byType(GoogleSignInButton));
    await tester.pump();
    expect(pressedCount, 0);
    semanticsHandle.dispose();
  });

  testWidgets('onPressed가 null이어도 로딩이 이겨 흰 배경을 쓴다', (tester) async {
    await tester.pumpWidget(_buildButton(onPressed: null, isLoading: true));
    await tester.pump(const Duration(milliseconds: 300));

    expect(_decoration(tester).color, AppColors.background);
  });

  testWidgets('로딩이 아니고 onPressed가 null이면 회색 배경·보조 글자색·테두리 없음이다', (
    tester,
  ) async {
    await tester.pumpWidget(_buildButton(onPressed: null));
    await tester.pump(const Duration(milliseconds: 300));

    expect(_decoration(tester).color, AppColors.neutralSurface);
    expect(_decoration(tester).border, isNull);
    final text = tester.widget<Text>(find.text('Google로 시작하기'));
    expect(text.style?.color, AppColors.textSecondary);
  });
}
