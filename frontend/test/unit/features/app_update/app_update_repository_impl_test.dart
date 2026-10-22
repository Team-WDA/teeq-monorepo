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
}
