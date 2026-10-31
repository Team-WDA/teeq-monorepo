import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/auth/auth_status_controller.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/features/feedback/data/feedback_repository_impl.dart';
import 'package:teeq/features/feedback/domain/awkward_moment.dart';
import 'package:teeq/features/feedback/domain/detailed_feedback_question.dart';
import 'package:teeq/features/feedback/domain/feedback_status.dart';
import 'package:teeq/features/feedback/domain/previous_call_recall.dart';
import 'package:teeq/features/feedback/domain/revisit_intention.dart';
import 'package:teeq/features/feedback/domain/start_reason.dart';
import 'package:teeq/features/feedback/presentation/feedback_flow_controller.dart';
import 'package:teeq/features/feedback/presentation/feedback_flow_state.dart';
import 'package:teeq/features/feedback/presentation/feedback_status_retry_policy.dart';
import 'package:teeq/features/home/data/home_repository_impl.dart';
import 'package:teeq/features/home/domain/character_mood.dart';
import 'package:teeq/features/home/domain/home_summary.dart';
import 'package:teeq/features/home/presentation/home_summary_provider.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';

import '../../../../support/fake_feedback_repository.dart';
import '../../../../support/fake_home_repository.dart';

class _RecordingErrorHandler extends Fake implements ErrorHandler {
  final List<Object> handledErrors = [];

  @override
  void handle(Object error, {bool blocking = false}) {
    handledErrors.add(error);
  }
}

const _member = Member(
  memberId: 'member-1',
  nickname: '소연',
  hasAiCharacter: true,
  loginType: LoginType.google,
);

const _callSessionId = 'call-1';

const _status = FeedbackStatus(
  callIndex: 2,
  previousCallRecallRequired: true,
  requiredFeedbackSubmitted: false,
);

typedef _SetUp = ({
  ProviderContainer container,
  FeedbackFlowController controller,
  FakeFeedbackRepository feedbackRepository,
  FakeHomeRepository homeRepository,
  _RecordingErrorHandler errorHandler,
});

/// 처음 [failureCount]번의 상태 조회만 실패하고 이후에는 성공하는 저장소.
class _FailsNTimesFeedbackRepository extends FakeFeedbackRepository {
  _FailsNTimesFeedbackRepository(
    FeedbackStatus status,
    this._error,
    this._failureCount,
  ) : super(status: status);

  final Object _error;
  final int _failureCount;

  @override
  Future<FeedbackStatus> fetchStatus(String callSessionId) {
    if (fetchStatusCount < _failureCount) {
      fetchStatusCount += 1;
      return Future.error(_error);
    }
    return super.fetchStatus(callSessionId);
  }
}

/// 첫 상태 조회만 실패하고 이후에는 성공하는 저장소.
class _FailsOnceFeedbackRepository extends FakeFeedbackRepository {
  _FailsOnceFeedbackRepository(FeedbackStatus status, this._error)
    : super(status: status);

  final Object _error;

  @override
  Future<FeedbackStatus> fetchStatus(String callSessionId) {
    if (fetchStatusCount == 0) {
      fetchStatusCount += 1;
      return Future.error(_error);
    }
    return super.fetchStatus(callSessionId);
  }
}

