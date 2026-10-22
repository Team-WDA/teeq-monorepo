import 'package:teeq/core/config/app_config.dart';
import 'package:teeq/core/debug_console/network/network_log_interceptor.dart';
import 'package:teeq/core/network/api_error_interceptor.dart';
import 'package:teeq/core/network/auth_interceptor.dart';
import 'package:teeq/core/network/dio_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _container() {
  final container = ProviderContainer(
    overrides: [
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
  return container;
}

void main() {
  test('dioProvider uses the apiBaseUrl from AppConfig and sets timeouts', () {
    final dio = _container().read(dioProvider);

    expect(dio.options.baseUrl, 'https://api.example.test');
    expect(dio.options.connectTimeout, isNotNull);
    expect(dio.options.receiveTimeout, isNotNull);
  });

  test('dioProvider runs ApiErrorInterceptor before AuthInterceptor', () {
    final interceptors = _container().read(dioProvider).interceptors;

    final apiErrorIndex = interceptors.indexWhere(
      (interceptor) => interceptor is ApiErrorInterceptor,
    );
    final authIndex = interceptors.indexWhere(
      (interceptor) => interceptor is AuthInterceptor,
    );
    expect(apiErrorIndex, isNonNegative);
    expect(authIndex, greaterThan(apiErrorIndex));
  });

  test('plainDioProvider shares base options and has no AuthInterceptor', () {
    final container = _container();
    final dio = container.read(dioProvider);
    final plainDio = container.read(plainDioProvider);

    expect(plainDio, isNot(same(dio)));
    expect(plainDio.options.baseUrl, dio.options.baseUrl);
    expect(plainDio.options.connectTimeout, dio.options.connectTimeout);
    expect(plainDio.options.receiveTimeout, dio.options.receiveTimeout);
    expect(
      plainDio.interceptors.whereType<ApiErrorInterceptor>(),
      hasLength(1),
    );
    expect(plainDio.interceptors.whereType<AuthInterceptor>(), isEmpty);
  });

  test('both dio instances log network calls before ApiErrorInterceptor', () {
    final container = _container();

    for (final dio in [
      container.read(dioProvider),
      container.read(plainDioProvider),
    ]) {
      final logIndex = dio.interceptors.indexWhere(
        (interceptor) => interceptor is NetworkLogInterceptor,
      );
      final apiErrorIndex = dio.interceptors.indexWhere(
        (interceptor) => interceptor is ApiErrorInterceptor,
      );
      expect(logIndex, isNonNegative);
      expect(logIndex, lessThan(apiErrorIndex));
    }
  });
}
