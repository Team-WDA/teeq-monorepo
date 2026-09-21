import 'package:ai_friend/core/config/app_config.dart';
import 'package:ai_friend/core/network/dio_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dioProvider uses the apiBaseUrl from AppConfig and sets timeouts', () {
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          const AppConfig(apiBaseUrl: 'https://api.example.test'),
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