_SetUp _setUp(FakeFeedbackRepository feedbackRepository) {
  final homeRepository = FakeHomeRepository(
    summary: const HomeSummary(
      characterName: '티티',
      characterType: CharacterType.character1,
      characterMood: CharacterMood.welcome,
      personalityTags: ['다정함', '차분함', '유쾌함'],
      greeting: '안녕',
    ),
  );
  final errorHandler = _RecordingErrorHandler();
  final container = ProviderContainer(
    // 실패 응답이 재시도되지 않도록 한다.
    retry: (retryCount, error) => null,
    overrides: [
      feedbackRepositoryProvider.overrideWithValue(feedbackRepository),
      homeRepositoryProvider.overrideWithValue(homeRepository),
      errorHandlerProvider.overrideWithValue(errorHandler),
      feedbackStatusRetryPolicyProvider.overrideWithValue(
        const FeedbackStatusRetryPolicy(interval: Duration.zero),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.read(authStatusControllerProvider.notifier).markSignedIn();
  container.read(currentMemberControllerProvider.notifier).update(_member);
  return (
    container: container,
    controller: container.read(feedbackFlowControllerProvider.notifier),
    feedbackRepository: feedbackRepository,
    homeRepository: homeRepository,
    errorHandler: errorHandler,
  );
}

FeedbackFlowState _stateOf(_SetUp setUp) =>
    setUp.container.read(feedbackFlowControllerProvider);

void _answerRequired(FeedbackFlowController controller) {
  controller
    ..setRating(4)
    ..setRevisitIntention(RevisitIntention.yes)
    ..setPreviousCallRecall(PreviousCallRecall.remembered)
    ..toggleAwkwardMoment(AwkwardMoment.none);
}

void _answerDetailed(FeedbackFlowController controller) {
  for (final question in DetailedFeedbackQuestion.values) {
    controller.setDetailedScore(question, 5);
  }
  controller.toggleStartReason(StartReason.needToTalk);
}

/// 상태를 불러오고 필수 응답을 제출해 상세 피드백 초대까지 받은 흐름을 만든다.
Future<_SetUp> _setUpInvited({Object? submitDetailedError}) async {
  final setUp = _setUp(
    FakeFeedbackRepository(
      status: _status,
      detailedFeedbackInvited: true,
      submitDetailedError: submitDetailedError,
    ),
  );
  setUp.controller.start(_callSessionId);
  await setUp.controller.loadStatus();
  _answerRequired(setUp.controller);
  await setUp.controller.submitRequired();
  _answerDetailed(setUp.controller);
  return setUp;
}

void main() {
  test('loadStatus_storesStatusAndReturnsReady', () async {
    final setUp = _setUp(FakeFeedbackRepository(status: _status));
    setUp.controller.start(_callSessionId);

    final result = await setUp.controller.loadStatus();

    expect(result, FeedbackStatusLoadResult.ready);
    expect(_stateOf(setUp).status, _status);
    expect(_stateOf(setUp).isRequestInProgress, isFalse);
  });

  test('loadStatus_returnsAlreadySubmittedWhenServerSaysSubmitted', () async {
    final setUp = _setUp(
      FakeFeedbackRepository(
        status: const FeedbackStatus(
          callIndex: 1,
          previousCallRecallRequired: false,
          requiredFeedbackSubmitted: true,
        ),
      ),
    );
    setUp.controller.start(_callSessionId);

    final result = await setUp.controller.loadStatus();

    expect(result, FeedbackStatusLoadResult.alreadySubmitted);
  });

  test('loadStatus_alreadySubmittedInvalidatesHome', () async {
    final setUp = _setUp(
      FakeFeedbackRepository(
        status: const FeedbackStatus(
          callIndex: 1,
          previousCallRecallRequired: false,
          requiredFeedbackSubmitted: true,
        ),
      ),
    );
    final subscription = setUp.container.listen(
      homeSummaryProvider(_member.memberId),
      (_, _) {},
    );
    addTearDown(subscription.close);
    await setUp.container.read(homeSummaryProvider(_member.memberId).future);
    setUp.controller.start(_callSessionId);

    await setUp.controller.loadStatus();
    await setUp.container.read(homeSummaryProvider(_member.memberId).future);

    expect(setUp.homeRepository.fetchCount, 2);
  });

  test('loadStatus_callSessionNotFoundReturnsUnavailable', () async {
    final error = apiFailure(ErrorCode.callSessionNotFound, httpStatus: 404);
    final setUp = _setUp(
      FakeFeedbackRepository(status: _status, statusError: error),
    );
    final subscription = setUp.container.listen(
      homeSummaryProvider(_member.memberId),
      (_, _) {},
    );
    addTearDown(subscription.close);
    await setUp.container.read(homeSummaryProvider(_member.memberId).future);
    setUp.controller.start(_callSessionId);

    final result = await setUp.controller.loadStatus();
    await setUp.container.read(homeSummaryProvider(_member.memberId).future);

    expect(result, FeedbackStatusLoadResult.unavailable);
    expect(setUp.errorHandler.handledErrors, [error]);
    expect(_stateOf(setUp).isRequestInProgress, isFalse);
    expect(setUp.homeRepository.fetchCount, 2);
  });

  group('loadStatus 재시도', () {
    final notFeedbackable = apiFailure(
      ErrorCode.callNotFeedbackable,
      httpStatus: 409,
    );

    test('callNotFeedbackableThenSuccess_retriesAndReturnsReady', () async {
      final repository = _FailsNTimesFeedbackRepository(
        _status,
        notFeedbackable,
        3,
      );
      final setUp = _setUp(repository);
      setUp.controller.start(_callSessionId);

      final result = await setUp.controller.loadStatus();

      expect(result, FeedbackStatusLoadResult.ready);
      expect(repository.fetchStatusCount, 4);
      expect(setUp.errorHandler.handledErrors, isEmpty);
      expect(_stateOf(setUp).status, _status);
      expect(_stateOf(setUp).isRequestInProgress, isFalse);
    });

    test('callNotFeedbackableAlways_stopsAtMaxAttemptsAsUnavailable', () async {
      final repository = FakeFeedbackRepository(
        status: _status,
        statusError: notFeedbackable,
      );
      final setUp = _setUp(repository);
      setUp.controller.start(_callSessionId);

      final result = await setUp.controller.loadStatus();

      expect(result, FeedbackStatusLoadResult.unavailable);
      expect(repository.fetchStatusCount, 10);
      expect(setUp.errorHandler.handledErrors, isEmpty);
      expect(_stateOf(setUp).isRequestInProgress, isFalse);
    });

    test('newGenerationDuringRetryWait_oldCallStopsAndIsIgnored', () async {
      final repository = FakeFeedbackRepository(
        status: _status,
        statusError: notFeedbackable,
      );
      final setUp = _setUp(repository);
      setUp.controller.start(_callSessionId);

      final oldRequest = setUp.controller.loadStatus();
      // 첫 시도가 실패하고 대기에 들어간 뒤 흐름을 다시 시작한다.
      await Future<void>.delayed(Duration.zero);
      setUp.controller.start('call-2');
      final result = await oldRequest;

      expect(result, FeedbackStatusLoadResult.ignored);
      expect(repository.fetchStatusCount, lessThan(10));
      expect(setUp.errorHandler.handledErrors, isEmpty);
      expect(_stateOf(setUp).callSessionId, 'call-2');
      expect(_stateOf(setUp).isRequestInProgress, isFalse);
    });

    test('callSessionNotFound_doesNotRetry', () async {
      final error = apiFailure(ErrorCode.callSessionNotFound, httpStatus: 404);
      final repository = FakeFeedbackRepository(
        status: _status,
        statusError: error,
      );
      final setUp = _setUp(repository);
      setUp.controller.start(_callSessionId);

      final result = await setUp.controller.loadStatus();

      expect(result, FeedbackStatusLoadResult.unavailable);
      expect(repository.fetchStatusCount, 1);
      expect(setUp.errorHandler.handledErrors, [error]);
    });

    test('otherError_doesNotRetryAndUsesCentralHandling', () async {
      final error = apiFailure(ErrorCode.internalServerError, httpStatus: 500);
      final repository = FakeFeedbackRepository(
        status: _status,
        statusError: error,
      );
      final setUp = _setUp(repository);
      setUp.controller.start(_callSessionId);

      final result = await setUp.controller.loadStatus();

      expect(result, FeedbackStatusLoadResult.failed);
      expect(repository.fetchStatusCount, 1);
      expect(setUp.errorHandler.handledErrors, [error]);
    });
  });

  test('submitRequired_alreadySubmittedInvalidatesHome', () async {
    final setUp = _setUp(
      FakeFeedbackRepository(
        status: _status,
        submitRequiredError: apiFailure(ErrorCode.feedbackAlreadySubmitted),
      ),
    );
    final subscription = setUp.container.listen(
      homeSummaryProvider(_member.memberId),
      (_, _) {},
    );
    addTearDown(subscription.close);
    await setUp.container.read(homeSummaryProvider(_member.memberId).future);
    setUp.controller.start(_callSessionId);
    await setUp.controller.loadStatus();
    _answerRequired(setUp.controller);

    await setUp.controller.submitRequired();
    await setUp.container.read(homeSummaryProvider(_member.memberId).future);

    expect(setUp.homeRepository.fetchCount, 2);
  });

  test('restartWithSameId_lateResponseDoesNotTouchNewFlow', () async {
    final gate = Completer<void>();
    final setUp = _setUp(FakeFeedbackRepository(status: _status, gate: gate));
    setUp.controller.start(_callSessionId);
    final oldRequest = setUp.controller.loadStatus();
    expect(_stateOf(setUp).isRequestInProgress, isTrue);

    setUp.controller.start(_callSessionId);
    expect(_stateOf(setUp).isRequestInProgress, isFalse);
    gate.complete();
    final oldResult = await oldRequest;

    expect(oldResult, FeedbackStatusLoadResult.ignored);
    expect(_stateOf(setUp).status, isNull);
    expect(_stateOf(setUp).isRequestInProgress, isFalse);
    final newResult = await setUp.controller.loadStatus();
    expect(newResult, FeedbackStatusLoadResult.ready);
  });

  test('loadStatus_failureCallsErrorHandlerAndKeepsStateRetryable', () async {
    final error = apiFailure(ErrorCode.internalServerError, httpStatus: 500);
    final repository = _FailsOnceFeedbackRepository(_status, error);
    final setUp = _setUp(repository);
    setUp.controller.start(_callSessionId);

    final failed = await setUp.controller.loadStatus();

    expect(failed, FeedbackStatusLoadResult.failed);
    expect(setUp.errorHandler.handledErrors, [error]);
    expect(_stateOf(setUp).status, isNull);
    expect(_stateOf(setUp).isRequestInProgress, isFalse);

    // 같은 컨트롤러로 다시 호출하면 재시도되어 성공한다.
    final retried = await setUp.controller.loadStatus();

    expect(retried, FeedbackStatusLoadResult.ready);
    expect(_stateOf(setUp).status, _status);
    expect(repository.fetchStatusCount, 2);
  });

  test('loadStatus_ignoresWhileInProgress', () async {
    final gate = Completer<void>();
    final setUp = _setUp(FakeFeedbackRepository(status: _status, gate: gate));
    setUp.controller.start(_callSessionId);

    final first = setUp.controller.loadStatus();
    final second = await setUp.controller.loadStatus();
    gate.complete();

    expect(second, FeedbackStatusLoadResult.ignored);
    expect(await first, FeedbackStatusLoadResult.ready);
    expect(setUp.feedbackRepository.fetchStatusCount, 1);
  });

  test('submitRequired_sendsMappedSubmissionOnce', () async {
    final setUp = _setUp(FakeFeedbackRepository(status: _status));
    setUp.controller.start(_callSessionId);
    await setUp.controller.loadStatus();
    _answerRequired(setUp.controller);

    final first = setUp.controller.submitRequired();
    final second = await setUp.controller.submitRequired();

    expect(second, RequiredFeedbackSubmitResult.ignored);
    expect(await first, RequiredFeedbackSubmitResult.submitted);
    expect(setUp.feedbackRepository.submitRequiredCalls.length, 1);
    final submission = setUp.feedbackRepository.submitRequiredCalls.single;
    expect(submission.rating, 4);
    expect(submission.revisitIntention, RevisitIntention.yes);
    expect(submission.previousCallRecall, PreviousCallRecall.remembered);
    expect(submission.awkwardMoments, [AwkwardMoment.none]);
  });

  test('submitRequired_marksSubmittedAndInvalidatesHome', () async {
    final setUp = _setUp(FakeFeedbackRepository(status: _status));
    // homeSummaryProvider는 autoDispose라 구독을 유지해야 무효화가 다시 불러온다.
    final subscription = setUp.container.listen(
      homeSummaryProvider(_member.memberId),
      (_, _) {},
    );
    addTearDown(subscription.close);
    await setUp.container.read(homeSummaryProvider(_member.memberId).future);
    setUp.controller.start(_callSessionId);
    await setUp.controller.loadStatus();
    _answerRequired(setUp.controller);
    expect(setUp.homeRepository.fetchCount, 1);

    await setUp.controller.submitRequired();
    await setUp.container.read(homeSummaryProvider(_member.memberId).future);

    expect(_stateOf(setUp).requiredSubmitted, isTrue);
    expect(setUp.homeRepository.fetchCount, 2);
  });

  test('submitRequired_returnsInvitationWhenServerInvites', () async {
    final setUp = _setUp(
      FakeFeedbackRepository(status: _status, detailedFeedbackInvited: true),
    );
    setUp.controller.start(_callSessionId);
    await setUp.controller.loadStatus();
    _answerRequired(setUp.controller);

    final result = await setUp.controller.submitRequired();

    expect(result, RequiredFeedbackSubmitResult.submittedWithInvitation);
    expect(_stateOf(setUp).detailedFeedbackInvited, isTrue);
  });

  test('submitRequired_ignoredWhenIncomplete', () async {
    final setUp = _setUp(FakeFeedbackRepository(status: _status));
    setUp.controller.start(_callSessionId);
    await setUp.controller.loadStatus();
    setUp.controller.setRating(3);

    final result = await setUp.controller.submitRequired();

    expect(result, RequiredFeedbackSubmitResult.ignored);
    expect(setUp.feedbackRepository.submitRequiredCalls, isEmpty);
  });

  test('submitRequired_alreadySubmittedDoesNotCallErrorHandler', () async {
    final setUp = _setUp(
      FakeFeedbackRepository(
        status: _status,
        submitRequiredError: apiFailure(ErrorCode.feedbackAlreadySubmitted),
      ),
    );
    setUp.controller.start(_callSessionId);
    await setUp.controller.loadStatus();
    _answerRequired(setUp.controller);

    final result = await setUp.controller.submitRequired();

    expect(result, RequiredFeedbackSubmitResult.alreadySubmitted);
    expect(setUp.errorHandler.handledErrors, isEmpty);
    expect(_stateOf(setUp).isRequestInProgress, isFalse);
  });

  test('submitRequired_failureKeepsAnswersAndCallsErrorHandler', () async {
    final error = DioException(requestOptions: RequestOptions(path: '/'));
    final setUp = _setUp(
      FakeFeedbackRepository(status: _status, submitRequiredError: error),
    );
    setUp.controller.start(_callSessionId);
    await setUp.controller.loadStatus();
    _answerRequired(setUp.controller);
    final answersBefore = _stateOf(setUp).requiredAnswers;

    final result = await setUp.controller.submitRequired();

    expect(result, RequiredFeedbackSubmitResult.failed);
    expect(setUp.errorHandler.handledErrors, [error]);
    expect(_stateOf(setUp).requiredAnswers, answersBefore);
    expect(_stateOf(setUp).requiredSubmitted, isFalse);
    expect(_stateOf(setUp).isRequestInProgress, isFalse);
  });

  test('submitDetailed_ignoredWhenNotInvited', () async {
    final setUp = _setUp(FakeFeedbackRepository(status: _status));
    setUp.controller.start(_callSessionId);
    await setUp.controller.loadStatus();
    _answerRequired(setUp.controller);
    await setUp.controller.submitRequired();
    _answerDetailed(setUp.controller);

    final result = await setUp.controller.submitDetailed();

    expect(result, DetailedFeedbackSubmitResult.ignored);
    expect(setUp.feedbackRepository.submitDetailedCalls, isEmpty);
  });

  test('submitDetailed_sendsSubmissionAndMarksSubmitted', () async {
    final setUp = await _setUpInvited();

    final first = setUp.controller.submitDetailed();
    final second = await setUp.controller.submitDetailed();
    final result = await first;

    expect(second, DetailedFeedbackSubmitResult.ignored);
    expect(result, DetailedFeedbackSubmitResult.submitted);
    expect(setUp.feedbackRepository.submitDetailedCalls.length, 1);
    expect(_stateOf(setUp).detailedSubmitted, isTrue);
    expect(_stateOf(setUp).isRequestInProgress, isFalse);
  });

  test('submitDetailed_alreadySubmittedMapsToResult', () async {
    final setUp = await _setUpInvited(
      submitDetailedError: apiFailure(ErrorCode.feedbackAlreadySubmitted),
    );

    final result = await setUp.controller.submitDetailed();

    expect(result, DetailedFeedbackSubmitResult.alreadySubmitted);
    expect(setUp.errorHandler.handledErrors, isEmpty);
  });

  test('submitDetailed_failureKeepsAnswersAndCallsErrorHandler', () async {
    final error = DioException(requestOptions: RequestOptions(path: '/'));
    final setUp = await _setUpInvited(submitDetailedError: error);

    final result = await setUp.controller.submitDetailed();

    expect(result, DetailedFeedbackSubmitResult.failed);
    expect(setUp.errorHandler.handledErrors, [error]);
    expect(_stateOf(setUp).detailedSubmitted, isFalse);
    expect(_stateOf(setUp).isRequestInProgress, isFalse);
  });

  test('start_clearsPreviousFlow', () async {
    final setUp = await _setUpInvited();

    setUp.controller.start('call-2');

    final state = _stateOf(setUp);
    expect(state.callSessionId, 'call-2');
    expect(state.status, isNull);
    expect(state.requiredSubmitted, isFalse);
    expect(state.detailedFeedbackInvited, isFalse);
    expect(state.requiredAnswers.rating, isNull);
    expect(state.detailedAnswers.scores, isEmpty);
  });

  test('signOut_resetsFlow', () async {
    final setUp = await _setUpInvited();

    setUp.container.read(authStatusControllerProvider.notifier).markSignedOut();

    expect(_stateOf(setUp), FeedbackFlowState.initial);
  });
}
