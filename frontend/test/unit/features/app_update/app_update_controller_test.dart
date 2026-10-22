import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/config/app_version_provider.dart';
import 'package:teeq/features/app_update/data/app_update_repository_impl.dart';
import 'package:teeq/features/app_update/domain/app_platform.dart';
import 'package:teeq/features/app_update/domain/app_update_repository.dart';
import 'package:teeq/features/app_update/domain/app_update_requirement.dart';
import 'package:teeq/features/app_update/presentation/app_update_controller.dart';

class _FakeAppUpdateRepository implements AppUpdateRepository {
  _FakeAppUpdateRepository({this.requirement, this.error});

  final AppUpdateRequirement? requirement;
  final Object? error;
  final List<({AppPlatform platform, String appVersion})> calls = [];

  @override
  Future<AppUpdateRequirement?> checkRequirement({
    required AppPlatform platform,
    required String appVersion,
  }) async {
    calls.add((platform: platform, appVersion: appVersion));
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return requirement;
  }
}

const _requirement = AppUpdateRequirement(
  minimumVersion: '1.3.0',
  storeUrl: 'https://store.example.test',
);

ProviderContainer _container(
  _FakeAppUpdateRepository repository, {
  AppPlatform? platform = AppPlatform.android,
}) {
  final container = ProviderContainer(
    overrides: [
      appUpdateRepositoryProvider.overrideWithValue(repository),
      currentAppPlatformProvider.overrideWithValue(platform),
      appVersionProvider.overrideWith((ref) async => '1.2.3'),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('check_returnsTrueAndStoresRequirementWhenUpdateRequired', () async {
    final container = _container(
      _FakeAppUpdateRepository(requirement: _requirement),
    );

    final result = await container
        .read(appUpdateControllerProvider.notifier)
        .check();

    expect(result, isTrue);
    expect(container.read(appUpdateControllerProvider), _requirement);
  });

  test('check_returnsFalseWhenRepositoryReturnsNull', () async {
    final container = _container(_FakeAppUpdateRepository());

    final result = await container
        .read(appUpdateControllerProvider.notifier)
        .check();

    expect(result, isFalse);
    expect(container.read(appUpdateControllerProvider), isNull);
  });

  group('check_failsOpen', () {
    final failures = <String, Object>{
      'DioException': DioException(
        requestOptions: RequestOptions(path: '/api/app-versions/check'),
        type: DioExceptionType.receiveTimeout,
      ),
      'Exception': Exception('boom'),
      'TypeError': TypeError(),
      'StateError': StateError('unexpected body'),
    };
    for (final entry in failures.entries) {
      test('${entry.key}를 던져도 false를 돌려주고 상태는 null', () async {
        final container = _container(
          _FakeAppUpdateRepository(error: entry.value),
        );

        final result = await container
            .read(appUpdateControllerProvider.notifier)
            .check();

        expect(result, isFalse);
        expect(container.read(appUpdateControllerProvider), isNull);
      });
    }
  });

  test('check_skipsRepositoryOnUnsupportedPlatform', () async {
    final repository = _FakeAppUpdateRepository(requirement: _requirement);
    final container = _container(repository, platform: null);

    final result = await container
        .read(appUpdateControllerProvider.notifier)
        .check();

    expect(result, isFalse);
    expect(repository.calls, isEmpty);
  });

  test('check_passesInstalledVersionAndPlatformToRepository', () async {
    final repository = _FakeAppUpdateRepository();
    final container = _container(repository, platform: AppPlatform.ios);

    await container.read(appUpdateControllerProvider.notifier).check();

    expect(repository.calls.single.platform, AppPlatform.ios);
    expect(repository.calls.single.appVersion, '1.2.3');
  });
}
