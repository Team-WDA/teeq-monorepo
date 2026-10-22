import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/app.dart';
import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/auth/auth_status_controller.dart';
import 'package:teeq/core/router/splash_minimum_display_controller.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/router/app_router.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/features/home/data/home_repository_impl.dart';
import 'package:teeq/features/home/domain/home_summary.dart';
import 'package:teeq/features/home/presentation/home_screen.dart';
import 'package:teeq/features/onboarding/data/ai_character_repository_impl.dart';
import 'package:teeq/features/onboarding/domain/ai_character.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';
import 'package:teeq/features/onboarding/domain/onboarding_question.dart';
import 'package:teeq/features/onboarding/presentation/character_edit_confirmation_dialog.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_controller.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_state.dart';
import 'package:teeq/features/onboarding/presentation/onboarding_introduction_screen.dart';

import '../../../support/fake_ai_character_repository.dart';
import '../../../support/fake_auth_status_controller.dart';
import '../../../support/fake_splash_minimum_display_controller.dart';
import '../../../support/fake_home_repository.dart';

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

const _unnamedCharacter = AiCharacter(
  characterType: CharacterType.character3,
  personalityTags: ['다정함', '차분함', '유쾌함'],
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
  required FakeAiCharacterRepository repository,
}) async {
  final container = ProviderContainer(
    overrides: [
      splashMinimumDisplayControllerProvider.overrideWith(
        () => FakeSplashMinimumDisplayController(true),
      ),
      authStatusControllerProvider.overrideWith(
        () => FakeAuthStatusController(AuthStatus.signedIn),
      ),
      currentMemberControllerProvider.overrideWith(
        () => _FakeCurrentMemberController(member),
      ),
      aiCharacterRepositoryProvider.overrideWithValue(repository),
      homeRepositoryProvider.overrideWithValue(
        FakeHomeRepository(summary: _homeSummary),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const App()),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pump();
  await tester.tap(find.text(text));
  await tester.pump();
}

/// 질문 7개를 각 첫 선택지로 채운다(7번은 2개 선택). 마지막 "다음" 뒤 생성 중 화면까지 간다.
Future<void> _answerAllQuestions(WidgetTester tester) async {
  for (final question in OnboardingQuestion.values) {
    final selectionCount = question.isMultipleChoice ? 2 : 1;
    for (final option in question.options.take(selectionCount)) {
      await _tapText(tester, option.label);
    }
    await _tapText(tester, '다음');
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('first-time flow completes from intro to home', (tester) async {
    final repository = FakeAiCharacterRepository(
      generateResult: _unnamedCharacter,
      confirmNameResult: _namedCharacter,
    );
    final container = await _pumpApp(
      tester,
      member: _memberWithoutCharacter,
      repository: repository,
    );
    expect(find.byType(OnboardingIntroductionScreen), findsOneWidget);

    await tester.tap(find.text('나만의 티크 만들기'));
    await tester.pumpAndSettle();
    expect(find.text('우리,\n어떤 사이로 지낼까?'), findsOneWidget);

    await _answerAllQuestions(tester);
    expect(find.text('거의 다 왔어.\n너의 티큐 친구가 태어나고 있어!'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 4500));
    await tester.pumpAndSettle();
    expect(find.text('마지막으로,\n이 친구의 이름을 정해줘.'), findsOneWidget);
    expect(repository.generateCalls, hasLength(1));

    await tester.enterText(find.byType(TextField), '티티');
    await tester.pump();
    await tester.tap(find.text('이 이름으로 시작하기'));
    await tester.pumpAndSettle();
    expect(repository.confirmedNames, ['티티']);
    expect(find.text('반가워!\n난 티티야.'), findsOneWidget);

    await tester.tap(find.text('대화 시작하기'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      container.read(currentMemberControllerProvider)?.hasAiCharacter,
      true,
    );
    expect(
      container.read(characterSetupFlowControllerProvider),
      CharacterSetupFlowState.initial,
    );
  });

  testWidgets('edit flow reuses the screens', (tester) async {
    final repository = FakeAiCharacterRepository(
      generateResult: _namedCharacter,
      confirmNameResult: _namedCharacter,
    );
    final container = await _pumpApp(
      tester,
      member: _memberWithCharacter,
      repository: repository,
    );
    expect(find.byType(HomeScreen), findsOneWidget);

    // ignore: unawaited_futures
    showCharacterEditConfirmationDialog(
      tester.element(find.byType(HomeScreen)),
      characterName: '티티',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('다시 설정하기'));
    await tester.pumpAndSettle();
    expect(find.text('우리,\n어떤 사이로 지낼까?'), findsOneWidget);

    await _answerAllQuestions(tester);
    await tester.pump(const Duration(milliseconds: 4500));
    await tester.pumpAndSettle();

    expect(find.text('마지막으로,\n이 친구의 이름을 정해줘.'), findsOneWidget);
    final nameField = tester.widget<TextField>(find.byType(TextField));
    expect(nameField.controller?.text, '티티');

    await tester.tap(find.text('이 이름으로 시작하기'));
    await tester.pumpAndSettle();
    expect(find.text('티티가\n이렇게 바뀌었어!'), findsOneWidget);

    await tester.tap(find.text('홈으로 돌아가기'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      container.read(currentMemberControllerProvider)?.hasAiCharacter,
      true,
    );
    expect(
      container.read(characterSetupFlowControllerProvider),
      CharacterSetupFlowState.initial,
    );
  });

  group('direct entry without flow state is redirected', () {
    testWidgets('member without character goes to intro', (tester) async {
      final container = await _pumpApp(
        tester,
        member: _memberWithoutCharacter,
        repository: FakeAiCharacterRepository(),
      );

      for (final location in [
        AppRoutes.characterResult,
        AppRoutes.characterName,
      ]) {
        container.read(appRouterProvider).go(location);
        await tester.pumpAndSettle();
        expect(find.byType(OnboardingIntroductionScreen), findsOneWidget);
      }
    });

    testWidgets('member with character goes home', (tester) async {
      final container = await _pumpApp(
        tester,
        member: _memberWithCharacter,
        repository: FakeAiCharacterRepository(),
      );

      for (final location in [
        AppRoutes.characterResult,
        AppRoutes.characterName,
      ]) {
        container.read(appRouterProvider).go(location);
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
      }
    });

    testWidgets('incomplete selections send generating back to questions', (
      tester,
    ) async {
      final container = await _pumpApp(
        tester,
        member: _memberWithCharacter,
        repository: FakeAiCharacterRepository(),
      );

      container.read(appRouterProvider).go(AppRoutes.onboardingGenerating);
      await tester.pumpAndSettle();

      expect(find.text('우리,\n어떤 사이로 지낼까?'), findsOneWidget);
    });

    testWidgets(
      'unnamed character is redirected from result but passes name route',
      (tester) async {
        final container = await _pumpApp(
          tester,
          member: _memberWithoutCharacter,
          repository: FakeAiCharacterRepository(),
        );
        container
            .read(characterSetupFlowControllerProvider.notifier)
            .recordCharacter(_unnamedCharacter);

        container.read(appRouterProvider).go(AppRoutes.characterResult);
        await tester.pumpAndSettle();
        expect(find.byType(OnboardingIntroductionScreen), findsOneWidget);

        container.read(appRouterProvider).go(AppRoutes.characterName);
        await tester.pumpAndSettle();
        expect(find.text('마지막으로,\n이 친구의 이름을 정해줘.'), findsOneWidget);
      },
    );
  });
}
