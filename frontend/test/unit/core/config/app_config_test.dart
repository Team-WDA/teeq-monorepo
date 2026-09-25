import 'package:teeq/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig.validate', () {
    test('does not throw when every required key is set', () {
      const config = AppConfig(apiBaseUrl: 'https://api.example.test');

      expect(config.validate, returnsNormally);
    });

    test('throws a StateError naming the missing keys', () {
      const config = AppConfig(apiBaseUrl: '');

      expect(
        config.validate,
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('API_BASE_URL'),
          ),
        ),
      );
    });
  });
}
