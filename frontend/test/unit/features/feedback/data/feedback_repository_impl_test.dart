import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/auth/token_storage.dart';
import 'package:teeq/core/config/app_config.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/core/network/dio_client.dart';
import 'package:teeq/features/feedback/data/feedback_repository_impl.dart';
import 'package:teeq/features/feedback/domain/awkward_moment.dart';
import 'package:teeq/features/feedback/domain/detailed_feedback_question.dart';
import 'package:teeq/features/feedback/domain/detailed_feedback_submission.dart';
import 'package:teeq/features/feedback/domain/feedback_repository.dart';
import 'package:teeq/features/feedback/domain/previous_call_recall.dart';
import 'package:teeq/features/feedback/domain/required_feedback_submission.dart';
import 'package:teeq/features/feedback/domain/revisit_intention.dart';
import 'package:teeq/features/feedback/domain/start_reason.dart';

import '../../../../support/fake_token_storage.dart';
import '../../../../support/scripted_http_client_adapter.dart';

const _callSessionId = 'call-session-1';
const _statusPath = '/api/calls/$_callSessionId/feedback-status';
const _requiredPath = '/api/calls/$_callSessionId/required-feedback';
const _detailedPath = '/api/calls/$_callSessionId/detailed-feedback';

({FeedbackRepository repository, ScriptedHttpClientAdapter adapter}) _setUp() {
  final container = ProviderContainer(
    overrides: [
      tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
      appConfigProvider.overrideWithValue(
        const AppConfig(
          apiBaseUrl: 'https://api.example.test',
          appleServiceId: 'kr.co.teeq.app.service',
          appleRedirectUri: 'https://api.example.test/api/auth/apple/callback',
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  final adapter = ScriptedHttpClientAdapter();
  container.read(dioProvider).httpClientAdapter = adapter;
  return (
    repository: container.read(feedbackRepositoryProvider),
    adapter: adapter,
  );
}

Map<String, dynamic> _bodyOf(RequestOptions options) =>
    options.data as Map<String, dynamic>;

void main() {
  test('fetchStatus_mapsResponseFields', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on(_statusPath, [
      ScriptedReply.json(200, {
        'callIndex': 3,
        'previousCallRecallRequired': true,
        'requiredFeedbackSubmitted': false,
      }),
    ]);

    final status = await repository.fetchStatus(_callSessionId);

    expect(adapter.requestsTo(_statusPath).single.method, 'GET');
    expect(status.callIndex, 3);
    expect(status.previousCallRecallRequired, isTrue);
    expect(status.requiredFeedbackSubmitted, isFalse);
  });

  test('fetchStatus_encodesCallSessionIdInPath', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on('/api/calls/a%20b/feedback-status', [
      ScriptedReply.json(200, {
        'callIndex': 1,
        'previousCallRecallRequired': false,
        'requiredFeedbackSubmitted': false,
      }),
    ]);

    await repository.fetchStatus('a b');

    expect(adapter.callCount('/api/calls/a%20b/feedback-status'), 1);
  });

  test('fetchStatus_propagatesApiFailure', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on(_statusPath, [
      ScriptedReply.json(409, {
        'errorCode': 'CALL_NOT_FEEDBACKABLE',
        'errorMessage': '피드백 불가',
      }),
    ]);

    await expectLater(
      repository.fetchStatus(_callSessionId),
      throwsA(
        isA<DioException>().having(
          (exception) => exception.error,
          'error',
          isA<ApiException>().having(
            (exception) => exception.errorCode,
            'errorCode',
            ErrorCode.callNotFeedbackable,
          ),
        ),
      ),
    );
  });

  test('submitRequired_sendsBodyAndReturnsInvitation', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on(_requiredPath, [
      ScriptedReply.json(201, {'detailedFeedbackInvited': true}),
    ]);

    final invited = await repository.submitRequired(
      _callSessionId,
      const RequiredFeedbackSubmission(
        rating: 4,
        revisitIntention: RevisitIntention.yes,
        previousCallRecall: PreviousCallRecall.remembered,
        awkwardMoments: [AwkwardMoment.cut, AwkwardMoment.slow],
      ),
    );

    final request = adapter.requestsTo(_requiredPath).single;
    expect(request.method, 'POST');
    expect(_bodyOf(request), {
      'rating': 4,
      'revisitIntention': 'YES',
      'previousCallRecall': 'REMEMBERED',
      'awkwardMoments': ['CUT', 'SLOW'],
    });
    expect(invited, isTrue);
  });

  test('submitRequired_omitsPreviousCallRecallWhenNull', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on(_requiredPath, [
      ScriptedReply.json(201, {'detailedFeedbackInvited': false}),
    ]);

    final invited = await repository.submitRequired(
      _callSessionId,
      const RequiredFeedbackSubmission(
        rating: 5,
        revisitIntention: RevisitIntention.no,
        awkwardMoments: [AwkwardMoment.none],
      ),
    );

    final body = _bodyOf(adapter.requestsTo(_requiredPath).single);
    expect(body.containsKey('previousCallRecall'), isFalse);
    expect(body['awkwardMoments'], ['NONE']);
    expect(invited, isFalse);
  });

  test('submitDetailed_sendsAllFieldsAndOmitsNulls', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on(_detailedPath, [ScriptedReply.json(201, null)]);

    await repository.submitDetailed(
      _callSessionId,
      const DetailedFeedbackSubmission(
        scores: {
          DetailedFeedbackQuestion.timing: 4,
          DetailedFeedbackQuestion.personaFit: 5,
          DetailedFeedbackQuestion.memory: 3,
          DetailedFeedbackQuestion.empathyTrust: 2,
          DetailedFeedbackQuestion.personalComfort: 1,
          DetailedFeedbackQuestion.storageComfort: 4,
        },
        reasons: {
          DetailedFeedbackQuestion.timing: '타이밍 이유',
          DetailedFeedbackQuestion.memory: '기억 이유',
        },
        memoryNotApplicable: false,
        startReasons: [StartReason.needToTalk, StartReason.other],
        startReasonOtherText: '그냥',
      ),
    );

    final request = adapter.requestsTo(_detailedPath).single;
    expect(request.method, 'POST');
    expect(_bodyOf(request), {
      'timingScore': 4,
      'timingReason': '타이밍 이유',
      'personaFitScore': 5,
      'memoryScore': 3,
      'memoryReason': '기억 이유',
      'memoryNotApplicable': false,
      'empathyTrustScore': 2,
      'personalComfortScore': 1,
      'storageComfortScore': 4,
      'startReasons': ['NEED_TO_TALK', 'OTHER'],
      'startReasonOtherText': '그냥',
    });
  });

  test('submitDetailed_omitsMemoryFieldsWhenNotApplicable', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on(_detailedPath, [ScriptedReply.json(201, null)]);

    await repository.submitDetailed(
      _callSessionId,
      const DetailedFeedbackSubmission(
        scores: {
          DetailedFeedbackQuestion.timing: 4,
          DetailedFeedbackQuestion.personaFit: 5,
          DetailedFeedbackQuestion.empathyTrust: 2,
          DetailedFeedbackQuestion.personalComfort: 1,
          DetailedFeedbackQuestion.storageComfort: 4,
        },
        reasons: {},
        memoryNotApplicable: true,
        freeText: '자유 서술',
        startReasons: [StartReason.testingService],
      ),
    );

    final body = _bodyOf(adapter.requestsTo(_detailedPath).single);
    expect(body.containsKey('memoryScore'), isFalse);
    expect(body.containsKey('memoryReason'), isFalse);
    expect(body['memoryNotApplicable'], isTrue);
    expect(body['freeText'], '자유 서술');
    expect(body.containsKey('startReasonOtherText'), isFalse);
    expect(body.containsKey('timingReason'), isFalse);
  });
}
