import 'package:teeq/app.dart';
import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/auth/auth_status_controller.dart';
import 'package:teeq/core/auth/auth_tokens.dart';
import 'package:teeq/core/router/splash_minimum_display_controller.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/auth/token_storage.dart';
import 'package:teeq/features/app_update/domain/app_update_requirement.dart';
import 'package:teeq/features/app_update/presentation/app_update_controller.dart';
import 'package:teeq/features/app_update/presentation/update_required_screen.dart';
import 'package:teeq/features/auth/data/auth_repository_impl.dart';
import 'package:teeq/features/auth/presentation/welcome_screen.dart';
import 'package:teeq/features/home/data/home_repository_impl.dart';
import 'package:teeq/features/home/domain/home_summary.dart';
import 'package:teeq/features/home/presentation/home_screen.dart';
import 'package:teeq/features/onboarding/presentation/onboarding_introduction_screen.dart';
import 'package:teeq/features/splash/presentation/splash_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_app_update_controller.dart';
import '../support/fake_auth_repository.dart';
import '../support/fake_auth_status_controller.dart';
import '../support/fake_splash_minimum_display_controller.dart';
import '../support/fake_current_member_controller.dart';
import '../support/fake_home_repository.dart';
import '../support/fake_token_storage.dart';

const _homeSummary = HomeSummary(
  characterName: '티티',
  personalityTags: ['다정함', '차분함', '유쾌함'],
  greeting: '소연아,\n오늘 하루 어땠어?',
);

Future<void> _pumpSignedInApp(WidgetTester tester, Member member) async {
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
          () => FakeCurrentMemberController(member),
        ),
        homeRepositoryProvider.overrideWithValue(
          FakeHomeRepository(summary: _homeSummary),
        ),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('signedOut 상태에서는 시작 화면을 보여 준다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          splashMinimumDisplayControllerProvider.overrideWith(
            () => FakeSplashMinimumDisplayController(true),
          ),
          authStatusControllerProvider.overrideWith(
            () => FakeAuthStatusController(AuthStatus.signedOut),
          ),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('signedIn 상태에서는 홈 화면을 보여 준다', (tester) async {
    await _pumpSignedInApp(
      tester,
      const Member(
        memberId: 'member-1',
        nickname: '소연',
        hasAiCharacter: true,
        loginType: LoginType.google,
      ),
    );

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('소연아,\n오늘 하루 어땠어?'), findsOneWidget);
    expect(find.text('티티'), findsOneWidget);
  });

  testWidgets('signedIn + 캐릭터가 있는 회원이면 홈 화면을 보여 준다', (tester) async {
    await _pumpSignedInApp(
      tester,
      const Member(
        memberId: 'member-1',
        nickname: '티큐',
        hasAiCharacter: true,
        loginType: LoginType.apple,
      ),
    );

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('signedIn + 가입 완료 + 캐릭터 없는 회원이면 온보딩 시작 화면을 보여 준다', (
    tester,
  ) async {
    await _pumpSignedInApp(
      tester,
      const Member(
        memberId: 'member-1',
        nickname: '티큐',
        hasAiCharacter: false,
        loginType: LoginType.apple,
      ),
    );

    expect(find.byType(OnboardingIntroductionScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('빈 저장소로 시작하면 복원이 끝나도 1.5초까지 스플래시에 머문 뒤 시작 화면을 보여 준다', (
    tester,
  ) async {
    final tokenStorage = FakeTokenStorage();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokenStorage),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          appUpdateControllerProvider.overrideWith(FakeAppUpdateController.new),
        ],
        child: const App(),
      ),
    );

    // 복원 완료와 리다이렉트가 반영될 프레임을 먼저 돌린 뒤 1.5초 직전까지 진행한다.
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(
      splashMinimumDisplayDuration - const Duration(milliseconds: 1),
    );
    expect(tokenStorage.readCount, 1);
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing);

    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('저장된 토큰으로 회원 조회가 성공해도 1.5초까지 스플래시에 머문 뒤 홈으로 간다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appUpdateControllerProvider.overrideWith(FakeAppUpdateController.new),
          tokenStorageProvider.overrideWithValue(
            FakeTokenStorage(
              storedTokens: const AuthTokens(
                accessToken: 'access',
                refreshToken: 'refresh',
              ),
            ),
          ),
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              member: const Member(
                memberId: 'member-1',
                nickname: '티큐',
                hasAiCharacter: true,
                loginType: LoginType.apple,
              ),
            ),
          ),
          homeRepositoryProvider.overrideWithValue(
            FakeHomeRepository(summary: _homeSummary),
          ),
        ],
        child: const App(),
      ),
    );

    // 복원 완료와 리다이렉트가 반영될 프레임을 먼저 돌린 뒤 1.5초 직전까지 진행한다.
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(
      splashMinimumDisplayDuration - const Duration(milliseconds: 1),
    );
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);

    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('업데이트가 필요하면 복원을 시작하지 않고 업데이트 필요 화면에 머문다', (tester) async {
    final tokenStorage = FakeTokenStorage();
    late final FakeAppUpdateController updateController;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokenStorage),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          appUpdateControllerProvider.overrideWith(() {
            updateController = FakeAppUpdateController(
              requirement: const AppUpdateRequirement(
                minimumVersion: '1.3.0',
                storeUrl: 'https://store.example.test/teeq',
              ),
            );
            return updateController;
          }),
        ],
        child: const App(),
      ),
    );

    await tester.pump();
    await tester.pump();
    // 화면 전환 애니메이션이 끝나 스플래시가 트리에서 빠질 때까지 1.5초 미만으로 진행한다.
    await tester.pump(const Duration(milliseconds: 500));
    expect(updateController.checkCount, 1);
    expect(find.byType(UpdateRequiredScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
    expect(tokenStorage.readCount, 0);

    await tester.pump(
      splashMinimumDisplayDuration + const Duration(milliseconds: 1),
    );
    await tester.pump();
    expect(find.byType(UpdateRequiredScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
    expect(tokenStorage.readCount, 0);
  });
}
