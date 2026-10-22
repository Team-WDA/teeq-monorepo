import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/features/auth/domain/auth_flow.dart';
import 'package:teeq/features/auth/domain/signup_draft.dart';
import 'package:teeq/features/auth/presentation/auth_flow_provider.dart';
import 'package:teeq/features/auth/presentation/signup_draft_controller.dart';
import 'package:teeq/features/auth/presentation/signup_nickname_screen.dart';

class _RecordingAuthFlow extends Fake implements AuthFlow {
  final List<String> requestedNicknames = [];
  final List<String> requestedEmails = [];
  Completer<void> pendingRequest = Completer<void>();

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String nickname,
    required bool serviceTermsAgreed,
    required bool privacyPolicyAgreed,
  }) {
    requestedEmails.add(email);
    requestedNicknames.add(nickname);
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

class _FixedSignupDraftController extends SignupDraftController {
  @override
  SignupDraft build() => const SignupDraft(
    email: 'a@b.co',
    password: 'Abcdef12',
    isServiceTermsAgreed: true,
    isPrivacyPolicyAgreed: true,
  );
}

Future<(_RecordingAuthFlow, _RecordingErrorHandler)> _pumpScreen(
  WidgetTester tester,
) async {
  final authFlow = _RecordingAuthFlow();
  final errorHandler = _RecordingErrorHandler();
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const Text('이메일 단계 스텁')),
      GoRoute(
        path: '/nickname',
        builder: (context, state) => const SignupNicknameScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const Text('온보딩 스텁'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authFlowProvider.overrideWithValue(authFlow),
        errorHandlerProvider.overrideWithValue(errorHandler),
        signupDraftControllerProvider.overrideWith(
          _FixedSignupDraftController.new,
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  unawaited(router.push('/nickname'));
  await tester.pumpAndSettle();
  return (authFlow, errorHandler);
}

VoidCallback? _nextButtonOnPressed(WidgetTester tester) {
  return tester
      .widget<PrimaryFilledButton>(find.byType(PrimaryFilledButton))
      .onPressed;
}

Future<void> _enterNickname(WidgetTester tester, String nickname) async {
  await tester.enterText(find.byType(TextField), nickname);
  await tester.pump();
}

void main() {
  testWidgets('닉네임 길이와 문자 경계에 따라 다음이 활성화된다', (tester) async {
    await _pumpScreen(tester);

    final cases = <String, bool>{
      '가': false,
      '가나': true,
      '가나다라마바사아자차': true,
      '가나다라마바사아자차카': false,
      '티큐!': false,
    };
    for (final entry in cases.entries) {
      await _enterNickname(tester, entry.key);
      expect(
        _nextButtonOnPressed(tester) != null,
        entry.value,
        reason: entry.key,
      );
    }
  });

  testWidgets('연속 탭해도 요청은 한 번이고 닉네임은 trim되어 전달된다', (tester) async {
    final (authFlow, _) = await _pumpScreen(tester);
    await _enterNickname(tester, ' 티큐 ');

    await tester.tap(find.text('다음'));
    await tester.tap(find.text('다음'));
    await tester.pump();

    expect(authFlow.requestedNicknames, ['티큐']);
    expect(authFlow.requestedEmails, ['a@b.co']);
    expect(_nextButtonOnPressed(tester), isNull);
  });

  testWidgets('성공하면 온보딩으로 이동한다', (tester) async {
    final (authFlow, _) = await _pumpScreen(tester);
    await _enterNickname(tester, '티큐');

    await tester.tap(find.text('다음'));
    await tester.pump();
    authFlow.pendingRequest.complete();
    await tester.pumpAndSettle();

    expect(find.text('온보딩 스텁'), findsOneWidget);
  });

  testWidgets('이메일 중복이면 오류를 넘기고 이메일 단계로 돌아간다', (tester) async {
    final (authFlow, errorHandler) = await _pumpScreen(tester);
    await _enterNickname(tester, '티큐');

    await tester.tap(find.text('다음'));
    await tester.pump();
    const failure = ApiException(
      errorCode: ErrorCode.duplicateEmail,
      httpStatus: 409,
    );
    authFlow.pendingRequest.completeError(failure);
    await tester.pumpAndSettle();

    expect(errorHandler.handledErrors, [failure]);
    expect(find.text('이메일 단계 스텁'), findsOneWidget);
  });

  testWidgets('그 외 오류면 화면에 남고 다음이 다시 활성화된다', (tester) async {
    final (authFlow, errorHandler) = await _pumpScreen(tester);
    await _enterNickname(tester, '티큐');

    await tester.tap(find.text('다음'));
    await tester.pump();
    final failure = Exception('가입 실패');
    authFlow.pendingRequest.completeError(failure);
    await tester.pump();
    await tester.pump();

    expect(errorHandler.handledErrors, [failure]);
    expect(find.byType(SignupNicknameScreen), findsOneWidget);
    expect(_nextButtonOnPressed(tester), isNotNull);
  });
}
