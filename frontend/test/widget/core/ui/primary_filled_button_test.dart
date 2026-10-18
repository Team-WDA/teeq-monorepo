import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';

Widget _buildButton({required VoidCallback? onPressed}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: PrimaryFilledButton(label: '다음', onPressed: onPressed),
    ),
  );
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
}
