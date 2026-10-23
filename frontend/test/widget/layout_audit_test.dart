import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
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
import 'package:teeq/features/auth/domain/profile_image_file.dart';
import 'package:teeq/features/auth/domain/signup_draft.dart';
import 'package:teeq/features/auth/presentation/auth_flow_provider.dart';
import 'package:teeq/features/auth/presentation/signup_completion_consent_screen.dart';
import 'package:teeq/features/auth/presentation/signup_draft_controller.dart';
import 'package:teeq/features/auth/presentation/signup_nickname_screen.dart';
import 'package:teeq/features/auth/presentation/welcome_screen.dart';
import 'package:teeq/features/error/presentation/error_screen.dart';
import 'package:teeq/features/feedback/data/feedback_repository_impl.dart';
import 'package:teeq/features/feedback/domain/awkward_moment.dart';
import 'package:teeq/features/feedback/domain/detailed_feedback_question.dart';
import 'package:teeq/features/feedback/domain/feedback_input_limits.dart';
import 'package:teeq/features/feedback/domain/feedback_status.dart';
import 'package:teeq/features/feedback/domain/previous_call_recall.dart';
import 'package:teeq/features/feedback/domain/revisit_intention.dart';
import 'package:teeq/features/feedback/domain/start_reason.dart';
import 'package:teeq/features/feedback/presentation/feedback_flow_controller.dart';
import 'package:teeq/features/feedback/presentation/feedback_flow_state.dart';
import 'package:teeq/features/feedback/presentation/screens/call_closing_screen.dart';
import 'package:teeq/features/feedback/presentation/screens/detailed_feedback_completion_screen.dart';
import 'package:teeq/features/feedback/presentation/screens/detailed_feedback_screen.dart';
import 'package:teeq/features/feedback/presentation/screens/feedback_completion_screen.dart';
import 'package:teeq/features/home/data/home_repository_impl.dart';
import 'package:teeq/features/home/domain/home_summary.dart';
import 'package:teeq/features/my_page/data/image_picker_profile_image_picker.dart';
import 'package:teeq/features/my_page/data/legal_document_loader.dart';
import 'package:teeq/features/my_page/domain/legal_document.dart';
import 'package:teeq/features/my_page/presentation/legal_document_screen.dart';
import 'package:teeq/features/my_page/presentation/nickname_change_screen.dart';
import 'package:teeq/features/my_page/presentation/profile_image_sheet.dart';
import 'package:teeq/features/onboarding/data/ai_character_repository_impl.dart';
import 'package:teeq/features/onboarding/domain/ai_character.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';
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
import 'package:teeq/features/app_update/domain/app_update_requirement.dart';
import 'package:teeq/features/app_update/data/url_store_launcher.dart';
import 'package:teeq/features/app_update/presentation/app_update_controller.dart';
import 'package:teeq/features/app_update/presentation/update_required_screen.dart';

import '../support/fake_ai_character_repository.dart';
import '../support/fake_app_update_controller.dart';
import '../support/fake_feedback_repository.dart';
import '../support/fake_home_repository.dart';
import '../support/fake_profile_image_picker.dart';
import '../support/fake_store_launcher.dart';
import '../support/viewport_cases.dart';

class _NoopAuthFlow extends Fake implements AuthFlow {
  @override
  Future<void> restore() async {}
}

/// 사진 업로드 응답이 오지 않아 "업로드 중" 상태에 머무는 인증 흐름.
class _PendingUploadAuthFlow extends _NoopAuthFlow {
  @override
  Future<void> replaceProfileImage(ProfileImageFile image) =>
      Completer<void>().future;
}

/// 실제 약관 자산 파일을 동기로 읽어 가장 긴 실제 본문으로 그리게 하는 로더.
class _FileLegalDocumentLoader extends LegalDocumentLoader {
  _FileLegalDocumentLoader() : super(rootBundle);

