import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/auth/auth_tokens.dart';
import 'package:teeq/core/debug_console/debug_console_store.dart';
import 'package:teeq/core/debug_console/developer_mode_controller.dart';
import 'package:teeq/core/debug_console/developer_mode_storage.dart';
import 'package:teeq/core/debug_console/network/network_log_interceptor.dart';
import 'package:teeq/core/debug_console/network_log_entry.dart';
import 'package:teeq/core/logging/app_logger.dart';
import 'package:teeq/core/network/api_error_interceptor.dart';
import 'package:teeq/core/network/auth_interceptor.dart';
import 'package:teeq/core/network/token_refresher.dart';

import '../../../../support/fake_developer_mode_storage.dart';
import '../../../../support/fake_token_storage.dart';
import '../../../../support/scripted_http_client_adapter.dart';

const _baseUrl = 'https://api.example.test';
const _refreshPath = '/api/auth/refresh';
const _oldTokens = AuthTokens(
  accessToken: 'old-access',
  refreshToken: 'old-refresh',
);

/// 실제 구성과 같은 순서(로그 → ApiError → Auth)로 묶은 테스트 환경.
class _Harness {
  _Harness({required bool developerModeEnabled}) {
    container = ProviderContainer(
      overrides: [
        initialDeveloperModeEnabledProvider.overrideWithValue(
          developerModeEnabled,
        ),
        developerModeStorageProvider.overrideWithValue(
          FakeDeveloperModeStorage(storedEnabled: developerModeEnabled),
        ),
      ],
    );
    addTearDown(container.dispose);
    final store = container.read(debugConsoleStoreProvider.notifier);

    final plainDio = Dio(BaseOptions(baseUrl: _baseUrl))
      ..httpClientAdapter = adapter;
    final logger = AppLogger();
    plainDio.interceptors.addAll([
      NetworkLogInterceptor(store: store),
      ApiErrorInterceptor(logger: logger),
    ]);
    dio = Dio(BaseOptions(baseUrl: _baseUrl))..httpClientAdapter = adapter;
    dio.interceptors.addAll([
      NetworkLogInterceptor(store: store),
      ApiErrorInterceptor(logger: logger),
      AuthInterceptor(
        logger: logger,
        dio: dio,
        tokenStorage: FakeTokenStorage(storedTokens: _oldTokens),
        tokenRefresher: DioTokenRefresher(plainDio),
        onSessionExpired: () async {},
      ),
    ]);
  }

  late final ProviderContainer container;
  late final Dio dio;
  final ScriptedHttpClientAdapter adapter = ScriptedHttpClientAdapter();

  List<NetworkLogEntry> entriesTo(String path) => container
      .read(debugConsoleStoreProvider)
      .networkEntries
      .where((entry) => Uri.parse(entry.url).path == path)
      .toList();
}

void main() {
  test('records a completed successful call', () async {
    final harness = _Harness(developerModeEnabled: true);
    harness.adapter.on('/api/ping', [
      ScriptedReply.json(200, {'status': 'ok'}),
    ]);

    await harness.dio.get<dynamic>('/api/ping');

    final entry = harness.entriesTo('/api/ping').single;
    expect(entry.method, 'GET');
    expect(entry.url, '$_baseUrl/api/ping');
    expect(entry.outcome, NetworkLogOutcome.success);
    expect(entry.statusCode, 200);
    expect(entry.responseBody!.text, contains('"status": "ok"'));
    expect(entry.duration, isNotNull);
  });

  test('records nothing while developer mode is off', () async {
    final harness = _Harness(developerModeEnabled: false);
    harness.adapter.on('/api/ping', [ScriptedReply.json(200, {})]);

    await harness.dio.get<dynamic>('/api/ping');

    expect(
      harness.container.read(debugConsoleStoreProvider).networkEntries,
      isEmpty,
    );
  });

  test('records the expired 401 and its retry as two entries', () async {
    final harness = _Harness(developerModeEnabled: true);
    harness.adapter
      ..on('/api/data', [
        ScriptedReply.json(401, {
          'errorCode': 'EXPIRED_TOKEN',
          'errorMessage': '상세',
        }),
        ScriptedReply.json(200, {'value': 1}),
      ])
      ..on(_refreshPath, [
        ScriptedReply.json(200, {
          'accessToken': 'new-access',
          'refreshToken': 'new-refresh',
        }),
      ]);

    await harness.dio.get<dynamic>('/api/data');

    final entries = harness.entriesTo('/api/data');
    expect(entries, hasLength(2));
    expect(entries.first.id, isNot(entries.last.id));
    expect(entries.first.statusCode, 401);
    expect(entries.first.outcome, NetworkLogOutcome.failure);
    expect(entries.first.responseBody!.text, contains('EXPIRED_TOKEN'));
    expect(entries.first.requestHeaders['Authorization'], 'Bearer old-access');
    expect(entries.last.statusCode, 200);
    expect(entries.last.outcome, NetworkLogOutcome.success);
    expect(entries.last.requestHeaders['Authorization'], 'Bearer new-access');
  });

  test('records a connection failure without a status code', () async {
    final harness = _Harness(developerModeEnabled: true);
    harness.adapter.on('/api/down', [
      ScriptedReply.failure(
        (options) => DioException.connectionError(
          requestOptions: options,
          reason: '연결 실패',
        ),
      ),
    ]);

    await expectLater(
      harness.dio.get<dynamic>('/api/down'),
      throwsA(isA<DioException>()),
    );

    final entry = harness.entriesTo('/api/down').single;
    expect(entry.outcome, NetworkLogOutcome.failure);
    expect(entry.statusCode, isNull);
    expect(entry.errorDescription, contains('connectionError'));
  });

  test('summarizes a FormData upload without its binary content', () async {
    final harness = _Harness(developerModeEnabled: true);
    harness.adapter.on('/api/upload', [ScriptedReply.json(200, {})]);

    await harness.dio.post<dynamic>(
      '/api/upload',
      data: FormData.fromMap({
        'image': MultipartFile.fromBytes([1, 2, 3], filename: 'photo.png'),
      }),
    );

    final body = harness.entriesTo('/api/upload').single.requestBody!;
    expect(body.text, contains('photo.png'));
    expect(body.text, isNot(contains('[1, 2, 3]')));
  });
}
