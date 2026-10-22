import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/app.dart';
import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/auth/auth_status_controller.dart';
import 'package:teeq/core/router/splash_minimum_display_controller.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/auth/token_storage.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/button/app_back_button.dart';
import 'package:teeq/features/auth/data/auth_repository_impl.dart';
import 'package:teeq/features/auth/presentation/signup_completion_consent_screen.dart';
import 'package:teeq/features/auth/presentation/signup_nickname_screen.dart';
import 'package:teeq/features/onboarding/presentation/onboarding_introduction_screen.dart';

import '../support/fake_auth_repository.dart';
import '../support/fake_auth_status_controller.dart';
import '../support/fake_splash_minimum_display_controller.dart';
import '../support/fake_current_member_controller.dart';
import '../support/fake_token_storage.dart';

const _incompleteMember = Member(
  memberId: 'member-1',
  hasAiCharacter: false,
  loginType: LoginType.apple,
);

const _completedMember = Member(
  memberId: 'member-1',
  nickname: '티큐',
  hasAiCharacter: false,
  loginType: LoginType.apple,
);

Future<FakeAuthRepository> _pumpIncompleteAppleMemberApp(
  WidgetTester tester, {
  Object? completeSignupError,
}) async {
  final repository = FakeAuthRepository(
    member: _completedMember,
    completeSignupError: completeSignupError,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        splashMinimumDisplayControllerProvider.overrideWith(
          () => FakeSplashMinimumDisplayController(true),
        ),
        authStatusControllerProvider.overrideWith(
          () => FakeAuthStatusController(AuthStatus.signedIn),
        ),
        currentMemberControllerProvider.overrideWith(
          () => FakeCurrentMemberController(_incompleteMember),
        ),
        tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
        authRepositoryProvider.overrideWithValue(repository),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

Future<void> _agreeAllAndProceed(WidgetTester tester) async {
  await tester.tap(find.text('전체 동의'));
  await tester.pump();
  await tester.tap(find.text('다음'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Apple 가입 미완료 회원이 약관과 닉네임을 마치면 온보딩 소개 화면에 도착한다', (tester) async {
    final repository = await _pumpIncompleteAppleMemberApp(tester);
    expect(find.byType(SignupCompletionConsentScreen), findsOneWidget);

    await _agreeAllAndProceed(tester);

    expect(find.byType(SignupNicknameScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField), '티큐');
    await tester.pump();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    expect(repository.completeSignupCount, 1);
    expect(repository.completedSignup?.nickname, '티큐');
    expect(repository.completedSignup?.serviceTermsAgreed, isTrue);
    expect(repository.completedSignup?.privacyPolicyAgreed, isTrue);
    expect(find.byType(OnboardingIntroductionScreen), findsOneWidget);
    expect(find.byType(SignupNicknameScreen), findsNothing);
    expect(find.byType(SignupCompletionConsentScreen), findsNothing);
  });

  testWidgets('서버는 이미 가입을 마쳤다는 STATE_CONFLICT를 받아도 온보딩 소개 화면에 도착한다', (
    tester,
  ) async {
    final repository = await _pumpIncompleteAppleMemberApp(
      tester,
      completeSignupError: DioException(
        requestOptions: RequestOptions(
          path: '/api/members/me/signup-completion',
        ),
        error: const ApiException(
          errorCode: ErrorCode.stateConflict,
          httpStatus: 409,
        ),
      ),
    );

    await _agreeAllAndProceed(tester);
    await tester.enterText(find.byType(TextField), '티큐');
    await tester.pump();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    expect(repository.completeSignupCount, 1);
    expect(repository.fetchMeCount, 1);
    expect(find.byType(OnboardingIntroductionScreen), findsOneWidget);
    expect(find.byType(SignupNicknameScreen), findsNothing);
  });

  testWidgets('약관에 동의하지 않고 닉네임 화면에 들어오면 약관 화면으로 되돌아간다', (tester) async {
    final repository = await _pumpIncompleteAppleMemberApp(tester);

    GoRouter.of(tester.element(find.byType(SignupCompletionConsentScreen)))
        .push(AppRoutes.signupNickname);
    await tester.pumpAndSettle();

    expect(find.byType(SignupNicknameScreen), findsNothing);
    expect(find.byType(SignupCompletionConsentScreen), findsOneWidget);
    expect(repository.completeSignupCount, 0);
  });

  testWidgets('닉네임 화면에서 뒤로가기를 누르면 약관 화면으로 돌아온다', (tester) async {
    await _pumpIncompleteAppleMemberApp(tester);

    await _agreeAllAndProceed(tester);
    expect(find.byType(SignupNicknameScreen), findsOneWidget);

    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();

    expect(find.byType(SignupCompletionConsentScreen), findsOneWidget);
    expect(find.byType(SignupNicknameScreen), findsNothing);
  });
}
