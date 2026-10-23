import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/features/auth/domain/auth_flow.dart';
import 'package:teeq/features/auth/presentation/auth_flow_provider.dart';
import 'package:teeq/features/auth/presentation/email_login_screen.dart';

class _RecordingAuthFlow extends Fake implements AuthFlow {
  final List<String> requestedEmails = [];
  Completer<SignInOutcome> pendingRequest = Completer<SignInOutcome>();

  @override
  Future<SignInOutcome> signInWithEmail({
    required String email,
    required String password,
  }) {
    requestedEmails.add(email);
    return pendingRequest.future;
  }
}

class _RecordingErrorHandler extends Fake implements ErrorHandler {
  final List<Object> handledErrors = [];

  @override
  void handle(Object error, {bool blocking = false}) {
    handledErrors.add(error);
  }
}

Future<(_RecordingAuthFlow, _RecordingErrorHandler)> _pumpScreen(
  WidgetTester tester,
) async {
  final authFlow = _RecordingAuthFlow();
  final errorHandler = _RecordingErrorHandler();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authFlowProvider.overrideWithValue(authFlow),
        errorHandlerProvider.overrideWithValue(errorHandler),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const EmailLoginScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return (authFlow, errorHandler);
}

VoidCallback? _nextButtonOnPressed(WidgetTester tester) {
  return tester
      .widget<PrimaryFilledButton>(find.byType(PrimaryFilledButton))
      .onPressed;
}

Future<void> _enter(WidgetTester tester, String email, String password) async {
  await tester.enterText(find.byType(TextField).at(0), email);
  await tester.enterText(find.byType(TextField).at(1), password);
  await tester.pump();
}

void main() {
  testWidgets('리빌드 전에 onPressed를 두 번 불러도 요청은 한 번이다', (tester) async {
    final (authFlow, _) = await _pumpScreen(tester);
    await _enter(tester, 'a@b.co', 'Abcdef12');

    final onPressed = _nextButtonOnPressed(tester)!;
    onPressed();
    onPressed();
    await tester.pump();

    expect(authFlow.requestedEmails, ['a@b.co']);
  });

  testWidgets('입력 전에는 다음이 비활성이다', (tester) async {
    final (authFlow, _) = await _pumpScreen(tester);

    expect(_nextButtonOnPressed(tester), isNull);
    await tester.tap(find.text('다음'));
    expect(authFlow.requestedEmails, isEmpty);
  });

  testWidgets('앞뒤 공백이 있는 이메일도 형식이 맞으면 활성이다', (tester) async {
    await _pumpScreen(tester);

    await _enter(tester, ' a@b.co ', 'Abcdef12');

    expect(_nextButtonOnPressed(tester), isNotNull);
  });

  testWidgets('이메일 형식이 틀리면 비활성이다', (tester) async {
    await _pumpScreen(tester);

    await _enter(tester, 'not-an-email', 'Abcdef12');

    expect(_nextButtonOnPressed(tester), isNull);
  });

  testWidgets('비밀번호가 비어 있으면 비활성이다', (tester) async {
    await _pumpScreen(tester);

    await _enter(tester, 'a@b.co', '');

    expect(_nextButtonOnPressed(tester), isNull);
  });

  testWidgets('요청 중에는 다음이 비활성이고 전달된 이메일은 trim된다', (tester) async {
    final (authFlow, _) = await _pumpScreen(tester);
    await _enter(tester, ' a@b.co ', 'Abcdef12');

    await tester.tap(find.text('다음'));
    await tester.tap(find.text('다음'));
    await tester.pump();

    expect(authFlow.requestedEmails, ['a@b.co']);
    expect(_nextButtonOnPressed(tester), isNull);
  });

  testWidgets('실패하면 오류를 ErrorHandler로 넘기고 다음이 다시 활성화된다', (tester) async {
    final (authFlow, errorHandler) = await _pumpScreen(tester);
    await _enter(tester, 'a@b.co', 'Abcdef12');

    await tester.tap(find.text('다음'));
    await tester.pump();
    final failure = Exception('로그인 실패');
    authFlow.pendingRequest.completeError(failure);
    await tester.pump();
    await tester.pump();

    expect(errorHandler.handledErrors, [failure]);
    expect(_nextButtonOnPressed(tester), isNotNull);
  });

  testWidgets('입력칸 힌트는 시안 문구를 쓴다', (tester) async {
    await _pumpScreen(tester);

    expect(find.text('이메일을 입력해줘.'), findsOneWidget);
    expect(find.text('비밀번호를 입력해줘.'), findsOneWidget);
  });

  testWidgets('가입이 필요한 계정이면 약관 화면을 push한다', (tester) async {
    final authFlow = _RecordingAuthFlow();
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const Text('시작 스텁')),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const EmailLoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.signupCompletion,
          builder: (context, state) => const Text('약관 스텁'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authFlowProvider.overrideWithValue(authFlow),
          errorHandlerProvider.overrideWithValue(_RecordingErrorHandler()),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(router.push(AppRoutes.login));
    await tester.pumpAndSettle();
    await _enter(tester, 'a@b.co', 'Abcdef12');

    await tester.tap(find.text('다음'));
    await tester.pump();
    authFlow.pendingRequest.complete(SignInOutcome.signupRequired);
    await tester.pumpAndSettle();

    expect(find.text('약관 스텁'), findsOneWidget);
  });
}
