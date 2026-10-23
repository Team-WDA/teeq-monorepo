import 'package:teeq/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig.validate', () {
    test('validate_allPresent_doesNotThrow', () {
      const config = AppConfig(apiBaseUrl: 'https://api.example.test');

      expect(config.validate, returnsNormally);
    });

    test('validate_missingApiBaseUrl_listsMissingKey', () {
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
