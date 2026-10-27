import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/ui/progress/button_loading_indicator.dart';
import 'package:teeq/features/auth/presentation/widgets/apple_sign_in_button.dart';

Widget _buildButton({
  required VoidCallback? onPressed,
  bool isLoading = false,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: AppleSignInButton(onPressed: onPressed, isLoading: isLoading),
    ),
  );
}

bool _hasTapAction(WidgetTester tester) {
  return tester
      .getSemantics(find.byType(AppleSignInButton))
      .getSemanticsData()
      .hasAction(SemanticsAction.tap);
}

Color? _backgroundColor(WidgetTester tester) {
  final container = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(AppleSignInButton),
          matching: find.byType(Container),
        )
        .first,
  );
  return (container.decoration as BoxDecoration).color;
}

void main() {
  testWidgets('접근성 탭 액션은 활성 상태에서만 노출하고 한 번만 부른다', (tester) async {
    final semanticsHandle = tester.ensureSemantics();
    var pressedCount = 0;

    await tester.pumpWidget(_buildButton(onPressed: () => pressedCount++));
    expect(_hasTapAction(tester), isTrue);

    tester.semantics.tap(find.semantics.byLabel('Apple로 시작하기'));
    await tester.pump();
    expect(pressedCount, 1);

    await tester.pumpWidget(_buildButton(onPressed: null));
    expect(_hasTapAction(tester), isFalse);
    semanticsHandle.dispose();
  });

  testWidgets('로딩 중에는 스피너만 보이고 탭을 무시하며 검정 배경을 유지한다', (tester) async {
    final semanticsHandle = tester.ensureSemantics();
    var pressedCount = 0;
    await tester.pumpWidget(
      _buildButton(onPressed: () => pressedCount++, isLoading: true),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ButtonLoadingIndicator), findsOneWidget);
    expect(find.text('Apple로 시작하기'), findsNothing);
    expect(_backgroundColor(tester), AppColors.textPrimary);
    expect(_hasTapAction(tester), isFalse);
    expect(
      tester
          .getSemantics(find.byType(AppleSignInButton))
          .getSemanticsData()
          .label,
      buttonLoadingSemanticsLabel,
    );
    await tester.tap(find.byType(AppleSignInButton));
    await tester.pump();
    expect(pressedCount, 0);
    semanticsHandle.dispose();
  });

  testWidgets('onPressed가 null이어도 로딩이 이겨 검정 배경을 쓴다', (tester) async {
    await tester.pumpWidget(_buildButton(onPressed: null, isLoading: true));
    await tester.pump(const Duration(milliseconds: 300));

    expect(_backgroundColor(tester), AppColors.textPrimary);
  });

  testWidgets('로딩이 아니고 onPressed가 null이면 회색 비활성 외형이다', (tester) async {
    await tester.pumpWidget(_buildButton(onPressed: null));
    await tester.pump(const Duration(milliseconds: 300));

    expect(_backgroundColor(tester), AppColors.neutralSurface);
    final style = DefaultTextStyle.of(tester.element(find.text('Apple로 시작하기')))
        .style;
    final text = tester.widget<Text>(find.text('Apple로 시작하기'));
    expect(text.style?.color ?? style.color, AppColors.textSecondary);
  });
}
