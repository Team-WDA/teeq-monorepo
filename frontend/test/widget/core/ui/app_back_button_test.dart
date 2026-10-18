import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/ui/button/app_back_button.dart';

void main() {
  testWidgets('접근성 탭 액션으로 콜백을 한 번 부른다', (tester) async {
    final semanticsHandle = tester.ensureSemantics();
    var pressedCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: AppBackButton(onPressed: () => pressedCount++)),
      ),
    );

    final semanticsData = tester
        .getSemantics(find.byType(AppBackButton))
        .getSemanticsData();
    expect(semanticsData.label, '뒤로 가기');
    expect(semanticsData.hasAction(SemanticsAction.tap), isTrue);

    tester.semantics.tap(find.semantics.byLabel('뒤로 가기'));
    await tester.pump();

    expect(pressedCount, 1);
    semanticsHandle.dispose();
  });
}
