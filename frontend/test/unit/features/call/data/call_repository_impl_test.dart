import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/auth/token_storage.dart';
import 'package:teeq/core/config/app_config.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/network/dio_client.dart';
import 'package:teeq/features/call/data/call_repository_impl.dart';
import 'package:teeq/features/call/domain/call_repository.dart';

import '../../../../support/fake_token_storage.dart';
import '../../../../support/scripted_http_client_adapter.dart';

const _startJson = {
  'callSessionId': 'call-session-1',
  'maxDurationSeconds': 600,
  'connection': {
    'livekitUrl': 'wss://livekit.example.test',
    'token': 'access-token-value',
    'personaId': 'persona-1',
  },
};

({CallRepository repository, ScriptedHttpClientAdapter adapter}) _setUp() {
  final container = ProviderContainer(
    overrides: [
      tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
      appConfigProvider.overrideWithValue(
        const AppConfig(apiBaseUrl: 'https://api.example.test'),
      ),
    ],
  );
  addTearDown(container.dispose);
  final adapter = ScriptedHttpClientAdapter();
  container.read(dioProvider).httpClientAdapter = adapter;
  return (repository: container.read(callRepositoryProvider), adapter: adapter);
}

void main() {
  test('startCall_mapsConnectionToStartInfo', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on('/api/calls', [ScriptedReply.json(200, _startJson)]);

    final info = await repository.startCall();

    expect(adapter.requestsTo('/api/calls').single.method, 'POST');
    expect(info.callSessionId, 'call-session-1');
    expect(info.maxDurationSeconds, 600);
    expect(info.serverUrl, 'wss://livekit.example.test');
    expect(info.accessToken, 'access-token-value');
  });

  test('startCall_throwsUnexpectedExceptionWhenConnectionMissing', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on('/api/calls', [
      ScriptedReply.json(200, {
        'callSessionId': 'call-session-1',
        'maxDurationSeconds': 600,
      }),
    ]);

    await expectLater(
      repository.startCall(),
      throwsA(isA<UnexpectedException>()),
    );
  });

  test('startCall_throwsUnexpectedExceptionWhenTokenNotString', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on('/api/calls', [
      ScriptedReply.json(200, {
        ..._startJson,
        'connection': {'livekitUrl': 'wss://x', 'token': 1},
      }),
    ]);

    await expectLater(
      repository.startCall(),
      throwsA(isA<UnexpectedException>()),
    );
  });

  test('startCall_throwsUnexpectedExceptionWhenLivekitUrlMissing', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on('/api/calls', [
      ScriptedReply.json(200, {
        ..._startJson,
        'connection': {'token': 'access-token-value'},
      }),
    ]);

    await expectLater(
      repository.startCall(),
      throwsA(isA<UnexpectedException>()),
    );
  });

  test('fetchTodayLimitStatus_mapsRemainingSeconds', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on('/api/call-limits/today', [
      ScriptedReply.json(200, {
        'usedSeconds': 100,
        'remainingSeconds': 500,
        'allowedSeconds': 600,
        'canStart': true,
      }),
    ]);

    final status = await repository.fetchTodayLimitStatus();

    expect(adapter.requestsTo('/api/call-limits/today').single.method, 'GET');
    expect(status.remainingSeconds, 500);
  });
}
