import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/ui/button/app_back_button.dart';
import 'package:teeq/features/onboarding/presentation/onboarding_introduction_screen.dart';

void main() {
  testWidgets('제목, 카드 문구 3개, 버튼이 보이고 뒤로 가기는 없다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const OnboardingIntroductionScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('이제\n너만의 티크를\n만들 차례야!'), findsOneWidget);
    expect(find.text('너에 대해 조금 더 알아보고'), findsOneWidget);
    expect(find.text('어떤 대화를 좋아하는지 말해주면'), findsOneWidget);
    expect(find.text('너만의 티크가 준비 돼!'), findsOneWidget);
    expect(find.text('나만의 티크 만들기'), findsOneWidget);
    expect(find.byType(AppBackButton), findsNothing);
  });
}
