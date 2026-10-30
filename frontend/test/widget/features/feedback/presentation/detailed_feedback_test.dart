import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/auth/auth_status_controller.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/button/app_back_button.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/core/ui/progress/button_loading_indicator.dart';
import 'package:teeq/features/feedback/data/feedback_repository_impl.dart';
import 'package:teeq/features/feedback/domain/awkward_moment.dart';
import 'package:teeq/features/feedback/domain/detailed_feedback_question.dart';
import 'package:teeq/features/feedback/domain/detailed_feedback_submission.dart';
import 'package:teeq/features/feedback/domain/feedback_status.dart';
import 'package:teeq/features/feedback/domain/previous_call_recall.dart';
import 'package:teeq/features/feedback/domain/revisit_intention.dart';
import 'package:teeq/features/feedback/domain/start_reason.dart';
import 'package:teeq/features/feedback/presentation/feedback_flow_controller.dart';
import 'package:teeq/features/feedback/presentation/feedback_flow_state.dart';
import 'package:teeq/features/feedback/presentation/screens/detailed_feedback_completion_screen.dart';
import 'package:teeq/features/feedback/presentation/screens/detailed_feedback_screen.dart';
import 'package:teeq/features/feedback/presentation/widgets/feedback_choice_chip.dart';
import 'package:teeq/features/home/data/home_repository_impl.dart';
import 'package:teeq/features/home/domain/character_mood.dart';
import 'package:teeq/features/home/domain/home_summary.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';

import '../../../../support/fake_feedback_repository.dart';
import '../../../../support/fake_home_repository.dart';
import '../../../../support/viewport_cases.dart';

class _RecordingErrorHandler extends Fake implements ErrorHandler {
  final List<Object> handledErrors = [];

  @override
  void handle(Object error, {bool blocking = false}) {
    handledErrors.add(error);
  }
}

/// 상세 제출 요청만 게이트가 열릴 때까지 지연시키는 저장소.
class _DetailedGatedFeedbackRepository extends FakeFeedbackRepository {
  _DetailedGatedFeedbackRepository(this._submitGate)
    : super(status: _laterCallStatus, detailedFeedbackInvited: true);

  final Completer<void> _submitGate;

  @override
  Future<void> submitDetailed(
    String callSessionId,
    DetailedFeedbackSubmission submission,
  ) async {
    final result = super.submitDetailed(callSessionId, submission);
    await _submitGate.future;
    return result;
  }
}

const _member = Member(
  memberId: 'member-1',
  nickname: '소연',
  hasAiCharacter: true,
  loginType: LoginType.google,
);

const _summary = HomeSummary(
  characterName: '티티',
  characterType: CharacterType.character1,
  characterMood: CharacterMood.welcome,
  personalityTags: ['다정함', '차분함', '유쾌함'],
  greeting: '안녕',
);

const _callSessionId = 'call-1';
const _homePageText = 'HOME-PAGE';
const _memoryRowText = '기억할 만한 내용이 없어서 평가하기 어려워.';

const _laterCallStatus = FeedbackStatus(
  callIndex: 3,
  previousCallRecallRequired: true,
  requiredFeedbackSubmitted: false,
);

typedef _Harness = ({
  ProviderContainer container,
  GoRouter router,
  FakeFeedbackRepository repository,
  _RecordingErrorHandler errorHandler,
});

FakeFeedbackRepository _invitedRepository({Object? submitDetailedError}) =>
    FakeFeedbackRepository(
      status: _laterCallStatus,
      detailedFeedbackInvited: true,
      submitDetailedError: submitDetailedError,
    );

