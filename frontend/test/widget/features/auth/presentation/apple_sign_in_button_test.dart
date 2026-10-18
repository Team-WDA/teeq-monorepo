import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/features/auth/presentation/widgets/apple_sign_in_button.dart';

Widget _buildButton({required VoidCallback? onPressed}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: AppleSignInButton(onPressed: onPressed)),
  );
}

bool _hasTapAction(WidgetTester tester) {
  return tester
      .getSemantics(find.byType(AppleSignInButton))
      .getSemanticsData()
      .hasAction(SemanticsAction.tap);
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
}
