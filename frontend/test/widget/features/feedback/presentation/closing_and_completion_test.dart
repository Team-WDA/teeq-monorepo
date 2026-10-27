import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/auth/auth_status_controller.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/bottom_sheet/app_bottom_sheet.dart';
import 'package:teeq/core/ui/button/app_back_button.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/core/ui/progress/button_loading_indicator.dart';
import 'package:teeq/features/feedback/data/feedback_repository_impl.dart';
import 'package:teeq/features/feedback/domain/awkward_moment.dart';
import 'package:teeq/features/feedback/domain/feedback_status.dart';
import 'package:teeq/features/feedback/domain/previous_call_recall.dart';
import 'package:teeq/features/feedback/domain/required_feedback_submission.dart';
import 'package:teeq/features/feedback/domain/revisit_intention.dart';
import 'package:teeq/features/feedback/presentation/feedback_flow_controller.dart';
import 'package:teeq/features/feedback/presentation/feedback_flow_state.dart';
import 'package:teeq/features/feedback/presentation/screens/call_closing_screen.dart';
import 'package:teeq/features/feedback/presentation/screens/feedback_completion_screen.dart';
import 'package:teeq/features/feedback/presentation/widgets/feedback_star_rating.dart';
import 'package:teeq/features/home/data/home_repository_impl.dart';
import 'package:teeq/features/home/domain/home_summary.dart';
import 'package:teeq/features/home/presentation/home_summary_provider.dart';

import '../../../../support/fake_feedback_repository.dart';
import '../../../../support/fake_home_repository.dart';
import '../../../../support/viewport_cases.dart';

class _RecordingErrorHandler extends Fake implements ErrorHandler {
  final List<Object> handledErrors = [];
  final List<bool> blockingFlags = [];

  @override
  void handle(Object error, {bool blocking = false}) {
    handledErrors.add(error);
    blockingFlags.add(blocking);
  }
}

/// 첫 상태 조회만 실패하고 이후에는 성공하는 저장소.
class _FailsOnceFeedbackRepository extends FakeFeedbackRepository {
  _FailsOnceFeedbackRepository(FeedbackStatus status) : super(status: status);

  @override
  Future<FeedbackStatus> fetchStatus(String callSessionId) {
    if (fetchStatusCount == 0) {
      fetchStatusCount += 1;
      return Future.error(Exception('status failed'));
    }
    return super.fetchStatus(callSessionId);
  }
}

/// 제출 요청만 게이트가 열릴 때까지 지연시키는 저장소.
class _SubmitGatedFeedbackRepository extends FakeFeedbackRepository {
  _SubmitGatedFeedbackRepository(FeedbackStatus status, this._submitGate)
    : super(status: status);

  final Completer<void> _submitGate;

