import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/router/error_page_arguments.dart';
import 'package:teeq/features/auth/domain/auth_flow.dart';
import 'package:teeq/features/auth/domain/signup_draft.dart';
import 'package:teeq/features/auth/presentation/auth_flow_provider.dart';
import 'package:teeq/features/auth/presentation/email_login_screen.dart';
import 'package:teeq/features/auth/presentation/email_signup_credentials_screen.dart';
import 'package:teeq/features/auth/presentation/signup_completion_screen.dart';
import 'package:teeq/features/auth/presentation/signup_draft_controller.dart';
import 'package:teeq/features/auth/presentation/signup_nickname_screen.dart';
import 'package:teeq/features/auth/presentation/welcome_screen.dart';
import 'package:teeq/features/error/presentation/error_screen.dart';
import 'package:teeq/features/onboarding/data/ai_character_repository_impl.dart';
import 'package:teeq/features/onboarding/domain/ai_character.dart';
import 'package:teeq/features/onboarding/domain/character_setup_mode.dart';
import 'package:teeq/features/onboarding/domain/onboarding_question.dart';
import 'package:teeq/features/onboarding/presentation/character_edit_confirmation_dialog.dart';
import 'package:teeq/features/onboarding/presentation/character_generating_screen.dart';
import 'package:teeq/features/onboarding/presentation/character_name_screen.dart';
import 'package:teeq/features/onboarding/presentation/character_result_screen.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_controller.dart';
import 'package:teeq/features/onboarding/presentation/onboarding_introduction_screen.dart';
import 'package:teeq/features/onboarding/presentation/onboarding_question_screen.dart';
import 'package:teeq/features/splash/presentation/splash_screen.dart';

import '../support/fake_ai_character_repository.dart';
import '../support/viewport_cases.dart';

class _NoopAuthFlow extends Fake implements AuthFlow {
  @override
  Future<void> restore() async {}
}

class _NoopErrorHandler extends Fake implements ErrorHandler {
  @override
  void handle(Object error, {bool blocking = false}) {}
}

/// 화면 하나를 그리는 데 필요한 위젯 트리를 만든다. 정리할 자원은 addTearDown으로 등록한다.
typedef _ScreenBuilder = Widget Function();

/// 의도한 화면이 그려졌는지 확인하는 찾기 조건.
typedef _ScreenFinder = Finder Function();

/// 가장 긴 캐릭터 이름(10자) 기준 최악 내용.
const _longCharacterName = '가나다라마바사아자차';

/// 이름 입력 화면에 넣을 최대 길이 이름.
const _longNickname = '아주아주긴닉네임입니다열자';

const _member = Member(
  memberId: 'member-1',
  nickname: _longNickname,
  hasAiCharacter: false,
  loginType: LoginType.email,
);

const _unnamedCharacter = AiCharacter(
  name: null,
  characterNumber: 3,
  personalityTags: ['다정함', '차분함', '유쾌함'],
);

AiCharacter _namedCharacter(String name) => AiCharacter(
  name: name,
  characterNumber: 3,
  personalityTags: const ['다정함', '차분함', '유쾌함'],
);

class _FixedSignupDraftController extends SignupDraftController {
  @override
  SignupDraft build() => const SignupDraft(
    email: 'a@b.co',
    password: 'Abcdef12',
    isServiceTermsAgreed: true,
    isPrivacyPolicyAgreed: true,
  );
}

ProviderContainer _newContainer({List overrides = const []}) {
  final container = ProviderContainer(
    overrides: [
      errorHandlerProvider.overrideWithValue(_NoopErrorHandler()),
      authFlowProvider.overrideWithValue(_NoopAuthFlow()),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Widget _hostPlain(ProviderContainer container, Widget home) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(theme: AppTheme.light, home: home),
  );
}

Widget _hostRouted(ProviderContainer container, String path, Widget screen) {
  final router = GoRouter(
    initialLocation: path,
    routes: [
      GoRoute(path: path, builder: (_, _) => screen),
      if (path != AppRoutes.home)
        GoRoute(path: AppRoutes.home, builder: (_, _) => const Text('홈 스텁')),
    ],
  );
  addTearDown(router.dispose);
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  );
}

void _startFlow(
  ProviderContainer container, {
  CharacterSetupMode mode = CharacterSetupMode.firstTime,
  int questionIndex = 0,
  AiCharacter? character,
}) {
  final controller = container.read(
    characterSetupFlowControllerProvider.notifier,
  )..start(mode);
  for (var index = 0; index < questionIndex; index++) {
    controller.goToNextQuestion();
  }
  if (character != null) {
    controller.recordCharacter(character);
  }
}

Widget _characterResult(CharacterSetupMode mode, String name) {
  final container = _newContainer();
  _startFlow(container, mode: mode, character: _namedCharacter(name));
  container.read(currentMemberControllerProvider.notifier).update(_member);
  return _hostRouted(
    container,
    AppRoutes.characterResult,
    const CharacterResultScreen(),
  );
}