  @override
  Future<LegalDocument> load(LegalDocumentType type) async =>
      LegalDocument.fromJson(
        jsonDecode(
          File(LegalDocumentLoader.assetPathOf(type)).readAsStringSync(),
        ) as Map<String, dynamic>,
      );
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
  loginType: LoginType.google,
);

const _unnamedCharacter = AiCharacter(
  name: null,
  characterType: CharacterType.character3,
  personalityTags: ['다정함', '차분함', '유쾌함'],
);

AiCharacter _namedCharacter(String name) => AiCharacter(
  name: name,
  characterType: CharacterType.character3,
  personalityTags: const ['다정함', '차분함', '유쾌함'],
);

class _FixedSignupDraftController extends SignupDraftController {
  @override
  SignupDraft build() => const SignupDraft(
    isServiceTermsAgreed: true,
    isPrivacyPolicyAgreed: true,
  );
}

ProviderContainer _newContainer({
  List overrides = const [],
  AuthFlow? authFlow,
}) {
  final container = ProviderContainer(
    overrides: [
      errorHandlerProvider.overrideWithValue(_NoopErrorHandler()),
      authFlowProvider.overrideWithValue(authFlow ?? _NoopAuthFlow()),
      appUpdateControllerProvider.overrideWith(FakeAppUpdateController.new),
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

const _feedbackCallSessionId = 'call-1';

/// 두 번째 이후 통화라 기억 문항까지 모두 나오는(가장 긴) 피드백 상태.
const _laterCallFeedbackStatus = FeedbackStatus(
  callIndex: 12,
  previousCallRecallRequired: true,
  requiredFeedbackSubmitted: false,
);

/// 최악 길이의 응답을 채운 채로 시작하는 피드백 흐름 컨트롤러.
class _WorstCaseFeedbackFlowController extends FeedbackFlowController {
  _WorstCaseFeedbackFlowController({required this.isDetailedFeedbackInvited});

  /// true이면 완료 화면이 상세 피드백 초대 시트를 연다.
  final bool isDetailedFeedbackInvited;

  @override
  FeedbackFlowState build() {
    super.build();
    var detailedAnswers = const FeedbackFlowState().detailedAnswers
        .withFreeText('가' * FeedbackInputLimits.freeTextMaxLength)
        .toggleStartReason(StartReason.other)
        .withStartReasonOtherText('나' * FeedbackInputLimits.reasonMaxLength);
    for (final question in DetailedFeedbackQuestion.values) {
      detailedAnswers = detailedAnswers
          .withScore(question, 5)
          .withReason(question, '다' * FeedbackInputLimits.reasonMaxLength);
    }
    final requiredAnswers = const FeedbackFlowState().requiredAnswers
        .withRating(5)
        .withRevisitIntention(RevisitIntention.yes)
        .withPreviousCallRecall(PreviousCallRecall.remembered)
        .toggleAwkwardMoment(AwkwardMoment.cut)
        .toggleAwkwardMoment(AwkwardMoment.slow)
        .toggleAwkwardMoment(AwkwardMoment.context)
        .toggleAwkwardMoment(AwkwardMoment.repeat);
    return FeedbackFlowState(
      callSessionId: _feedbackCallSessionId,
      status: _laterCallFeedbackStatus,
      requiredAnswers: requiredAnswers,
      detailedAnswers: detailedAnswers,
      requiredSubmitted: true,
      detailedFeedbackInvited: isDetailedFeedbackInvited,
    );
  }
}

Widget _feedbackScreen(
  Widget screen, {
  required String path,
  bool isDetailedFeedbackInvited = false,
}) {
  final container = _newContainer(
    overrides: [
      feedbackRepositoryProvider.overrideWithValue(
        FakeFeedbackRepository(status: _laterCallFeedbackStatus),
      ),
      homeRepositoryProvider.overrideWithValue(
        FakeHomeRepository(
          summary: const HomeSummary(
            characterName: _longCharacterName,
            personalityTags: ['다정함', '차분함', '유쾌함'],
            greeting: '안녕',
          ),
        ),
      ),
      feedbackFlowControllerProvider.overrideWith(
        () => _WorstCaseFeedbackFlowController(
          isDetailedFeedbackInvited: isDetailedFeedbackInvited,
        ),
      ),
    ],
  );
  container.read(currentMemberControllerProvider.notifier).update(_member);
  return _hostRouted(container, path, screen);
}

/// 버튼으로 프로필 사진 시트를 여는 화면. 시트에서 고를 사진과 업로드 동작을 정한다.
Widget _profileImageSheetOpener({
  required FakeProfileImagePicker picker,
  required AuthFlow authFlow,
}) {
  final container = _newContainer(
    overrides: [profileImagePickerProvider.overrideWithValue(picker)],
    authFlow: authFlow,
  );
  return _hostPlain(
    container,
    Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => showProfileImageSheet(context),
          child: const Text('팝업 열기'),
        ),
      ),
    ),
  );
}

