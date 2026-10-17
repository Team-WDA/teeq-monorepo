import 'package:teeq/core/config/app_config.dart';
import 'package:teeq/core/network/dio_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dioProvider uses the apiBaseUrl from AppConfig and sets timeouts', () {
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          const AppConfig(
            apiBaseUrl: 'https://api.example.test',
            appleServiceId: 'kr.co.teeq.app.service',
            appleRedirectUri:
                'https://api.example.test/api/auth/apple/callback',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final dio = container.read(dioProvider);

    expect(dio.options.baseUrl, 'https://api.example.test');
    expect(dio.options.connectTimeout, isNotNull);
    expect(dio.options.receiveTimeout, isNotNull);
  });
}
