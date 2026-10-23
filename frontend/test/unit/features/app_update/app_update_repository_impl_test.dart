import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/auth/token_storage.dart';
import 'package:teeq/core/config/app_config.dart';
import 'package:teeq/core/network/dio_client.dart';
import 'package:teeq/features/app_update/data/app_update_repository_impl.dart';
import 'package:teeq/features/app_update/domain/app_platform.dart';
import 'package:teeq/features/app_update/domain/app_update_repository.dart';

import '../../../support/fake_token_storage.dart';
import '../../../support/scripted_http_client_adapter.dart';

const _path = '/api/app-versions/check';

({AppUpdateRepository repository, ScriptedHttpClientAdapter adapter}) _setUp() {
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
  return (
    repository: container.read(appUpdateRepositoryProvider),
    adapter: adapter,
  );
}

void main() {
  test('checkRequirement_returnsRequirementWhenUpdateRequired', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on(_path, [
      ScriptedReply.json(200, {
        'updateRequired': true,
        'minimumVersion': '1.3.0',
        'storeUrl': 'https://store.example.test',
      }),
    ]);

    final requirement = await repository.checkRequirement(
      platform: AppPlatform.android,
      appVersion: '1.2.3',
    );

    expect(requirement?.minimumVersion, '1.3.0');
    expect(requirement?.storeUrl, 'https://store.example.test');
  });

  test('checkRequirement_returnsNullWhenUpdateNotRequired', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on(_path, [
      ScriptedReply.json(200, {
        'updateRequired': false,
        'minimumVersion': '1.0.0',
        'storeUrl': 'https://store.example.test',
      }),
    ]);

    final requirement = await repository.checkRequirement(
      platform: AppPlatform.ios,
      appVersion: '1.2.3',
    );

    expect(requirement, isNull);
  });

  test('checkRequirement_sendsQueryAndShortTimeouts', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on(_path, [
      ScriptedReply.json(200, {
        'updateRequired': false,
        'minimumVersion': '1.0.0',
        'storeUrl': 'https://store.example.test',
      }),
    ]);

    await repository.checkRequirement(
      platform: AppPlatform.android,
      appVersion: '1.2.3',
    );

    final request = adapter.requestsTo(_path).single;
    expect(request.method, 'GET');
    expect(request.queryParameters, {
      'platform': 'ANDROID',
      'appVersion': '1.2.3',
    });
    expect(request.connectTimeout, const Duration(seconds: 5));
    expect(request.receiveTimeout, const Duration(seconds: 5));
  });

  // Dio의 연결·수신 타임아웃은 단계별 제한이라 합계를 막지 못하므로 요청 전체에 마감을 건다.
  testWidgets('checkRequirement_throwsTimeoutWhenTotalTimeExceedsDeadline', (
    tester,
  ) async {
    final (:repository, :adapter) = _setUp();
    adapter.on(_path, [
      ScriptedReply.json(200, {
        'updateRequired': true,
        'minimumVersion': '1.3.0',
        'storeUrl': 'https://store.example.test',
      }, delay: const Duration(seconds: 6)),
    ]);

    final result = repository.checkRequirement(
      platform: AppPlatform.android,
      appVersion: '1.2.3',
    );
    final expectation = expectLater(result, throwsA(isA<TimeoutException>()));
    // 응답 지연(6초)까지 가짜 시간을 진행한다. 마감(5초)이 없으면 성공 응답이 돌아와 위 단언이 실패한다.
    await tester.pump(appVersionCheckTimeout);
    await tester.pump(const Duration(seconds: 2));
    await expectation;
  });
}
