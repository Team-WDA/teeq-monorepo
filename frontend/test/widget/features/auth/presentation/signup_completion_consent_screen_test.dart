import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/button/app_back_button.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
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

    await tester.tap(find.text('[필수] 서비스 이용약관 동의'));
    await tester.pump();

    expect(_nextButtonOnPressed(tester), isNull);
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
