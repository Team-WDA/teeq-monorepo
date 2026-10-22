import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/app.dart';
import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/auth/auth_status_controller.dart';
import 'package:teeq/core/router/splash_minimum_display_controller.dart';
import 'package:teeq/core/auth/auth_tokens.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/auth/sign_in_result.dart';
import 'package:teeq/core/auth/token_storage.dart';
import 'package:teeq/features/auth/data/auth_repository_impl.dart';
import 'package:teeq/features/auth/presentation/email_signup_credentials_screen.dart';
import 'package:teeq/features/auth/presentation/signup_nickname_screen.dart';
import 'package:teeq/features/auth/presentation/welcome_screen.dart';
import 'package:teeq/features/onboarding/presentation/onboarding_introduction_screen.dart';

import '../support/fake_auth_repository.dart';
import '../support/fake_auth_status_controller.dart';
import '../support/fake_splash_minimum_display_controller.dart';
import '../support/fake_token_storage.dart';

const _completedMember = Member(
  memberId: 'member-1',
  nickname: '티큐',
  hasAiCharacter: false,
  loginType: LoginType.email,
);

void main() {
  testWidgets('이메일 가입을 마치면 온보딩 소개 화면에 도착한다', (tester) async {
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
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              signInResult: const SignInResult(
                tokens: AuthTokens(
                  accessToken: 'access',
                  refreshToken: 'refresh',
                ),
                member: _completedMember,
              ),
            ),
          ),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('가입하기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'a@b.co');
    await tester.enterText(find.byType(TextField).at(1), 'Abcdef12');
    await tester.ensureVisible(find.text('전체 동의'));
    await tester.tap(find.text('전체 동의'));
    await tester.pump();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    expect(find.byType(SignupNicknameScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField), '티큐');
    await tester.pump();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingIntroductionScreen), findsOneWidget);
    expect(find.byType(SignupNicknameScreen), findsNothing);
    expect(find.byType(EmailSignupCredentialsScreen), findsNothing);
    expect(find.byType(WelcomeScreen), findsNothing);
  });
}
