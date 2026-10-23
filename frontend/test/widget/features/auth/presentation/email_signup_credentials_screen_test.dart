import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/features/auth/domain/signup_draft.dart';
import 'package:teeq/features/auth/presentation/email_signup_credentials_screen.dart';
import 'package:teeq/features/auth/presentation/signup_draft_controller.dart';

late ProviderContainer _container;

Future<GoRouter> _pumpScreen(WidgetTester tester) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const EmailSignupCredentialsScreen(),
      ),
      GoRoute(
        path: AppRoutes.signupNickname,
        builder: (context, state) => const Text('닉네임 스텁'),
      ),
      GoRoute(path: '/other', builder: (context, state) => const Text('다른 화면')),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: _container,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
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

Future<void> _agreeToAll(WidgetTester tester) async {
  await tester.ensureVisible(find.text('전체 동의'));
  await tester.tap(find.text('전체 동의'));
  await tester.pump();
}

void main() {
  setUp(() => _container = ProviderContainer());
  tearDown(() => _container.dispose());

  testWidgets('유효한 입력이어도 약관 미동의면 다음이 비활성이다', (tester) async {
    await _pumpScreen(tester);

    await _enter(tester, 'a@b.co', 'Abcdef12');

    expect(_nextButtonOnPressed(tester), isNull);
  });

  testWidgets('약관 전체 동의와 유효한 입력이면 다음이 활성이다', (tester) async {
    await _pumpScreen(tester);

    await _enter(tester, 'a@b.co', 'Abcdef12');
    await _agreeToAll(tester);

    expect(_nextButtonOnPressed(tester), isNotNull);
  });

  testWidgets('공백이 들어간 비밀번호면 다음이 비활성이다', (tester) async {
    await _pumpScreen(tester);

    await _enter(tester, 'a@b.co', 'Abcdef 12');
    await _agreeToAll(tester);

    expect(_nextButtonOnPressed(tester), isNull);
  });

  testWidgets('이메일 형식이 틀리면 다음이 비활성이다', (tester) async {
    await _pumpScreen(tester);

    await _enter(tester, 'not-an-email', 'Abcdef12');
    await _agreeToAll(tester);

    expect(_nextButtonOnPressed(tester), isNull);
  });

  testWidgets('다음을 탭하면 trim된 이메일로 draft를 저장하고 닉네임 화면으로 이동한다', (tester) async {
    await _pumpScreen(tester);
    await _enter(tester, ' a@b.co ', 'Abcdef12');
    await _agreeToAll(tester);

    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    expect(
      _container.read(signupDraftControllerProvider),
      const SignupDraft(
        mode: SignupMode.emailSignup,
        email: 'a@b.co',
        password: 'Abcdef12',
        isServiceTermsAgreed: true,
        isPrivacyPolicyAgreed: true,
      ),
    );
    expect(find.text('닉네임 스텁'), findsOneWidget);
  });

  testWidgets('다음을 연속으로 탭해도 닉네임 화면은 한 번만 열린다', (tester) async {
    final router = await _pumpScreen(tester);
    await _enter(tester, 'a@b.co', 'Abcdef12');
    await _agreeToAll(tester);

    await tester.tap(find.text('다음'));
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();

    expect(find.text('닉네임 스텁'), findsNothing);
    expect(find.byType(EmailSignupCredentialsScreen), findsOneWidget);
  });

  testWidgets('draft는 가입 화면이 스택에 있는 동안만 유지된다', (tester) async {
    final router = await _pumpScreen(tester);
    await _enter(tester, 'a@b.co', 'Abcdef12');
    await _agreeToAll(tester);

    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(_container.read(signupDraftControllerProvider).email, 'a@b.co');

    router.pop();
    await tester.pumpAndSettle();
    expect(_container.read(signupDraftControllerProvider).email, 'a@b.co');

    router.go('/other');
    await tester.pumpAndSettle();
    expect(find.text('다른 화면'), findsOneWidget);
    expect(_container.read(signupDraftControllerProvider), SignupDraft.empty);
  });
}
