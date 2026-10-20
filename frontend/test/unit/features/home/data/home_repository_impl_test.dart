import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/auth/token_storage.dart';
import 'package:teeq/core/config/app_config.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/network/dio_client.dart';
import 'package:teeq/features/home/data/home_repository_impl.dart';
import 'package:teeq/features/home/domain/home_repository.dart';

import '../../../../support/fake_token_storage.dart';
import '../../../../support/scripted_http_client_adapter.dart';

const _homeJson = {
  'characterName': '티큐',
  'personalityTags': ['다정한', '차분한', '든든한'],
  'greeting': '소연아,\n오늘 하루 어땠어?',
  'callLimit': {'remainingSeconds': 600},
  'pendingFeedback': null,
};

({HomeRepository repository, ScriptedHttpClientAdapter adapter}) _setUp() {
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
  return (repository: container.read(homeRepositoryProvider), adapter: adapter);
}

void main() {
  test('fetchHome_mapsResponseFieldsAndIgnoresOthers', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on('/api/home', [ScriptedReply.json(200, _homeJson)]);

    final summary = await repository.fetchHome();

    expect(adapter.requestsTo('/api/home').single.method, 'GET');
    expect(summary.characterName, '티큐');
    expect(summary.personalityTags, ['다정한', '차분한', '든든한']);
    expect(summary.greeting, '소연아,\n오늘 하루 어땠어?');
  });

  test('fetchHome_propagatesFailure', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on('/api/home', [
      ScriptedReply.json(502, {
        'errorCode': 'AI_SERVER_UNAVAILABLE',
        'errorMessage': 'AI 서버 오류',
      }),
    ]);

    await expectLater(
      repository.fetchHome(),
      throwsA(
        isA<DioException>().having(
          (exception) => exception.error,
          'error',
          isA<ApiException>(),
        ),
      ),
    );
  });

  test('fetchHome_mapsPendingFeedback', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on('/api/home', [
      ScriptedReply.json(200, {
        ..._homeJson,
        'pendingFeedback': {'callSessionId': 'call-session-1', 'callIndex': 2},
      }),
    ]);

    final summary = await repository.fetchHome();

    expect(summary.pendingFeedback?.callSessionId, 'call-session-1');
    expect(summary.pendingFeedback?.callIndex, 2);
  });

  test('fetchHome_mapsNullPendingFeedback', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on('/api/home', [ScriptedReply.json(200, _homeJson)]);

    final summary = await repository.fetchHome();

    expect(summary.pendingFeedback, isNull);
  });
}
