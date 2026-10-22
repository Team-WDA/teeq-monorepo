import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/app.dart';
import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/auth/auth_status_controller.dart';
import 'package:teeq/core/router/splash_minimum_display_controller.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/auth/token_storage.dart';
import 'package:teeq/core/config/app_version_provider.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/router/app_router.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/navigation/main_bottom_tab_bar.dart';
import 'package:teeq/features/auth/data/auth_repository_impl.dart';
import 'package:teeq/features/auth/presentation/welcome_screen.dart';
import 'package:teeq/features/error/presentation/error_screen.dart';
import 'package:teeq/features/home/data/home_repository_impl.dart';
import 'package:teeq/features/home/domain/home_summary.dart';
import 'package:teeq/features/home/presentation/home_screen.dart';
import 'package:teeq/features/my_page/presentation/my_page_screen.dart';
import 'package:teeq/features/onboarding/domain/ai_character.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';
import 'package:teeq/features/onboarding/domain/character_setup_mode.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_controller.dart';
import 'package:teeq/features/onboarding/presentation/onboarding_introduction_screen.dart';

import '../../../support/fake_auth_repository.dart';
import '../../../support/fake_auth_status_controller.dart';
import '../../../support/fake_splash_minimum_display_controller.dart';
import '../../../support/fake_home_repository.dart';
import '../../../support/fake_token_storage.dart';
import '../../../support/my_page_harness.dart';

class _FakeCurrentMemberController extends CurrentMemberController {
  _FakeCurrentMemberController(this._initialMember);

  final Member _initialMember;

  @override
  Member? build() => _initialMember;
}

const _memberWithoutCharacter = Member(
  memberId: 'member-1',
  nickname: '티큐',
  hasAiCharacter: false,
  loginType: LoginType.email,
);

final _memberWithCharacter = _memberWithoutCharacter.copyWith(
  hasAiCharacter: true,
);

const _namedCharacter = AiCharacter(
  name: '티티',
  characterType: CharacterType.character3,
  personalityTags: ['다정함', '차분함', '유쾌함'],
);

const _homeSummary = HomeSummary(
  characterName: '티티',
  personalityTags: ['다정함', '차분함', '유쾌함'],
  greeting: '안녕',
);

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  required Member member,
  required FakeHomeRepository homeRepository,
  RecordingErrorHandler? errorHandler,
}) async {
  final container = ProviderContainer(
    // 실패 응답이 재시도되지 않도록 한다.
    retry: (retryCount, error) => null,
    overrides: [
      splashMinimumDisplayControllerProvider.overrideWith(
        () => FakeSplashMinimumDisplayController(true),
      ),
      appVersionProvider.overrideWith((ref) async => '0.15.0'),
      authStatusControllerProvider.overrideWith(
        () => FakeAuthStatusController(AuthStatus.signedIn),
      ),
      currentMemberControllerProvider.overrideWith(
        () => _FakeCurrentMemberController(member),
      ),
      homeRepositoryProvider.overrideWithValue(homeRepository),
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(member: member),
      ),
      tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
      if (errorHandler != null)
        errorHandlerProvider.overrideWithValue(errorHandler),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const App()),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('signed in member with character sees home tab and tab bar', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      member: _memberWithCharacter,
      homeRepository: FakeHomeRepository(summary: _homeSummary),
    );

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(MainBottomTabBar), findsOneWidget);
  });

  testWidgets('tapping my tab shows my page and keeps home state', (
    tester,
  ) async {
    final homeRepository = FakeHomeRepository(summary: _homeSummary);
    await _pumpApp(
      tester,
      member: _memberWithCharacter,
      homeRepository: homeRepository,
    );

    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    expect(find.byType(MyPageScreen), findsOneWidget);

    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(homeRepository.fetchCount, 1);
  });

  testWidgets('repeated taps on same tab do not throw or duplicate pages', (
    tester,
  ) async {
    final homeRepository = FakeHomeRepository(summary: _homeSummary);
    await _pumpApp(
      tester,
      member: _memberWithCharacter,
      homeRepository: homeRepository,
    );

    await tester.tap(find.text('홈'));
    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.text('마이'));
    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();

    expect(find.byType(MyPageScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(homeRepository.fetchCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'member without character on /my-page is redirected to onboarding',
    (tester) async {
      final container = await _pumpApp(
        tester,
        member: _memberWithoutCharacter,
        homeRepository: FakeHomeRepository(summary: _homeSummary),
      );

      container.read(appRouterProvider).go(AppRoutes.myPage);
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingIntroductionScreen), findsOneWidget);
      expect(find.byType(MainBottomTabBar), findsNothing);
    },
  );

  testWidgets('onboarding route does not show the tab bar', (tester) async {
    await _pumpApp(
      tester,
      member: _memberWithoutCharacter,
      homeRepository: FakeHomeRepository(summary: _homeSummary),
    );

    expect(find.byType(OnboardingIntroductionScreen), findsOneWidget);
    expect(find.byType(MainBottomTabBar), findsNothing);
  });

  testWidgets('error route does not show the tab bar', (tester) async {
    final container = await _pumpApp(
      tester,
      member: _memberWithCharacter,
      homeRepository: FakeHomeRepository(summary: _homeSummary),
    );

    container.read(appRouterProvider).go(AppRoutes.error);
    await tester.pumpAndSettle();

    expect(find.byType(ErrorScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byType(MainBottomTabBar), findsNothing);
  });

  testWidgets('logout from my tab shows welcome without error', (tester) async {
    final errorHandler = RecordingErrorHandler();
    await _pumpApp(
      tester,
      member: _memberWithCharacter,
      homeRepository: FakeHomeRepository(summary: _homeSummary),
      errorHandler: errorHandler,
    );
    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('로그아웃'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(ErrorScreen), findsNothing);
    expect(find.byType(MainBottomTabBar), findsNothing);
    expect(errorHandler.handledErrors, isEmpty);
  });

  testWidgets('edit flow return keeps tab shell and shows home', (
    tester,
  ) async {
    final container = await _pumpApp(
      tester,
      member: _memberWithCharacter,
      homeRepository: FakeHomeRepository(summary: _homeSummary),
    );
    container
        .read(characterSetupFlowControllerProvider.notifier)
        .start(CharacterSetupMode.edit);
    container
        .read(characterSetupFlowControllerProvider.notifier)
        .recordCharacter(_namedCharacter);

    container.read(appRouterProvider).go(AppRoutes.characterResult);
    await tester.pumpAndSettle();
    expect(find.byType(MainBottomTabBar), findsNothing);

    await tester.tap(find.text('홈으로 돌아가기'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(MainBottomTabBar), findsOneWidget);
  });
}