final Map<String, _ScreenBuilder> _screens = {
  '환영': () => _hostPlain(_newContainer(), const WelcomeScreen()),
  '이메일 로그인': () => _hostPlain(_newContainer(), const EmailLoginScreen()),
  '이메일 가입 자격 증명': () => _hostRouted(
    _newContainer(),
    AppRoutes.signup,
    const EmailSignupCredentialsScreen(),
  ),
  '닉네임': () => _hostRouted(
    _newContainer(
      overrides: [
        signupDraftControllerProvider.overrideWith(
          _FixedSignupDraftController.new,
        ),
      ],
    ),
    AppRoutes.signupNickname,
    const SignupNicknameScreen(),
  ),
  '가입 완료': () => _hostPlain(_newContainer(), const SignupCompletionScreen()),
  '온보딩 시작': () =>
      _hostPlain(_newContainer(), const OnboardingIntroductionScreen()),
  '질문(첫 질문)': () {
    final container = _newContainer();
    _startFlow(container);
    return _hostRouted(
      container,
      AppRoutes.onboardingQuestions,
      const OnboardingQuestionScreen(),
    );
  },
  '질문(복수 선택 마지막 질문)': () {
    final container = _newContainer();
    _startFlow(container, questionIndex: OnboardingQuestion.values.length - 1);
    return _hostRouted(
      container,
      AppRoutes.onboardingQuestions,
      const OnboardingQuestionScreen(),
    );
  },
  '생성 중': () {
    final container = _newContainer(
      overrides: [
        aiCharacterRepositoryProvider.overrideWithValue(
          FakeAiCharacterRepository(
            generateGate: Completer<void>(),
            generateResult: _unnamedCharacter,
          ),
        ),
      ],
    );
    _startFlow(container);
    final controller = container.read(
      characterSetupFlowControllerProvider.notifier,
    );
    for (final question in OnboardingQuestion.values) {
      controller.toggleOption(question.options.first);
    }
    return _hostRouted(
      container,
      AppRoutes.onboardingGenerating,
      const CharacterGeneratingScreen(),
    );
  },
  '이름 입력': () {
    final container = _newContainer(
      overrides: [
        aiCharacterRepositoryProvider.overrideWithValue(
          FakeAiCharacterRepository(),
        ),
      ],
    );
    _startFlow(container, character: _unnamedCharacter);
    return _hostRouted(
      container,
      AppRoutes.characterName,
      const CharacterNameScreen(),
    );
  },
  '결과(최초)': () =>
      _characterResult(CharacterSetupMode.firstTime, _longCharacterName),
  '결과(수정)': () => _characterResult(CharacterSetupMode.edit, _longCharacterName),
  '오류 화면': () => _hostPlain(
    _newContainer(),
    const ErrorScreen(
      arguments: ErrorPageArguments(
        message: '일시적인 문제가 생겼어요. 잠시 후 다시 시도해 주세요.',
        retryLocation: AppRoutes.home,
      ),
    ),
  ),
  '스플래시': () => _hostPlain(_newContainer(), const SplashScreen()),
  '수정 팝업': () {
    final container = _newContainer();
    return _hostRouted(
      container,
      AppRoutes.home,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showCharacterEditConfirmationDialog(
              context,
              characterName: _longCharacterName,
            ),
            child: const Text('팝업 열기'),
          ),
        ),
      ),
    );
  },
};

/// 각 구성에서 그려져야 하는 화면(또는 팝업).
final Map<String, _ScreenFinder> _expectedScreens = {
  '환영': () => find.byType(WelcomeScreen),
  '이메일 로그인': () => find.byType(EmailLoginScreen),
  '이메일 가입 자격 증명': () => find.byType(EmailSignupCredentialsScreen),
  '닉네임': () => find.byType(SignupNicknameScreen),
  '가입 완료': () => find.byType(SignupCompletionScreen),
  '온보딩 시작': () => find.byType(OnboardingIntroductionScreen),
  '질문(첫 질문)': () => find.byType(OnboardingQuestionScreen),
  '질문(복수 선택 마지막 질문)': () => find.byType(OnboardingQuestionScreen),
  '생성 중': () => find.byType(CharacterGeneratingScreen),
  '이름 입력': () => find.byType(CharacterNameScreen),
  '결과(최초)': () => find.byType(CharacterResultScreen),
  '결과(수정)': () => find.byType(CharacterResultScreen),
  '오류 화면': () => find.byType(ErrorScreen),
  '스플래시': () => find.byType(SplashScreen),
  '수정 팝업': () => find.byType(CharacterEditConfirmationDialog),
};

/// 팝업은 열고, 입력 화면은 최악 길이의 값을 넣어 가장 긴 내용으로 그린다.
Future<void> _fillWorstCaseContent(WidgetTester tester, String name) async {
  final opener = find.text('팝업 열기');
  if (opener.evaluate().isNotEmpty) {
    await tester.tap(opener);
    await tester.pumpAndSettle();
  }
  if (name == '이름 입력') {
    await tester.enterText(find.byType(TextField), _longCharacterName);
    await tester.pumpAndSettle();
  }
  if (name == '닉네임') {
    await tester.enterText(find.byType(TextField), _longNickname);
    await tester.pumpAndSettle();
  }
}

void main() {
  group('모든 뷰포트에서 예외 없이 그려진다', () {
    for (final entry in _screens.entries) {
      for (final viewport in viewportCases) {
        testWidgets('${entry.key} ${viewport.label}', (tester) async {
          await pumpAtViewport(tester, viewport, entry.value());
          await _fillWorstCaseContent(tester, entry.key);

          expect(_expectedScreens[entry.key]!(), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('터치 영역 측정(기준 미달은 기록만 하고 실패시키지 않는다)', () {
    const baseViewport = ViewportCase(width: 393, height: 852, textScale: 1.0);
    final guidelines = {
      'Android 48dp': androidTapTargetGuideline,
      'iOS 44pt': iOSTapTargetGuideline,
    };
    for (final entry in _screens.entries) {
      testWidgets(entry.key, (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpAtViewport(tester, baseViewport, entry.value());
        await _fillWorstCaseContent(tester, entry.key);
        expect(_expectedScreens[entry.key]!(), findsOneWidget);

        for (final guideline in guidelines.entries) {
          final evaluation = await guideline.value.evaluate(tester);
          if (!evaluation.passed) {
            debugPrint(
              'TAP_TARGET ${entry.key} ${guideline.key}: ${evaluation.reason}',
            );
          }
        }
        semantics.dispose();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
