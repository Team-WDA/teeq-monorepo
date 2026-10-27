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
  Completer<SignupOutcome> pendingRequest = Completer<SignupOutcome>();

  @override
  Future<SignupOutcome> completeSignup({
    required SignupDraft draft,
    required String nickname,
  }) {
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
    mode: SignupMode.emailSignup,
    email: 'user@example.com',
    password: 'Abcdef12',
    isServiceTermsAgreed: true,
    isPrivacyPolicyAgreed: true,
  );
}

const String _guidanceText = '한글만 2~10자 · 공백 없이 입력해줘';

late ProviderContainer _container;

Future<(_RecordingAuthFlow, _RecordingErrorHandler)> _pumpScreen(
  WidgetTester tester,
) async {
  final authFlow = _RecordingAuthFlow();
  final errorHandler = _RecordingErrorHandler();
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const Text('약관 단계 스텁')),
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
  _container = ProviderContainer(
    overrides: [
      authFlowProvider.overrideWithValue(authFlow),
      errorHandlerProvider.overrideWithValue(errorHandler),
      signupDraftControllerProvider.overrideWith(
        _FixedSignupDraftController.new,
      ),
    ],
  );
  addTearDown(_container.dispose);
  // 화면 이동으로 autoDispose provider가 정리돼도 상태를 읽을 수 있게 붙잡아 둔다.
  _container.listen(signupDraftControllerProvider, (previous, next) {});
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: _container,
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

  testWidgets('연속 탭해도 요청은 한 번이다', (tester) async {
    final (authFlow, _) = await _pumpScreen(tester);
    await _enterNickname(tester, '티큐');

    await tester.tap(find.text('다음'));
    await tester.tap(find.text('다음'));
    await tester.pump();

    expect(authFlow.requestedNicknames, ['티큐']);
    expect(_nextButtonOnPressed(tester), isNull);
  });

  testWidgets('처음부터 안내 문구가 보인다', (tester) async {
    await _pumpScreen(tester);

    expect(find.text(_guidanceText), findsOneWidget);
  });

  testWidgets('1자는 짧다는 오류를 보이고 다음이 비활성이다', (tester) async {
    await _pumpScreen(tester);
    await _enterNickname(tester, '소');

    expect(find.text('2자 이상으로 입력해줘'), findsOneWidget);
    expect(_nextButtonOnPressed(tester), isNull);
  });

  testWidgets('11자는 길다는 오류를 보인다', (tester) async {
    await _pumpScreen(tester);
    await _enterNickname(tester, '가나다라마바사아자차카');

    expect(find.text('10자 이하로 입력해줘'), findsOneWidget);
  });

  testWidgets('한글이 아닌 문자는 한글만 입력하라는 오류를 보인다', (tester) async {
    await _pumpScreen(tester);
    await _enterNickname(tester, '소연A1!');

    expect(find.text('한글만 입력할 수 있어. 영문,숫자,특수문자는 빼줘.'), findsOneWidget);
  });

  testWidgets('중간 공백은 공백 없이 입력하라는 오류를 보인다', (tester) async {
    await _pumpScreen(tester);
    await _enterNickname(tester, '소 연');

    expect(find.text('공백 없이 입력해줘'), findsOneWidget);
  });

  testWidgets('끝 공백도 오류이고 다음이 비활성이다', (tester) async {
    await _pumpScreen(tester);
    await _enterNickname(tester, '소연 ');

    expect(find.text('공백 없이 입력해줘'), findsOneWidget);
    expect(_nextButtonOnPressed(tester), isNull);
  });

  testWidgets('유효한 닉네임이면 오류가 없고 다음이 활성이다', (tester) async {
    await _pumpScreen(tester);
    await _enterNickname(tester, '소연');

    expect(find.text('2자 이상으로 입력해줘'), findsNothing);
    expect(find.text('10자 이하로 입력해줘'), findsNothing);
    expect(find.text('공백 없이 입력해줘'), findsNothing);
    expect(find.text('한글만 입력할 수 있어. 영문,숫자,특수문자는 빼줘.'), findsNothing);
    expect(_nextButtonOnPressed(tester), isNotNull);
  });

  testWidgets('성공하면 온보딩으로 이동한다', (tester) async {
    final (authFlow, _) = await _pumpScreen(tester);
    await _enterNickname(tester, '티큐');

    await tester.tap(find.text('다음'));
    await tester.pump();
    authFlow.pendingRequest.complete(SignupOutcome.signedIn);
    await tester.pumpAndSettle();

    expect(find.text('온보딩 스텁'), findsOneWidget);
  });

  testWidgets('닉네임 중복이면 오류를 넘기고 화면에 남는다', (tester) async {
    final (authFlow, errorHandler) = await _pumpScreen(tester);
    await _enterNickname(tester, '티큐');

    await tester.tap(find.text('다음'));
    await tester.pump();
    const failure = ApiException(
      errorCode: ErrorCode.duplicateNickname,
      httpStatus: 409,
    );
    authFlow.pendingRequest.completeError(failure);
    await tester.pump();
    await tester.pump();

    expect(errorHandler.handledErrors, [failure]);
    expect(find.byType(SignupNicknameScreen), findsOneWidget);
    expect(_nextButtonOnPressed(tester), isNotNull);
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

  testWidgets('성공하면 draft의 비밀번호를 비운다', (tester) async {
    final (authFlow, _) = await _pumpScreen(tester);
    await _enterNickname(tester, '티큐');

    await tester.tap(find.text('다음'));
    await tester.pump();
    authFlow.pendingRequest.complete(SignupOutcome.signedIn);
    await tester.pumpAndSettle();

    expect(_container.read(signupDraftControllerProvider).password, isEmpty);
  });

  testWidgets('닉네임 사전 확인에서 걸리면 중복 닉네임 오류를 알리고 비밀번호를 유지한다', (tester) async {
    final (authFlow, errorHandler) = await _pumpScreen(tester);
    await _enterNickname(tester, '티큐');

    await tester.tap(find.text('다음'));
    await tester.pump();
    authFlow.pendingRequest.complete(SignupOutcome.nicknameUnavailable);
    await tester.pump();
    await tester.pump();

    final handled = errorHandler.handledErrors.single as ApiException;
    expect(handled.errorCode, ErrorCode.duplicateNickname);
    expect(find.byType(SignupNicknameScreen), findsOneWidget);
    expect(_nextButtonOnPressed(tester), isNotNull);
    expect(_container.read(signupDraftControllerProvider).password, 'Abcdef12');
  });

  testWidgets('실패하면 같은 비밀번호로 다시 시도할 수 있게 비밀번호를 유지한다', (tester) async {
    final (authFlow, _) = await _pumpScreen(tester);
    await _enterNickname(tester, '티큐');

    await tester.tap(find.text('다음'));
    await tester.pump();
    authFlow.pendingRequest.completeError(Exception('가입 실패'));
    await tester.pump();
    await tester.pump();

    expect(_container.read(signupDraftControllerProvider).password, 'Abcdef12');
  });
}
