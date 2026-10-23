import 'package:material_ui/material_ui.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/app.dart';
import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/auth/auth_status_controller.dart';
import 'package:teeq/core/auth/auth_tokens.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/auth/sign_in_result.dart';
import 'package:teeq/core/auth/token_storage.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/router/splash_minimum_display_controller.dart';
import 'package:teeq/core/ui/button/app_back_button.dart';
import 'package:teeq/features/auth/data/auth_repository_impl.dart';
import 'package:teeq/features/auth/data/firebase_social_credential_provider.dart';
import 'package:teeq/features/auth/presentation/signup_completion_consent_screen.dart';
import 'package:teeq/features/auth/presentation/signup_nickname_screen.dart';
import 'package:teeq/features/auth/presentation/welcome_screen.dart';
import 'package:teeq/features/onboarding/presentation/onboarding_introduction_screen.dart';

import '../support/fake_auth_repository.dart';
import '../support/fake_auth_status_controller.dart';
import '../support/fake_social_credential_provider.dart';
import '../support/fake_splash_minimum_display_controller.dart';
import '../support/fake_token_storage.dart';

const _member = Member(
  memberId: 'member-1',
  nickname: '티큐',
  hasAiCharacter: false,
  loginType: LoginType.google,
);

DioException _apiError(ErrorCode errorCode, int status) => DioException(
  requestOptions: RequestOptions(path: '/api/auth'),
  error: ApiException(errorCode: errorCode, httpStatus: status),
);

/// 로그아웃 상태로 앱을 띄운다. 첫 로그인은 가입이 필요한 계정(404)으로 응답한다.
Future<(FakeAuthRepository, FakeSocialCredentialProvider)> _pumpApp(
  WidgetTester tester, {
  Object? socialSignUpError,
}) async {
  final repository = FakeAuthRepository(
    signInResult: const SignInResult(
      tokens: AuthTokens(accessToken: 'access', refreshToken: 'refresh'),
      member: _member,
    ),
    socialLoginError: _apiError(ErrorCode.socialSignupRequired, 404),
    socialSignUpError: socialSignUpError,
  );
  final socialProvider = FakeSocialCredentialProvider();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        splashMinimumDisplayControllerProvider.overrideWith(
          () => FakeSplashMinimumDisplayController(true),
        ),
        authStatusControllerProvider.overrideWith(
          () => FakeAuthStatusController(AuthStatus.signedOut),
        ),
        tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
        authRepositoryProvider.overrideWithValue(repository),
        socialCredentialProviderProvider.overrideWithValue(socialProvider),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
  return (repository, socialProvider);
}

Future<void> _startGoogleSignIn(WidgetTester tester) async {
  await tester.tap(find.text('Google로 시작하기'));
  await tester.pumpAndSettle();
}

Future<void> _agreeAllAndProceed(WidgetTester tester) async {
  await tester.tap(find.text('전체 동의'));
  await tester.pump();
  await tester.tap(find.text('다음'));
  await tester.pumpAndSettle();
}

Future<void> _submitNickname(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), '티큐');
  await tester.pump();
  await tester.tap(find.text('다음'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('가입이 필요한 계정이 약관과 닉네임을 마치면 온보딩 소개 화면에 도착한다', (tester) async {
    final (repository, _) = await _pumpApp(tester);

    await _startGoogleSignIn(tester);
    expect(find.byType(SignupCompletionConsentScreen), findsOneWidget);
    await _agreeAllAndProceed(tester);
    expect(find.byType(SignupNicknameScreen), findsOneWidget);
    await _submitNickname(tester);

    expect(repository.socialSignUpCount, 1);
    expect(repository.socialSignUpRequest?.credential, 'latest-token');
    expect(repository.socialSignUpRequest?.nickname, '티큐');
    expect(repository.socialSignUpRequest?.serviceTermsAgreed, isTrue);
    expect(repository.socialSignUpRequest?.privacyPolicyAgreed, isTrue);
    expect(find.byType(OnboardingIntroductionScreen), findsOneWidget);
    expect(find.byType(SignupNicknameScreen), findsNothing);
    expect(find.byType(SignupCompletionConsentScreen), findsNothing);
    expect(find.byType(WelcomeScreen), findsNothing);
  });

  testWidgets('가입 요청이 STATE_CONFLICT여도 로그인을 다시 시도해 온보딩에 도착한다', (tester) async {
    final (repository, _) = await _pumpApp(
      tester,
      socialSignUpError: _apiError(ErrorCode.stateConflict, 409),
    );
    await _startGoogleSignIn(tester);
    await _agreeAllAndProceed(tester);
    // 이제 서버에는 이미 가입된 계정이라 로그인이 성공한다.
    repository.socialLoginError = null;

    await _submitNickname(tester);

    expect(repository.socialSignUpCount, 1);
    expect(repository.socialLoginCount, 2);
    expect(find.byType(OnboardingIntroductionScreen), findsOneWidget);
  });

  testWidgets('중복 닉네임이면 닉네임 화면에 머문다', (tester) async {
    await _pumpApp(
      tester,
      socialSignUpError: _apiError(ErrorCode.duplicateNickname, 409),
    );
    await _startGoogleSignIn(tester);
    await _agreeAllAndProceed(tester);

    await _submitNickname(tester);

    expect(find.byType(SignupNicknameScreen), findsOneWidget);
    expect(find.byType(OnboardingIntroductionScreen), findsNothing);
  });

  testWidgets('약관에 동의하지 않고 닉네임 화면에 들어오면 약관 화면으로 되돌아간다', (tester) async {
    await _pumpApp(tester);
    await _startGoogleSignIn(tester);

    GoRouter.of(tester.element(find.byType(SignupCompletionConsentScreen)))
        .push(AppRoutes.signupNickname);
    await tester.pumpAndSettle();

    expect(find.byType(SignupNicknameScreen), findsNothing);
    expect(find.byType(SignupCompletionConsentScreen), findsOneWidget);
  });

  testWidgets('약관 화면에서 뒤로가면 시작 화면으로 돌아가고 Firebase 로그아웃은 하지 않는다', (
    tester,
  ) async {
    final (_, socialProvider) = await _pumpApp(tester);
    await _startGoogleSignIn(tester);

    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(SignupCompletionConsentScreen), findsNothing);
    expect(socialProvider.calls, ['signInWithGoogle']);
  });

  testWidgets('닉네임 화면에서 뒤로가기를 누르면 약관 화면으로 돌아온다', (tester) async {
    await _pumpApp(tester);
    await _startGoogleSignIn(tester);
    await _agreeAllAndProceed(tester);

    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();

    expect(find.byType(SignupCompletionConsentScreen), findsOneWidget);
    expect(find.byType(SignupNicknameScreen), findsNothing);
  });
}