Future<_Harness> _buildHarness(FakeFeedbackRepository repository) async {
  final errorHandler = _RecordingErrorHandler();
  final container = ProviderContainer(
    retry: (retryCount, error) => null,
    overrides: [
      feedbackRepositoryProvider.overrideWithValue(repository),
      homeRepositoryProvider.overrideWithValue(
        FakeHomeRepository(summary: _summary),
      ),
      errorHandlerProvider.overrideWithValue(errorHandler),
    ],
  );
  addTearDown(container.dispose);
  container.read(authStatusControllerProvider.notifier).markSignedIn();
  container.read(currentMemberControllerProvider.notifier).update(_member);
  // 필수 피드백을 제출해 상세 피드백에 초대받은 상태까지 흐름을 진행한다.
  final controller = container.read(feedbackFlowControllerProvider.notifier)
    ..start(_callSessionId);
  await controller.loadStatus();
  controller
    ..setRating(4)
    ..setRevisitIntention(RevisitIntention.yes)
    ..setPreviousCallRecall(PreviousCallRecall.remembered)
    ..toggleAwkwardMoment(AwkwardMoment.none);
  await controller.submitRequired();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const Scaffold(body: Text(_homePageText)),
      ),
      GoRoute(
        path: AppRoutes.detailedFeedback,
        builder: (context, state) => DetailedFeedbackScreen(
          callSessionId: state.pathParameters['callSessionId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.detailedFeedbackCompletion,
        builder: (context, state) => DetailedFeedbackCompletionScreen(
          callSessionId: state.pathParameters['callSessionId']!,
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  return (
    container: container,
    router: router,
    repository: repository,
    errorHandler: errorHandler,
  );
}

Widget _app(_Harness harness) => UncontrolledProviderScope(
  container: harness.container,
  child: MaterialApp.router(
    theme: AppTheme.light,
    routerConfig: harness.router,
  ),
);

/// 홈 위에 [location]을 쌓아 시스템 뒤로가기가 실제로 이전 화면으로 돌아가는지 확인할 수 있게 한다.
Future<_Harness> _pumpDetailed(
  WidgetTester tester,
  FakeFeedbackRepository repository, {
  ViewportCase? viewport,
  String? location,
}) async {
  final harness = await _buildHarness(repository);
  if (viewport == null) {
    await tester.pumpWidget(_app(harness));
    await tester.pumpAndSettle();
  } else {
    await pumpAtViewport(tester, viewport, _app(harness));
  }
  unawaited(
    harness.router.push<void>(
      location ?? AppRoutes.detailedFeedbackLocation(_callSessionId),
    ),
  );
  await tester.pumpAndSettle();
  return harness;
}

FeedbackFlowController _controller(_Harness harness) =>
    harness.container.read(feedbackFlowControllerProvider.notifier);

FeedbackFlowState _flowState(_Harness harness) =>
    harness.container.read(feedbackFlowControllerProvider);

/// 필수 문항을 모두 채운다.
void _answerAllRequired(_Harness harness) {
  final controller = _controller(harness);
  for (final question in DetailedFeedbackQuestion.values) {
    controller.setDetailedScore(question, 4);
  }
  controller.toggleStartReason(StartReason.needToTalk);
}

PrimaryFilledButton _submitButton(WidgetTester tester) =>
    tester.widget<PrimaryFilledButton>(
      find.widgetWithText(PrimaryFilledButton, '의견 보내기'),
    );

Future<void> _scrollToAndTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

/// 화면 순서대로 5점 칩이 5개씩 있으므로 [sectionIndex]번째 점수 문항의 칩 5개를 돌려준다.
List<FeedbackChoiceChip> _chipsOfSection(
  WidgetTester tester,
  int sectionIndex,
) {
  final chips = tester
      .widgetList<FeedbackChoiceChip>(find.byType(FeedbackChoiceChip))
      .toList();
  return chips.sublist(sectionIndex * 5, sectionIndex * 5 + 5);
}

TextField _textFieldAt(WidgetTester tester, int index) =>
    tester.widget<TextField>(find.byType(TextField).at(index));

void main() {
  group('detailed feedback screen', () {
    testWidgets('detailedScreen_showsHeaderAndEightQuestions', (tester) async {
      await _pumpDetailed(tester, _invitedRepository());

      expect(find.text('티티와의 대화,\n조금 더 알려줄래?'), findsOneWidget);
      expect(find.text('기억나는 부분만 편하게 알려줘!'), findsOneWidget);
      expect(find.textContaining('1. 티티와 말 주고받는'), findsOneWidget);
      expect(find.textContaining('3. 티티가 우리 대화를'), findsOneWidget);
      expect(find.textContaining('8. 오늘 통화를 시작한 이유'), findsOneWidget);
      expect(find.text('티티가 궁금해서'), findsOneWidget);
    });

    testWidgets('detailedScreen_helperTextSitsBelowQuestionTitle', (
      tester,
    ) async {
      await _pumpDetailed(tester, _invitedRepository());

      final helperByTitle = {
        '5. 가장 좋았거나 아쉬웠던 순간이 있었어?': '선택',
        '8. 오늘 통화를 시작한 이유는 뭐야?': '해당하는 이유를 모두 골라줘.',
      };
      for (final entry in helperByTitle.entries) {
        final title = find.text(entry.key);
        final helper = find.text(entry.value);
        expect(title, findsOneWidget);
        expect(helper, findsOneWidget);
        expect(
          tester.getTopLeft(helper).dy,
          greaterThan(tester.getBottomLeft(title).dy),
        );
        expect(tester.getTopLeft(helper).dx, tester.getTopLeft(title).dx);
      }
    });

    testWidgets('detailedScreen_backButtonGoesHomeWithoutConfirmation', (
      tester,
    ) async {
      final harness = await _pumpDetailed(tester, _invitedRepository());
      _answerAllRequired(harness);
      await tester.pump();

      await tester.tap(find.byType(AppBackButton));
      await tester.pumpAndSettle();

      expect(find.text(_homePageText), findsOneWidget);
      expect(find.byType(DetailedFeedbackScreen), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
      expect(_flowState(harness), FeedbackFlowState.initial);
    });

    testWidgets('detailedScreen_systemBackGoesHomeAndDiscardsAnswers', (
      tester,
    ) async {
      final harness = await _pumpDetailed(tester, _invitedRepository());
      _answerAllRequired(harness);
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text(_homePageText), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(_flowState(harness), FeedbackFlowState.initial);
    });

    testWidgets('detailedScreen_submitDisabledUntilRequiredAnswered', (
      tester,
    ) async {
      final harness = await _pumpDetailed(tester, _invitedRepository());
      expect(_submitButton(tester).onPressed, isNull);

      final controller = _controller(harness);
      for (final question in DetailedFeedbackQuestion.values) {
        controller.setDetailedScore(question, 3);
      }
      await tester.pump();
      // 시작 이유가 하나도 없으면 아직 보낼 수 없다.
      expect(_submitButton(tester).onPressed, isNull);

      controller.toggleStartReason(StartReason.needToTalk);
      await tester.pump();
      expect(_submitButton(tester).onPressed, isNotNull);
    });

    testWidgets('detailedScreen_memoryCheckDisablesMemoryChipsAndReason', (
      tester,
    ) async {
      final harness = await _pumpDetailed(tester, _invitedRepository());
      _controller(harness).setDetailedScore(DetailedFeedbackQuestion.memory, 4);
      await tester.pump();
      expect(
        _chipsOfSection(tester, 2).every((chip) => chip.isEnabled),
        isTrue,
      );
      expect(_textFieldAt(tester, 2).enabled, isTrue);

      await _scrollToAndTap(tester, find.text(_memoryRowText));

      expect(_flowState(harness).detailedAnswers.memoryNotApplicable, isTrue);
      expect(
        _flowState(harness).detailedAnswers.scores,
        isNot(contains(DetailedFeedbackQuestion.memory)),
      );
      expect(_chipsOfSection(tester, 2).any((chip) => chip.isEnabled), isFalse);
      expect(_textFieldAt(tester, 2).enabled, isFalse);

      await _scrollToAndTap(tester, find.text(_memoryRowText));

      expect(_flowState(harness).detailedAnswers.memoryNotApplicable, isFalse);
      expect(
        _chipsOfSection(tester, 2).every((chip) => chip.isEnabled),
        isTrue,
      );
      expect(_textFieldAt(tester, 2).enabled, isTrue);
      // 풀면 기억 점수를 다시 골라야 보낼 수 있다.
      expect(_flowState(harness).detailedAnswers.isComplete, isFalse);
    });

    testWidgets('detailedScreen_otherInputDisabledUntilOtherChecked', (
      tester,
    ) async {
      final harness = await _pumpDetailed(tester, _invitedRepository());
      const otherInputIndex = 7;
      expect(_textFieldAt(tester, otherInputIndex).enabled, isFalse);

      await _scrollToAndTap(tester, find.text('기타'));
      expect(_textFieldAt(tester, otherInputIndex).enabled, isTrue);

      await tester.enterText(
        find.byType(TextField).at(otherInputIndex),
        '그냥 궁금했어',
      );
      await tester.pump();
      expect(
        _flowState(harness).detailedAnswers.startReasonOtherText,
        '그냥 궁금했어',
      );

      await _scrollToAndTap(tester, find.text('기타'));
      expect(_textFieldAt(tester, otherInputIndex).enabled, isFalse);
      expect(_flowState(harness).detailedAnswers.startReasonOtherText, isEmpty);
    });

    testWidgets('detailedScreen_doubleTapSubmitSendsOnce', (tester) async {
      final gate = Completer<void>();
      final repository = _DetailedGatedFeedbackRepository(gate);
      final harness = await _pumpDetailed(tester, repository);
      _answerAllRequired(harness);
      await tester.pump();

      await tester.tap(find.text('의견 보내기'));
      await tester.pump();
      expect(find.byType(ButtonLoadingIndicator), findsOneWidget);
      await tester.tap(find.byType(PrimaryFilledButton));
      await tester.pump();

      expect(repository.submitDetailedCalls, hasLength(1));

      gate.complete();
      await tester.pumpAndSettle();
      expect(repository.submitDetailedCalls, hasLength(1));
    });

    testWidgets('detailedScreen_submitSendsMappedRequest', (tester) async {
      final repository = _invitedRepository();
      final harness = await _pumpDetailed(tester, repository);
      final controller = _controller(harness);
      for (final question in DetailedFeedbackQuestion.values) {
        controller.setDetailedScore(question, 2);
      }
      controller
        ..setDetailedScore(DetailedFeedbackQuestion.timing, 5)
        ..setDetailedReason(DetailedFeedbackQuestion.timing, '잘 들어줬어')
        ..setFreeText('다음에도 좋았으면 해')
        ..toggleStartReason(StartReason.wantToConfide)
        ..toggleStartReason(StartReason.other)
        ..setStartReasonOtherText('그냥');
      await tester.pump();

      await tester.tap(find.text('의견 보내기'));
      await tester.pumpAndSettle();

      expect(repository.submitDetailedCalls, hasLength(1));
      final submission = repository.submitDetailedCalls.single;
      expect(submission.scores[DetailedFeedbackQuestion.timing], 5);
      expect(submission.scores[DetailedFeedbackQuestion.storageComfort], 2);
      expect(submission.reasons, {DetailedFeedbackQuestion.timing: '잘 들어줬어'});
      expect(submission.memoryNotApplicable, isFalse);
      expect(submission.freeText, '다음에도 좋았으면 해');
      expect(submission.startReasons, [
        StartReason.wantToConfide,
        StartReason.other,
      ]);
      expect(submission.startReasonOtherText, '그냥');
    });

    testWidgets('detailedScreen_submitFailureKeepsAnswers', (tester) async {
      final repository = _invitedRepository(
        submitDetailedError: Exception('submit failed'),
      );
      final harness = await _pumpDetailed(tester, repository);
      _answerAllRequired(harness);
      await tester.pump();
      final answersBefore = _flowState(harness).detailedAnswers;

      await tester.tap(find.text('의견 보내기'));
      await tester.pumpAndSettle();

      expect(harness.errorHandler.handledErrors, hasLength(1));
      expect(find.byType(DetailedFeedbackScreen), findsOneWidget);
      expect(_flowState(harness).detailedAnswers, answersBefore);
      expect(_submitButton(tester).onPressed, isNotNull);
    });

    testWidgets('detailedScreen_alreadySubmittedGoesHomeAndResets', (
      tester,
    ) async {
      final repository = _invitedRepository(
        submitDetailedError: apiFailure(ErrorCode.feedbackAlreadySubmitted),
      );
      final harness = await _pumpDetailed(tester, repository);
      _answerAllRequired(harness);
      await tester.pump();

      await tester.tap(find.text('의견 보내기'));
      await tester.pumpAndSettle();

      expect(find.text(_homePageText), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(_flowState(harness), FeedbackFlowState.initial);
    });

    testWidgets('detailedScreen_successGoesToCompletion', (tester) async {
      final harness = await _pumpDetailed(tester, _invitedRepository());
      _answerAllRequired(harness);
      await tester.pump();

      await tester.tap(find.text('의견 보내기'));
      await tester.pumpAndSettle();

      expect(find.byType(DetailedFeedbackCompletionScreen), findsOneWidget);
      expect(find.byType(DetailedFeedbackScreen), findsNothing);
      expect(_flowState(harness).detailedSubmitted, isTrue);
    });
  });

  group('detailed feedback completion screen', () {
    Future<_Harness> pumpCompletion(WidgetTester tester) async {
      final harness = await _buildHarness(_invitedRepository());
      _answerAllRequired(harness);
      await _controller(harness).submitDetailed();
      await tester.pumpWidget(_app(harness));
      await tester.pumpAndSettle();
      unawaited(
        harness.router.push<void>(
          AppRoutes.detailedFeedbackCompletionLocation(_callSessionId),
        ),
      );
      await tester.pumpAndSettle();
      return harness;
    }

    testWidgets('detailedCompletion_blocksSystemBackAndGoesHome', (
      tester,
    ) async {
      final harness = await pumpCompletion(tester);

      expect(find.byType(AppBackButton), findsNothing);
      expect(find.text('피드백을\n보내줬어!'), findsOneWidget);
      expect(find.text('소중한 의견 덕분에\n티티가 조금 더 성장할 수 있을 거야.'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(DetailedFeedbackCompletionScreen), findsOneWidget);

      await tester.tap(find.text('홈으로 가기'));
      await tester.pumpAndSettle();

      expect(find.text(_homePageText), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(_flowState(harness), FeedbackFlowState.initial);
    });
  });

  group('narrow width with enlarged text', () {
    const viewport = ViewportCase(width: 320, height: 568, textScale: 1.2);

    testWidgets('detailedScreen_rendersAllQuestionsWithoutOverflow', (
      tester,
    ) async {
      final harness = await _pumpDetailed(
        tester,
        _invitedRepository(),
        viewport: viewport,
      );
      expect(tester.takeException(), isNull);

      _controller(harness).setMemoryNotApplicable(true);
      await tester.pump();
      await _scrollToAndTap(tester, find.text('기타'));
      await tester.ensureVisible(find.textContaining('8. 오늘 통화를 시작한 이유는 뭐야?'));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('detailedCompletion_rendersWithoutOverflow', (tester) async {
      final harness = await _buildHarness(_invitedRepository());
      _answerAllRequired(harness);
      await _controller(harness).submitDetailed();
      await pumpAtViewport(tester, viewport, _app(harness));
      unawaited(
        harness.router.push<void>(
          AppRoutes.detailedFeedbackCompletionLocation(_callSessionId),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