Widget _legalDocumentScreen(LegalDocumentType type, String path) => _hostRouted(
  _newContainer(
    overrides: [
      legalDocumentLoaderProvider.overrideWithValue(_FileLegalDocumentLoader()),
    ],
  ),
  path,
  LegalDocumentScreen(type: type),
);

final Map<String, _ScreenBuilder> _screens = {
  '환영': () => _hostPlain(_newContainer(), const WelcomeScreen()),
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
  '약관 동의': () =>
      _hostPlain(_newContainer(), const SignupCompletionConsentScreen()),
  '닉네임 변경': () {
    final container = _newContainer();
    container.read(currentMemberControllerProvider.notifier).update(_member);
    return _hostRouted(
      container,
      AppRoutes.nicknameChange,
      const NicknameChangeScreen(),
    );
  },
  '서비스 이용약관': () => _legalDocumentScreen(
    LegalDocumentType.serviceTerms,
    AppRoutes.serviceTerms,
  ),
  '개인정보 처리방침': () => _legalDocumentScreen(
    LegalDocumentType.privacyPolicy,
    AppRoutes.privacyPolicy,
  ),
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
  // 기본 컨테이너가 이미 업데이트 컨트롤러를 가짜로 덮어써서, 업데이트 필요 상태는 따로 구성한다.
  '업데이트 필요': () {
    final container = ProviderContainer(
      overrides: [
        errorHandlerProvider.overrideWithValue(_NoopErrorHandler()),
        appUpdateControllerProvider.overrideWith(
          () => FakeAppUpdateController(
            initialRequirement: const AppUpdateRequirement(
              minimumVersion: '1.3.0',
              storeUrl: 'https://store.example.test/teeq',
            ),
          ),
        ),
        storeLauncherProvider.overrideWithValue(FakeStoreLauncher()),
      ],
    );
    addTearDown(container.dispose);
    return _hostPlain(container, const UpdateRequiredScreen());
  },
  '통화 마무리': () => _feedbackScreen(
    const CallClosingScreen(callSessionId: _feedbackCallSessionId),
    path: AppRoutes.feedbackClosingLocation(_feedbackCallSessionId),
  ),
  '통화 마무리(필수 시트 열림)': () => _feedbackScreen(
    const CallClosingScreen(callSessionId: _feedbackCallSessionId),
    path: AppRoutes.feedbackClosingLocation(_feedbackCallSessionId),
  ),
  '피드백 완료': () => _feedbackScreen(
    const FeedbackCompletionScreen(callSessionId: _feedbackCallSessionId),
    path: AppRoutes.feedbackCompletionLocation(_feedbackCallSessionId),
  ),
  '피드백 완료(상세 초대 시트 열림)': () => _feedbackScreen(
    const FeedbackCompletionScreen(callSessionId: _feedbackCallSessionId),
    path: AppRoutes.feedbackCompletionLocation(_feedbackCallSessionId),
    isDetailedFeedbackInvited: true,
  ),
  '상세 피드백': () => _feedbackScreen(
    const DetailedFeedbackScreen(callSessionId: _feedbackCallSessionId),
    path: AppRoutes.detailedFeedbackLocation(_feedbackCallSessionId),
  ),
  '상세 피드백 완료': () => _feedbackScreen(
    const DetailedFeedbackCompletionScreen(
      callSessionId: _feedbackCallSessionId,
    ),
    path: AppRoutes.detailedFeedbackCompletionLocation(_feedbackCallSessionId),
  ),
  '프로필 사진 시트(기본)': () => _profileImageSheetOpener(
    picker: FakeProfileImagePicker(
      result: FakeProfileImagePicker.imageOf(fileName: 'photo.gif'),
    ),
    authFlow: _NoopAuthFlow(),
  ),
  '프로필 사진 시트(업로드 중)': () => _profileImageSheetOpener(
    picker: FakeProfileImagePicker(result: FakeProfileImagePicker.imageOf()),
    authFlow: _PendingUploadAuthFlow(),
  ),
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
  '닉네임': () => find.byType(SignupNicknameScreen),
  '약관 동의': () => find.byType(SignupCompletionConsentScreen),
  '닉네임 변경': () => find.byType(NicknameChangeScreen),
  '서비스 이용약관': () => find.byType(LegalDocumentScreen),
  '개인정보 처리방침': () => find.byType(LegalDocumentScreen),
  '온보딩 시작': () => find.byType(OnboardingIntroductionScreen),
  '질문(첫 질문)': () => find.byType(OnboardingQuestionScreen),
  '질문(복수 선택 마지막 질문)': () => find.byType(OnboardingQuestionScreen),
  '생성 중': () => find.byType(CharacterGeneratingScreen),
  '이름 입력': () => find.byType(CharacterNameScreen),
  '결과(최초)': () => find.byType(CharacterResultScreen),
  '결과(수정)': () => find.byType(CharacterResultScreen),
  '오류 화면': () => find.byType(ErrorScreen),
  '스플래시': () => find.byType(SplashScreen),
  '업데이트 필요': () => find.byType(UpdateRequiredScreen),
  '수정 팝업': () => find.byType(CharacterEditConfirmationDialog),
  '프로필 사진 시트(기본)': () => find.text('프로필 사진 변경'),
  '프로필 사진 시트(업로드 중)': () => find.text('프로필 사진 변경'),
  '통화 마무리': () => find.byType(CallClosingScreen),
  '통화 마무리(필수 시트 열림)': () => find.text('오늘 통화는 어땠어?'),
  '피드백 완료': () => find.byType(FeedbackCompletionScreen),
  '피드백 완료(상세 초대 시트 열림)': () => find.text('자세히 알려주기'),
  '상세 피드백': () => find.byType(DetailedFeedbackScreen),
  '상세 피드백 완료': () => find.byType(DetailedFeedbackCompletionScreen),
};

/// 팝업은 열고, 입력 화면은 최악 길이의 값을 넣어 가장 긴 내용으로 그린다.
Future<void> _fillWorstCaseContent(WidgetTester tester, String name) async {
  final opener = find.text('팝업 열기');
  if (opener.evaluate().isNotEmpty) {
    await tester.tap(opener);
    await tester.pumpAndSettle();
  }
  // 형식 오류 문구가 보이는 상태와 업로드 중 상태로 만든다. 스피너가 계속 돌아 settle하지 않는다.
  if (name.startsWith('프로필 사진 시트')) {
    await tester.tap(find.text('사진 선택하기'));
    await tester.pump();
    await tester.pump();
  }
  if (name == '통화 마무리(필수 시트 열림)') {
    await tester.tap(find.text('의견 남기기'));
    await tester.pumpAndSettle();
  }
  if (name == '이름 입력') {
    await tester.enterText(find.byType(TextField), _longCharacterName);
    await tester.pumpAndSettle();
  }
  // 오류 문구와 카운터가 모두 나오는 최악 내용으로 그린다.
  if (name == '닉네임 변경') {
    await tester.enterText(find.byType(TextField), '가 나다라마바사아자차카');
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
