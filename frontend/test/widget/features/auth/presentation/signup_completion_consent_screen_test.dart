import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/button/app_back_button.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/core/ui/checkbox/rounded_square_checkbox.dart';
import 'package:teeq/features/auth/presentation/signup_completion_consent_screen.dart';

Future<void> _pumpScreen(WidgetTester tester) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SignupCompletionConsentScreen(),
      ),
      GoRoute(
        path: AppRoutes.signupNickname,
        builder: (context, state) => const Text('닉네임 스텁'),
      ),
      GoRoute(
        path: AppRoutes.serviceTerms,
        builder: (context, state) => const Text('서비스 이용약관 스텁'),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) => const Text('개인정보 처리방침 스텁'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

VoidCallback? _nextButtonOnPressed(WidgetTester tester) {
  return tester
      .widget<PrimaryFilledButton>(find.byType(PrimaryFilledButton))
      .onPressed;
}

void main() {
  testWidgets('동의 전에는 다음이 비활성이다', (tester) async {
    await _pumpScreen(tester);

    expect(_nextButtonOnPressed(tester), isNull);
  });

  testWidgets('필수 항목 하나만 동의하면 다음이 비활성이다', (tester) async {
    await _pumpScreen(tester);

    await tester.tap(find.byType(RoundedSquareCheckbox).at(1));
    await tester.pump();

    expect(_nextButtonOnPressed(tester), isNull);
  });

  testWidgets('약관 문구를 탭하면 상세로 이동하고 돌아와도 체크 상태가 유지된다', (tester) async {
    await _pumpScreen(tester);
    await tester.tap(find.byType(RoundedSquareCheckbox).at(1));
    await tester.pump();

    await tester.tap(find.text('[필수] 서비스 이용약관 동의'));
    await tester.pumpAndSettle();
    expect(find.text('서비스 이용약관 스텁'), findsOneWidget);

    tester.element(find.text('서비스 이용약관 스텁')).pop();
    await tester.pumpAndSettle();

    final checkboxes = tester.widgetList<RoundedSquareCheckbox>(
      find.byType(RoundedSquareCheckbox),
    );
    expect(checkboxes.map((checkbox) => checkbox.isChecked), [
      false,
      true,
      false,
    ]);
  });

  testWidgets('약관 문구를 연속으로 두 번 탭해도 이동은 한 번이다', (tester) async {
    await _pumpScreen(tester);

    await tester.tap(find.text('[필수] 개인정보 수집·이용 동의'));
    await tester.tap(find.text('[필수] 개인정보 수집·이용 동의'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('개인정보 처리방침 스텁'), findsOneWidget);
    tester.element(find.text('개인정보 처리방침 스텁')).pop();
    await tester.pumpAndSettle();
    expect(find.text('개인정보 처리방침 스텁'), findsNothing);
    expect(find.byType(SignupCompletionConsentScreen), findsOneWidget);
  });

  testWidgets('전체 동의 후 다음이 활성이고 닉네임 화면으로 이동한다', (tester) async {
    await _pumpScreen(tester);

    await tester.tap(find.text('전체 동의'));
    await tester.pump();
    expect(_nextButtonOnPressed(tester), isNotNull);

    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    expect(find.text('닉네임 스텁'), findsOneWidget);
  });

  testWidgets('뒤로가기 버튼을 누르면 이전 화면으로 돌아간다', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const Text('시작 스텁')),
        GoRoute(
          path: AppRoutes.signupCompletion,
          builder: (context, state) => const SignupCompletionConsentScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(router.push(AppRoutes.signupCompletion));
    await tester.pumpAndSettle();
    expect(find.byType(AppBackButton), findsOneWidget);

    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();

    expect(find.text('시작 스텁'), findsOneWidget);
    expect(find.byType(SignupCompletionConsentScreen), findsNothing);
  });
}