  @override
  Future<bool> submitRequired(
    String callSessionId,
    RequiredFeedbackSubmission submission,
  ) async {
    final result = super.submitRequired(callSessionId, submission);
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
  personalityTags: ['다정함', '차분함', '유쾌함'],
  greeting: '안녕',
);

const _callSessionId = 'call-1';
const _homePageText = 'HOME-PAGE';
const _detailedPageText = 'DETAILED-PAGE';

const _firstCallStatus = FeedbackStatus(
  callIndex: 1,
  previousCallRecallRequired: false,
  requiredFeedbackSubmitted: false,
);

const _laterCallStatus = FeedbackStatus(
  callIndex: 3,
  previousCallRecallRequired: true,
  requiredFeedbackSubmitted: false,
);

const _submittedStatus = FeedbackStatus(
  callIndex: 3,
  previousCallRecallRequired: true,
  requiredFeedbackSubmitted: true,
);

typedef _Harness = ({
  ProviderContainer container,
  GoRouter router,
  _RecordingErrorHandler errorHandler,
});

_Harness _buildHarness(
  FakeFeedbackRepository feedbackRepository, {
  FakeHomeRepository? homeRepository,
}) {
  final errorHandler = _RecordingErrorHandler();
  final container = ProviderContainer(
    // 실패 응답이 재시도되지 않도록 한다.
    retry: (retryCount, error) => null,
    overrides: [
      feedbackRepositoryProvider.overrideWithValue(feedbackRepository),
      homeRepositoryProvider.overrideWithValue(
        homeRepository ?? FakeHomeRepository(summary: _summary),
      ),
      errorHandlerProvider.overrideWithValue(errorHandler),
    ],
  );
  addTearDown(container.dispose);
  container.read(authStatusControllerProvider.notifier).markSignedIn();
  container.read(currentMemberControllerProvider.notifier).update(_member);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const Scaffold(body: Text(_homePageText)),
      ),
      GoRoute(
        path: AppRoutes.feedbackClosing,
        builder: (context, state) => CallClosingScreen(
          callSessionId: state.pathParameters['callSessionId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.feedbackCompletion,
        builder: (context, state) => FeedbackCompletionScreen(
          callSessionId: state.pathParameters['callSessionId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.detailedFeedback,
        builder: (context, state) =>
            const Scaffold(body: Text(_detailedPageText)),
      ),
    ],
  );
  addTearDown(router.dispose);
  return (container: container, router: router, errorHandler: errorHandler);
}

Widget _app(_Harness harness) => UncontrolledProviderScope(
  container: harness.container,
  child: MaterialApp.router(
    theme: AppTheme.light,
    routerConfig: harness.router,
  ),
);

/// 홈 위에 [location]을 쌓아 시스템 뒤로가기가 실제로 이전 화면으로 돌아가는지 확인할 수 있게 한다.
Future<void> _pushLocation(
  WidgetTester tester,
  _Harness harness,
  String location,
) async {
  unawaited(harness.router.push<void>(location));
  await tester.pumpAndSettle();
}

Future<_Harness> _pumpClosing(
  WidgetTester tester,
  FakeFeedbackRepository feedbackRepository, {
  FakeHomeRepository? homeRepository,
  ViewportCase? viewport,
}) async {
  final harness = _buildHarness(
    feedbackRepository,
    homeRepository: homeRepository,
  );
  if (viewport == null) {
    await tester.pumpWidget(_app(harness));
    await tester.pumpAndSettle();
  } else {
    await pumpAtViewport(tester, viewport, _app(harness));
  }
  await _pushLocation(
    tester,
    harness,
    AppRoutes.feedbackClosingLocation(_callSessionId),
  );
  return harness;
}

/// 필수 피드백을 제출한 상태까지 흐름을 진행해 완료 화면에 들어갈 수 있게 한다.
Future<_Harness> _pumpCompletion(
  WidgetTester tester,
  FakeFeedbackRepository feedbackRepository, {
  required bool previousCallRecallRequired,
  ViewportCase? viewport,
}) async {
  final harness = _buildHarness(feedbackRepository);
  final controller = harness.container.read(
    feedbackFlowControllerProvider.notifier,
  );
  controller.start(_callSessionId);
  await controller.loadStatus();
  controller.setRating(4);
  controller.setRevisitIntention(RevisitIntention.yes);
  if (previousCallRecallRequired) {
    controller.setPreviousCallRecall(PreviousCallRecall.remembered);
  }
  controller.toggleAwkwardMoment(AwkwardMoment.none);
  await controller.submitRequired();
  if (viewport == null) {
    await tester.pumpWidget(_app(harness));
    await tester.pumpAndSettle();
  } else {
    await pumpAtViewport(tester, viewport, _app(harness));
  }
  await _pushLocation(
    tester,
    harness,
    AppRoutes.feedbackCompletionLocation(_callSessionId),
  );
  return harness;
}

Future<void> _tapOpinionButton(WidgetTester tester) async {
  await tester.tap(find.text('의견 남기기'));
  await tester.pumpAndSettle();
}

/// 시트가 스크롤되는 높이에서도 눌릴 수 있게 대상이 보이도록 스크롤한 뒤 탭한다.
Future<void> _scrollToAndTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

/// 필수 시트의 모든 문항에 답한다. [previousCallRecallRequired]이면 기억 문항도 고른다.
Future<void> _answerRequiredSheet(
  WidgetTester tester, {
  required bool previousCallRecallRequired,
}) async {
  final stars = find.descendant(
    of: find.byType(FeedbackStarRating),
    matching: find.byType(GestureDetector),
  );
  await _scrollToAndTap(tester, stars.at(3));
  await _scrollToAndTap(tester, find.text('응, 또 할래'));
  if (previousCallRecallRequired) {
    await _scrollToAndTap(tester, find.text('기억했어'));
  }
  await _scrollToAndTap(tester, find.text('없었어'));
}

PrimaryFilledButton _submitButton(WidgetTester tester) =>
    tester.widget<PrimaryFilledButton>(
      find.widgetWithText(PrimaryFilledButton, '의견 보내기'),
    );

void main() {
  group('closing screen', () {
    testWidgets('closingScreen_hasNoBackButtonAndBlocksSystemBack', (
      tester,
    ) async {
      await _pumpClosing(
        tester,
        FakeFeedbackRepository(status: _firstCallStatus),
      );

      expect(find.byType(AppBackButton), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(CallClosingScreen), findsOneWidget);
      expect(find.text(_homePageText), findsNothing);
    });

    testWidgets('closingScreen_showsCharacterNameInDescription', (
      tester,
    ) async {
      await _pumpClosing(
        tester,
        FakeFeedbackRepository(status: _firstCallStatus),
      );

      expect(find.text('이야기해서 좋았어!'), findsOneWidget);
      expect(find.textContaining('티티랑 통화한 거 어땠어?'), findsOneWidget);
    });

    testWidgets('closingScreen_tapOpensRequiredSheetAfterStatusLoaded', (
      tester,
    ) async {
      final repository = FakeFeedbackRepository(status: _firstCallStatus);
      await _pumpClosing(tester, repository);
      expect(find.text('오늘 통화는 어땠어?'), findsNothing);

      await _tapOpinionButton(tester);

      expect(repository.fetchStatusCount, 1);
      expect(find.text('오늘 통화는 어땠어?'), findsOneWidget);
    });

    testWidgets('closingScreen_statusFailureKeepsScreenAndButtonRetries', (
      tester,
    ) async {
      final repository = _FailsOnceFeedbackRepository(_firstCallStatus);
      final harness = await _pumpClosing(tester, repository);

      await _tapOpinionButton(tester);

      expect(find.text('오늘 통화는 어땠어?'), findsNothing);
      expect(find.byType(CallClosingScreen), findsOneWidget);
      expect(harness.errorHandler.handledErrors, hasLength(1));

      await _tapOpinionButton(tester);

      expect(repository.fetchStatusCount, 2);
      expect(find.text('오늘 통화는 어땠어?'), findsOneWidget);
    });

    testWidgets('closingScreen_doubleTapCallsStatusOnce', (tester) async {
      final gate = Completer<void>();
      final repository = FakeFeedbackRepository(
        status: _firstCallStatus,
        gate: gate,
      );
      await _pumpClosing(tester, repository);

      await tester.tap(find.text('의견 남기기'));
      await tester.pump();
      expect(find.byType(ButtonLoadingIndicator), findsOneWidget);
      await tester.tap(find.byType(PrimaryFilledButton));
      await tester.pump();

      expect(repository.fetchStatusCount, 1);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('오늘 통화는 어땠어?'), findsOneWidget);
    });

    testWidgets('closingScreen_alreadySubmittedGoesHome', (tester) async {
      await _pumpClosing(
        tester,
        FakeFeedbackRepository(status: _submittedStatus),
      );

      await _tapOpinionButton(tester);

      expect(find.text('오늘 통화는 어땠어?'), findsNothing);
      expect(find.text(_homePageText), findsOneWidget);
    });

    testWidgets('closingScreen_callSessionNotFoundGoesHome', (tester) async {
      final harness = await _pumpClosing(
        tester,
        FakeFeedbackRepository(
          status: _firstCallStatus,
          statusError: apiFailure(
            ErrorCode.callSessionNotFound,
            httpStatus: 404,
          ),
        ),
      );

      await _tapOpinionButton(tester);

      expect(find.text(_homePageText), findsOneWidget);
      expect(find.byType(CallClosingScreen), findsNothing);
      expect(harness.errorHandler.handledErrors, hasLength(1));
    });

    testWidgets('closingScreen_callNotFeedbackableStaysAndRetries', (
      tester,
    ) async {
      final harness = await _pumpClosing(
        tester,
        FakeFeedbackRepository(
          status: _firstCallStatus,
          statusError: apiFailure(ErrorCode.callNotFeedbackable),
        ),
      );

      await _tapOpinionButton(tester);

      expect(find.byType(CallClosingScreen), findsOneWidget);
      expect(find.text(_homePageText), findsNothing);
      expect(harness.errorHandler.handledErrors, hasLength(1));
      final button = tester.widget<PrimaryFilledButton>(
        find.widgetWithText(PrimaryFilledButton, '의견 남기기'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('closingScreen_homeRefetchErrorWithCachedValueIsNonBlocking', (
      tester,
    ) async {
      final failure = Exception('refetch failed');
      final harness = await _pumpClosing(
        tester,
        FakeFeedbackRepository(status: _firstCallStatus),
        homeRepository: FakeHomeRepository(
          summary: _summary,
          errorAfterFirstFetch: failure,
        ),
      );
      expect(harness.errorHandler.handledErrors, isEmpty);

      harness.container.invalidate(homeSummaryProvider(_member.memberId));
      await tester.pumpAndSettle();

      expect(find.byType(CallClosingScreen), findsOneWidget);
      expect(harness.errorHandler.handledErrors, [failure]);
      expect(harness.errorHandler.blockingFlags, [false]);
    });

    testWidgets('closingScreen_homeFirstLoadErrorIsBlocking', (tester) async {
      final failure = Exception('load failed');
      final harness = await _pumpClosing(
        tester,
        FakeFeedbackRepository(status: _firstCallStatus),
        homeRepository: FakeHomeRepository(error: failure),
      );

      expect(harness.errorHandler.handledErrors, [failure]);
      expect(harness.errorHandler.blockingFlags, [true]);
    });

    testWidgets('closingScreen_startsFlowOncePerEntryWithoutBuildError', (
      tester,
    ) async {
      final harness = await _pumpClosing(
        tester,
        FakeFeedbackRepository(status: _firstCallStatus),
      );

      expect(tester.takeException(), isNull);
      expect(
        harness.container.read(feedbackFlowControllerProvider).callSessionId,
        _callSessionId,
      );
    });
  });

  group('required sheet', () {
    testWidgets('requiredSheet_firstCallShowsThreeQuestionsAndNoRecall', (
      tester,
    ) async {
      await _pumpClosing(
        tester,
        FakeFeedbackRepository(status: _firstCallStatus),
      );

      await _tapOpinionButton(tester);

      expect(find.textContaining('1. 오늘 통화, 마음에 들었어?'), findsOneWidget);
      expect(find.textContaining('2. 티티와 또 통화하고 싶어?'), findsOneWidget);
      expect(find.textContaining('3. 어색했던 순간이 있었어?'), findsOneWidget);
      expect(find.textContaining('지난 대화를 기억했어?'), findsNothing);
    });

    testWidgets('requiredSheet_topStaysAtOffsetWithBottomSafeArea', (
      tester,
    ) async {
      const bottomInset = 34.0;
      tester.view.padding = const FakeViewPadding(bottom: bottomInset);
      tester.view.viewPadding = const FakeViewPadding(bottom: bottomInset);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await _pumpClosing(
        tester,
        FakeFeedbackRepository(status: _firstCallStatus),
        viewport: const ViewportCase(width: 393, height: 852, textScale: 1.0),
      );

      await _tapOpinionButton(tester);

      expect(
        tester.getTopLeft(find.byType(AppBottomSheetFrame)).dy,
        AppLayout.requiredSheetTopOffset,
      );
    });

    testWidgets('requiredSheet_laterCallShowsFourQuestions', (tester) async {
      await _pumpClosing(
        tester,
        FakeFeedbackRepository(status: _laterCallStatus),
      );

      await _tapOpinionButton(tester);

      expect(find.textContaining('3. 티티가 지난 대화를 기억했어?'), findsOneWidget);
      expect(find.textContaining('4. 어색했던 순간이 있었어?'), findsOneWidget);
    });

    testWidgets('requiredSheet_submitDisabledUntilComplete', (tester) async {
      await _pumpClosing(
        tester,
        FakeFeedbackRepository(status: _laterCallStatus),
      );
      await _tapOpinionButton(tester);
      expect(_submitButton(tester).onPressed, isNull);

      await _answerRequiredSheet(tester, previousCallRecallRequired: false);
      expect(_submitButton(tester).onPressed, isNull);

      await _scrollToAndTap(tester, find.text('기억했어'));
      expect(_submitButton(tester).onPressed, isNotNull);
    });

    testWidgets('requiredSheet_doesNotCloseOnBarrierTapBackOrDrag', (
      tester,
    ) async {
      await _pumpClosing(
        tester,
        FakeFeedbackRepository(status: _firstCallStatus),
      );
      await _tapOpinionButton(tester);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('오늘 통화는 어땠어?'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('오늘 통화는 어땠어?'), findsOneWidget);

      await tester.drag(find.text('오늘 통화는 어땠어?'), const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(find.text('오늘 통화는 어땠어?'), findsOneWidget);
    });

    testWidgets('requiredSheet_doubleTapSubmitSendsOnce', (tester) async {
      final submitGate = Completer<void>();
      final repository = _SubmitGatedFeedbackRepository(
        _firstCallStatus,
        submitGate,
      );
      await _pumpClosing(tester, repository);
      await _tapOpinionButton(tester);
      await _answerRequiredSheet(tester, previousCallRecallRequired: false);

      await tester.tap(find.text('의견 보내기'));
      await tester.pump();
      // 뒤쪽 닫힘 화면 버튼도 같은 요청 상태를 따르므로 맨 위 시트 버튼을 쓴다.
      final sheetButton = find.byType(PrimaryFilledButton).last;
      expect(
        find.descendant(
          of: sheetButton,
          matching: find.byType(ButtonLoadingIndicator),
        ),
        findsOneWidget,
      );
      await tester.tap(sheetButton);
      await tester.pump();

      expect(repository.submitRequiredCalls, hasLength(1));

      submitGate.complete();
      await tester.pumpAndSettle();
      expect(repository.submitRequiredCalls, hasLength(1));
    });

    testWidgets('requiredSheet_failureKeepsSheetAndAnswers', (tester) async {
      final repository = FakeFeedbackRepository(
        status: _firstCallStatus,
        submitRequiredError: Exception('submit failed'),
      );
      final harness = await _pumpClosing(tester, repository);
      await _tapOpinionButton(tester);
      await _answerRequiredSheet(tester, previousCallRecallRequired: false);

      await tester.tap(find.text('의견 보내기'));
      await tester.pumpAndSettle();

      expect(find.text('오늘 통화는 어땠어?'), findsOneWidget);
      expect(harness.errorHandler.handledErrors, hasLength(1));
      expect(
        harness.container
            .read(feedbackFlowControllerProvider)
            .requiredAnswers
            .rating,
        4,
      );
      expect(_submitButton(tester).onPressed, isNotNull);
    });

    testWidgets('requiredSheet_success_navigatesToCompletion', (tester) async {
      final repository = FakeFeedbackRepository(status: _firstCallStatus);
      await _pumpClosing(tester, repository);
      await _tapOpinionButton(tester);
      await _answerRequiredSheet(tester, previousCallRecallRequired: false);

      await tester.tap(find.text('의견 보내기'));
      await tester.pumpAndSettle();

      expect(repository.submitRequiredCalls, hasLength(1));
      expect(find.byType(FeedbackCompletionScreen), findsOneWidget);
      expect(find.text('오늘 통화는 어땠어?'), findsNothing);
    });

    testWidgets('requiredSheet_alreadySubmittedOnSubmitGoesHome', (
      tester,
    ) async {
      final repository = FakeFeedbackRepository(
        status: _firstCallStatus,
        submitRequiredError: apiFailure(ErrorCode.feedbackAlreadySubmitted),
      );
      await _pumpClosing(tester, repository);
      await _tapOpinionButton(tester);
      await _answerRequiredSheet(tester, previousCallRecallRequired: false);

      await tester.tap(find.text('의견 보내기'));
      await tester.pumpAndSettle();

      expect(find.text(_homePageText), findsOneWidget);
    });
  });

  group('completion screen', () {
    testWidgets('completionScreen_blocksSystemBack', (tester) async {
      await _pumpCompletion(
        tester,
        FakeFeedbackRepository(status: _laterCallStatus),
        previousCallRecallRequired: true,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(FeedbackCompletionScreen), findsOneWidget);
      expect(find.byType(AppBackButton), findsNothing);
    });

    testWidgets('completionScreen_showsCopyAndGoesHomeFromButton', (
      tester,
    ) async {
      await _pumpCompletion(
        tester,
        FakeFeedbackRepository(status: _laterCallStatus),
        previousCallRecallRequired: true,
      );

      expect(find.text('피드백을\n보내줬어!'), findsOneWidget);
      expect(find.text('소중한 의견 덕분에\n티티가 조금 더 성장할 수 있을 거야.'), findsOneWidget);

      await tester.tap(find.text('홈으로 가기'));
      await tester.pumpAndSettle();

      expect(find.text(_homePageText), findsOneWidget);
    });

    testWidgets('completionScreen_showsInvitationSheetOnlyWhenInvited', (
      tester,
    ) async {
      await _pumpCompletion(
        tester,
        FakeFeedbackRepository(status: _laterCallStatus),
        previousCallRecallRequired: true,
      );
      expect(find.text('자세히 알려주기'), findsNothing);
    });

    testWidgets('completionScreen_showsInvitationSheetOnceWhenInvited', (
      tester,
    ) async {
      final harness = await _pumpCompletion(
        tester,
        FakeFeedbackRepository(
          status: _laterCallStatus,
          detailedFeedbackInvited: true,
        ),
        previousCallRecallRequired: true,
      );

      expect(find.text('자세히 알려주기'), findsOneWidget);
      expect(find.text('티티와의 대화,\n조금 더 알려줄래?'), findsOneWidget);
      expect(find.textContaining('벌써 티티와 3번째 대화를 나눴네!'), findsOneWidget);

      // 홈 요약이 다시 도착해도 시트를 또 띄우지 않는다.
      harness.container.invalidate(homeSummaryProvider(_member.memberId));
      await tester.pumpAndSettle();

      expect(find.text('자세히 알려주기'), findsOneWidget);
    });

    testWidgets('completionScreen_declineGoesHome', (tester) async {
      await _pumpCompletion(
        tester,
        FakeFeedbackRepository(
          status: _laterCallStatus,
          detailedFeedbackInvited: true,
        ),
        previousCallRecallRequired: true,
      );

      await tester.tap(find.text('다음에 할게'));
      await tester.pumpAndSettle();

      expect(find.text(_homePageText), findsOneWidget);
    });

    testWidgets('completionScreen_acceptGoesToDetailedFeedback', (
      tester,
    ) async {
      await _pumpCompletion(
        tester,
        FakeFeedbackRepository(
          status: _laterCallStatus,
          detailedFeedbackInvited: true,
        ),
        previousCallRecallRequired: true,
      );

      await tester.tap(find.text('자세히 알려주기'));
      await tester.pumpAndSettle();

      expect(find.text(_detailedPageText), findsOneWidget);
    });

    testWidgets('invitationSheet_dismissIsDecline', (tester) async {
      await _pumpCompletion(
        tester,
        FakeFeedbackRepository(
          status: _laterCallStatus,
          detailedFeedbackInvited: true,
        ),
        previousCallRecallRequired: true,
      );

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text(_homePageText), findsOneWidget);
    });

    testWidgets('completionScreen_hidesRecallRowOnFirstCall', (tester) async {
      await _pumpCompletion(
        tester,
        FakeFeedbackRepository(status: _firstCallStatus),
        previousCallRecallRequired: false,
      );

      expect(find.text('오늘 통화 만족도'), findsOneWidget);
      expect(find.text('기억한 내용'), findsNothing);
    });

    testWidgets('completionScreen_showsRecallRowOnLaterCall', (tester) async {
      await _pumpCompletion(
        tester,
        FakeFeedbackRepository(status: _laterCallStatus),
        previousCallRecallRequired: true,
      );

      expect(find.text('기억한 내용'), findsOneWidget);
    });
  });

  group('narrow width with enlarged text', () {
    const viewport = ViewportCase(width: 320, height: 568, textScale: 1.2);

    testWidgets('closingScreen_rendersWithoutOverflow', (tester) async {
      await _pumpClosing(
        tester,
        FakeFeedbackRepository(status: _laterCallStatus),
        viewport: viewport,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('requiredSheet_fourQuestionsRenderWithoutOverflow', (
      tester,
    ) async {
      await _pumpClosing(
        tester,
        FakeFeedbackRepository(status: _laterCallStatus),
        viewport: viewport,
      );

      await _tapOpinionButton(tester);

      expect(find.text('오늘 통화는 어땠어?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('completionScreen_rendersWithoutOverflow', (tester) async {
      await _pumpCompletion(
        tester,
        FakeFeedbackRepository(status: _laterCallStatus),
        previousCallRecallRequired: true,
        viewport: viewport,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('invitationSheet_rendersWithoutOverflow', (tester) async {
      await _pumpCompletion(
        tester,
        FakeFeedbackRepository(
          status: _laterCallStatus,
          detailedFeedbackInvited: true,
        ),
        previousCallRecallRequired: true,
        viewport: viewport,
      );

      expect(find.text('자세히 알려주기'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
  group('flow exit resets', () {
    FeedbackFlowState flowState(_Harness harness) =>
        harness.container.read(feedbackFlowControllerProvider);

    testWidgets('closingScreen_alreadySubmittedExit_resetsFlowWithoutError', (
      tester,
    ) async {
      final harness = await _pumpClosing(
        tester,
        FakeFeedbackRepository(status: _submittedStatus),
      );

      await _tapOpinionButton(tester);

      expect(find.text(_homePageText), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(flowState(harness), FeedbackFlowState.initial);
    });

    testWidgets('requiredSheet_alreadySubmittedExit_resetsFlowWithoutError', (
      tester,
    ) async {
      final harness = await _pumpClosing(
        tester,
        FakeFeedbackRepository(
          status: _firstCallStatus,
          submitRequiredError: apiFailure(ErrorCode.feedbackAlreadySubmitted),
        ),
      );
      await _tapOpinionButton(tester);
      await _answerRequiredSheet(tester, previousCallRecallRequired: false);

      await tester.tap(find.text('의견 보내기'));
      await tester.pumpAndSettle();

      expect(find.text(_homePageText), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(flowState(harness), FeedbackFlowState.initial);
    });

    testWidgets('completionScreen_homeButton_resetsFlowWithoutError', (
      tester,
    ) async {
      final harness = await _pumpCompletion(
        tester,
        FakeFeedbackRepository(status: _laterCallStatus),
        previousCallRecallRequired: true,
      );

      await tester.tap(find.text('홈으로 가기'));
      await tester.pumpAndSettle();

      expect(find.text(_homePageText), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(flowState(harness), FeedbackFlowState.initial);
    });

    testWidgets('invitationSheet_decline_resetsFlowWithoutError', (
      tester,
    ) async {
      final harness = await _pumpCompletion(
        tester,
        FakeFeedbackRepository(
          status: _laterCallStatus,
          detailedFeedbackInvited: true,
        ),
        previousCallRecallRequired: true,
      );

      await tester.tap(find.text('다음에 할게'));
      await tester.pumpAndSettle();

      expect(find.text(_homePageText), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(flowState(harness), FeedbackFlowState.initial);
    });

    testWidgets('invitationSheet_dismiss_resetsFlowWithoutError', (
      tester,
    ) async {
      final harness = await _pumpCompletion(
        tester,
        FakeFeedbackRepository(
          status: _laterCallStatus,
          detailedFeedbackInvited: true,
        ),
        previousCallRecallRequired: true,
      );

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text(_homePageText), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(flowState(harness), FeedbackFlowState.initial);
    });

    testWidgets('invitationSheet_accept_keepsFlowForDetailedFeedback', (
      tester,
    ) async {
      final harness = await _pumpCompletion(
        tester,
        FakeFeedbackRepository(
          status: _laterCallStatus,
          detailedFeedbackInvited: true,
        ),
        previousCallRecallRequired: true,
      );

      await tester.tap(find.text('자세히 알려주기'));
      await tester.pumpAndSettle();

      expect(flowState(harness).callSessionId, _callSessionId);
      expect(flowState(harness).detailedFeedbackInvited, isTrue);
    });
  });
}
